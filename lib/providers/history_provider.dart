import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/history_model.dart';

class HistoryProvider extends ChangeNotifier {
  static const _dbName = 'webbuddy_history.db';
  static const _tableName = 'history';

  Database? _db;
  List<HistoryEntry> _entries = [];

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            visitedAt INTEGER NOT NULL
          )
        ''');
      },
    );
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final rows = await _db!.query(
      _tableName,
      orderBy: 'visitedAt DESC',
      limit: 500,
    );
    _entries = rows.map(HistoryEntry.fromMap).toList();
    notifyListeners();
  }

  Future<void> add(String title, String url) async {
    final entry = HistoryEntry(
      id: const Uuid().v4(),
      title: title.isNotEmpty ? title : url,
      url: url,
      visitedAt: DateTime.now(),
    );
    await _db!.insert(_tableName, entry.toMap());
    _entries.insert(0, entry);
    if (_entries.length > 500) _entries = _entries.sublist(0, 500);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _db!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> clear() async {
    await _db!.delete(_tableName);
    _entries.clear();
    notifyListeners();
  }
}
