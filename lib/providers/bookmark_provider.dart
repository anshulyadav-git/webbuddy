import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/bookmark_model.dart';

class BookmarkProvider extends ChangeNotifier {
  static const _dbName = 'webbuddy.db';
  static const _tableName = 'bookmarks';

  Database? _db;
  List<Bookmark> _bookmarks = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

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
            faviconUrl TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final rows = await _db!.query(_tableName, orderBy: 'createdAt DESC');
    _bookmarks = rows.map(Bookmark.fromMap).toList();
    notifyListeners();
  }

  bool isBookmarked(String url) => _bookmarks.any((b) => b.url == url);

  Future<void> add(String title, String url, {String? faviconUrl}) async {
    if (isBookmarked(url)) return;
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      title: title,
      url: url,
      faviconUrl: faviconUrl,
      createdAt: DateTime.now(),
    );
    await _db!.insert(_tableName, bookmark.toMap());
    _bookmarks.insert(0, bookmark);
    notifyListeners();
  }

  Future<void> remove(String url) async {
    await _db!.delete(_tableName, where: 'url = ?', whereArgs: [url]);
    _bookmarks.removeWhere((b) => b.url == url);
    notifyListeners();
  }

  Future<void> clear() async {
    await _db!.delete(_tableName);
    _bookmarks.clear();
    notifyListeners();
  }
}
