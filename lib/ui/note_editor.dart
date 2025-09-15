import 'package:flutter/material.dart';
import '../models/note.dart';

class NoteEditor extends StatefulWidget {
  final Note? note;
  final ValueChanged<Note> onSave;
  final VoidCallback? onDelete;

  const NoteEditor({super.key, this.note, required this.onSave, this.onDelete});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _starred = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _starred = widget.note?.starred ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    final n = Note(
      id: widget.note?.id,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      starred: _starred,
      createdAt: widget.note?.createdAt,
    );
    widget.onSave(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New note' : 'Edit note'),
        actions: [
          IconButton(
            icon: Icon(_starred ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => _starred = !_starred),
            tooltip: 'Star',
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                widget.onDelete?.call();
              },
              tooltip: 'Delete',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(controller: _bodyController, maxLines: null, expands: true, decoration: const InputDecoration(labelText: 'Body')),
            ),
          ],
        ),
      ),
    );
  }
}