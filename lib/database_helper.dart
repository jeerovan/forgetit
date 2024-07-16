import 'dart:typed_data';

import 'package:forgetit/globals.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('forgetit.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path,
        version: 1, onCreate: _onCreate, onOpen: _onOpen);
  }

  Future _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // Add table creation queries here
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image BLOB NOT NULL,
        at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        image BLOB NOT NULL,
        at INTEGER,
        FOREIGN KEY (profile_id) REFERENCES profile(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        at INTEGER
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_tag_title ON tag(title)
    ''');
    await db.execute('''
      CREATE TABLE itemtag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        at INTEGER,
        FOREIGN KEY (item_id) REFERENCES item(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tag(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE locale (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL,
        lang TEXT NOT NULL,
        value TEXT NOT NULL,
        at INTEGER
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_locale_key ON locale(key)
    ''');
    await db.execute('''
      CREATE TABLE setting(
        id TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        at INTEGER
      )
    ''');
    // Add more tables as needed
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    int at = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    Uint8List homeImage = getBlankImage(512);
    await db
        .insert("profile", {"id": 1, "title": "Home", "image": homeImage,"at":at});
        Uint8List officeImage = getBlankImage(512);
    await db
        .insert("profile", {"id": 2, "title": "Office", "image": officeImage,"at":at});
  }

  Future<int> insert(String tableName, Map<String, dynamic> row) async {
    final db = await instance.database;
    row['at'] = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return await db.insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(
      String tableName, Map<String, dynamic> row, dynamic id) async {
    final db = await instance.database;
    row['at'] = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return await db.update(tableName, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String tableName, dynamic id) async {
    final db = await instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryOne(
      String tableName, dynamic id) async {
    final db = await instance.database;
    return await db.query(tableName,
        where: "id = ?", whereArgs: [id], limit: 1);
  }

  Future<List<Map<String, dynamic>>> queryAll(String tableName) async {
    final db = await instance.database;
    return await db.query(tableName);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
