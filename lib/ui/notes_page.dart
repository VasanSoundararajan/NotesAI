
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/storage_service.dart';
import '../llm/mock_llm_provider.dart';
import '../llm/llm_provider.dart';
import '../utils/debounce.dart';
import 'note_editor.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _storage = StorageService();
  final LlmProvider _llm = MockLlmProvider();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 300);

  List<Note> _notes = [];
  List<Note> _filtered = [];
  bool _showStarredOnly = false;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      setState(() => _loading = true);
      final n = await _storage.getAll();
      setState(() {
        _notes = n;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notes: $e';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    var list = _notes;
    if (_showStarredOnly) list = list.where((n) => n.starred).toList();
    if (q.isNotEmpty) {
      list = list.where((n) => n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q)).toList();
    }
    setState(() => _filtered = list);
  }

  Future<void> _createNew() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditor(
      onSave: (note) async {
        await _storage.create(note);
        Navigator.of(context).pop();
        await _loadNotes();
      },
    )));
  }

  Future<void> _edit(Note note) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditor(
      note: note,
      onSave: (updated) async {
        updated.id = note.id;
        await _storage.update(updated);
        Navigator.of(context).pop();
        await _loadNotes();
      },
      onDelete: () async {
        if (note.id != null) await _storage.delete(note.id!);
        Navigator.of(context).pop();
        await _loadNotes();
      },
    )));
  }

  Future<void> _summarise(Note note) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final s = await _llm.summarize(note.body);
      Navigator.of(context).pop();
      await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Summary'), content: SelectableText(s), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to summarise: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // Ctrl/Cmd+N => new note
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) => _createNew()),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Notes + AI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.brightness_6),
                onPressed: () {
                  // Keep it simple: toggle theme by rebuilding MaterialApp through navigator pushReplacement
                  final brightness = Theme.of(context).brightness;
                  final newMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
                  // This approach is a bit hacky — for production, lift theme state higher.
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MaterialApp(
                    title: 'Notes + AI',
                    themeMode: newMode,
                    theme: ThemeData.light(),
                    darkTheme: ThemeData.dark(),
                    home: const NotesPage(),
                  )));
                },
                tooltip: 'Toggle theme',
              )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _createNew,
            tooltip: 'New note (Ctrl/Cmd+N)',
            child: const Icon(Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes... (Ctrl/Cmd+K)'),
                      onChanged: (_) => _debouncer.run(() => _applyFilter()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Starred'),
                    selected: _showStarredOnly,
                    onSelected: (v) => setState(() { _showStarredOnly = v; _applyFilter(); }),
                  )
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                      ? Center(child: Text(_error))
                      : _filtered.isEmpty
                        ? const Center(child: Text('No notes — create one!'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final n = _filtered[i];
                              return ListTile(
                                title: Text(n.title.isEmpty ? '(no title)' : n.title),
                                subtitle: Text(
                                  n.body.length > 100 ? '${n.body.substring(0, 100)}…' : n.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: IconButton(
                                  icon: Icon(n.starred ? Icons.star : Icons.star_border),
                                  onPressed: () async {
                                    n.starred = !n.starred;
                                    if (n.id != null) await _storage.update(n);
                                    await _loadNotes();
                                  },
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') await _edit(n);
                                    if (v == 'summary') await _summarise(n);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'summary', child: Text('Summarise')),
                                  ],
                                ),
                                onTap: () => _edit(n),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}