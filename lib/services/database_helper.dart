import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/event.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static final List<LocalEvent> _webMemoryStorage = [];
  static int _webIdCounter = 1;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'premium_events_v2.db');
      return await openDatabase(
        path,
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL,
        description TEXT NOT NULL,
        date        TEXT NOT NULL,
        time        TEXT NOT NULL,
        location    TEXT NOT NULL,
        category    TEXT NOT NULL,
        isFavorite  INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE events ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  // ── INSERT ────────────────────────────────────────────────────────────────
  Future<int> insert(LocalEvent event) async {
    if (kIsWeb) {
      final newEvent = event.copyWith(id: _webIdCounter++);
      _webMemoryStorage.add(newEvent);
      return newEvent.id!;
    }
    try {
      final db = await database;
      if (db == null) return -1;
      final map = event.toMap()..remove('id');
      return await db.insert('events', map);
    } catch (e) {
      return -1;
    }
  }

  // ── READ ALL ──────────────────────────────────────────────────────────────
  Future<List<LocalEvent>> readAllEvents() async {
    if (kIsWeb) return List.from(_webMemoryStorage.reversed);
    try {
      final db = await database;
      if (db == null) return [];
      final maps = await db.query('events', orderBy: 'id DESC');
      return maps.map((m) => LocalEvent.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<int> update(LocalEvent event) async {
    if (kIsWeb) {
      final index = _webMemoryStorage.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _webMemoryStorage[index] = event;
        return 1;
      }
      return -1;
    }
    try {
      final db = await database;
      if (db == null) return -1;
      return await db.update(
        'events',
        event.toMap(),
        where: 'id = ?',
        whereArgs: [event.id],
      );
    } catch (e) {
      return -1;
    }
  }

  // ── TOGGLE FAVORITE ───────────────────────────────────────────────────────
  Future<int> toggleFavorite(LocalEvent event) async {
    final updated = event.copyWith(isFavorite: !event.isFavorite);
    return update(updated);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<int> delete(int id) async {
    if (kIsWeb) {
      _webMemoryStorage.removeWhere((e) => e.id == id);
      return 1;
    }
    try {
      final db = await database;
      if (db == null) return -1;
      return await db.delete('events', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      return -1;
    }
  }
}
