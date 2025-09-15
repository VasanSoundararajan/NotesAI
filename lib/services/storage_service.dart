import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'dart:io';
import '../models/note.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'notes_ai.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, ver) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            starred INTEGER,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<Note> create(Note note) async {
    final db = await _database;
    final id = await db.insert('notes', note.toMap());
    note.id = id;
    return note;
  }

  Future<List<Note>> getAll() async {
    final db = await _database;
    final rows = await db.query('notes', orderBy: 'updatedAt DESC');
    return rows.map((r) => Note.fromMap(r)).toList();
  }

  Future<Note?> getById(int id) async {
    final db = await _database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<int> update(Note note) async {
    final db = await _database;
    note.updatedAt = DateTime.now();
    return db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> delete(int id) async {
    final db = await _database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) await db.close();
    _db = null;
  }
}