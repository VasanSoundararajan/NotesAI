import 'package:flutter_test/flutter_test.dart';
import 'package:internship_task_vasansoundararajan/services/storage_service.dart';
import 'package:internship_task_vasansoundararajan/models/note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Storage create-read-delete note', () async {
    final s = StorageService();
    final note = Note(title: 'T1', body: 'B1');
    final created = await s.create(note);
    expect(created.id, isNotNull);

    final all = await s.getAll();
    expect(all.any((n) => n.id == created.id), true);

    final del = await s.delete(created.id!);
    expect(del, 1);
  });
}