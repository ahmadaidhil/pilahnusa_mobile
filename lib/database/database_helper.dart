import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/history_item.dart';
import '../models/chat_message.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pilahnusa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Platform check for Windows / Linux desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await _getDbDirectory();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<String> _getDbDirectory() async {
    if (Platform.isWindows || Platform.isLinux) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final pilahDir = Directory(join(appDocDir.path, 'PilahNusa'));
      if (!await pilahDir.exists()) {
        await pilahDir.create(recursive: true);
      }
      return pilahDir.path;
    }
    return await getDatabasesPath();
  }

  Future<void> _createDB(Database db, int version) async {
    // Scan History Table
    await db.execute('''
      CREATE TABLE scan_history (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        image_path TEXT,
        image_base64 TEXT,
        user_feedback TEXT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        confidence REAL NOT NULL,
        description TEXT NOT NULL,
        disposal_guide TEXT NOT NULL,
        environmental_impact TEXT,
        decomposition_time TEXT NOT NULL,
        economic_value TEXT,
        recycling_tips TEXT NOT NULL,
        recycling_potential TEXT NOT NULL,
        youtube_tutorials TEXT NOT NULL
      )
    ''');

    // Chat History Table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // App Settings Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- History CRUD Operations ---

  Future<int> insertHistory(HistoryItem item) async {
    final db = await database;
    return await db.insert(
      'scan_history',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HistoryItem>> getAllHistory() async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => HistoryItem.fromMap(map)).toList();
  }

  Future<List<HistoryItem>> getHistoryByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'LOWER(category) = ?',
      whereArgs: [category.toLowerCase()],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => HistoryItem.fromMap(map)).toList();
  }

  Future<HistoryItem?> getHistoryById(String id) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return HistoryItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateFeedback(String id, String feedback) async {
    final db = await database;
    return await db.update(
      'scan_history',
      {'user_feedback': feedback},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHistory(String id) async {
    final db = await database;
    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearHistory() async {
    final db = await database;
    return await db.delete('scan_history');
  }

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final totalResult = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_history'),
    );
    final organikResult = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM scan_history WHERE LOWER(category) = 'organik'"),
    );
    final anorganikResult = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM scan_history WHERE LOWER(category) = 'anorganik'"),
    );
    final b3Result = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM scan_history WHERE LOWER(category) = 'b3'"),
    );

    return {
      'total': totalResult ?? 0,
      'organik': organikResult ?? 0,
      'anorganik': anorganikResult ?? 0,
      'b3': b3Result ?? 0,
    };
  }

  // --- Chat Messages CRUD Operations ---

  Future<int> insertChatMessage(ChatMessage message) async {
    final db = await database;
    return await db.insert(
      'chat_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessage>> getAllChatMessages() async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<int> clearChatMessages() async {
    final db = await database;
    return await db.delete('chat_messages');
  }

  // --- App Settings (Key-Value) ---

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    final maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

