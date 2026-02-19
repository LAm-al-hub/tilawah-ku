import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/user_target.dart';
import '../models/user_profile.dart';
import '../models/reading_history.dart';

class LocalStorageService {
  static const String _lastReadSurahKey = 'last_read_surah';
  static const String _lastReadAyahKey = 'last_read_ayah';
  static const String _userTargetKey = 'user_target';
  static const String _userProfileKey = 'user_profile';
  static const String _dailyProgressKey = 'daily_progress';
  static const String _dailyProgressDateKey = 'daily_progress_date';

  // --- SharedPreferences (Settings & Last Read) ---

  Future<void> saveLastRead(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadSurahKey, surah);
    await prefs.setInt(_lastReadAyahKey, ayah);
  }

  Future<Map<String, int>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_lastReadSurahKey);
    final ayah = prefs.getInt(_lastReadAyahKey);
    if (surah != null && ayah != null) {
      return {'surah': surah, 'ayah': ayah};
    }
    return null;
  }

  Future<int> getDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateStr = prefs.getString(_dailyProgressDateKey);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (dateStr == todayStr) {
      return prefs.getInt(_dailyProgressKey) ?? 0;
    } else {
      // Reset if date is different
      await prefs.setString(_dailyProgressDateKey, todayStr);
      await prefs.setInt(_dailyProgressKey, 0);
      return 0;
    }
  }

  Future<void> incrementDailyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getDailyProgress();
    await prefs.setInt(_dailyProgressKey, current + 1);
  }

  Future<void> saveUserTarget(UserTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTargetKey, jsonEncode(target.toJson()));
  }

  Future<UserTarget?> getUserTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final String? targetJson = prefs.getString(_userTargetKey);
    if (targetJson != null) {
      return UserTarget.fromJson(jsonDecode(targetJson));
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileJson = prefs.getString(_userProfileKey);
    if (profileJson != null) {
      return UserProfile.fromJson(jsonDecode(profileJson));
    }
    return null;
  }

  // --- SQLite (Tasks) ---

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Check if we are on Web
    if (identical(0, 0.0)) { // Simple check for web (Javascript treats int and double as same type)
        // Or use kIsWeb from foundation if imported
        // For web, we might need a different approach or just return a dummy DB if sqflite_common_ffi_web is not used
        // But since we are using standard sqflite, it doesn't support web out of the box without extra setup.
        // For this debugging purpose, we can use a basic implementation or just throw/warn.
        // However, a better approach for a quick fix for "debugging in web" is to not break.
         // NOTE: Actual Web support for sqflite requires 'sqflite_common_ffi_web' or similar.
         // Here we will try to proceed with standard getDatabasesPath which might fail on web.
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tilawah_app.db');

    return await openDatabase(
      path,
      version: 2, // Increment version for new table
      onCreate: (db, version) async {
        await _createTasksTable(db);
        await _createHistoryTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createHistoryTable(db);
        }
      },
    );
  }

  Future<void> _createTasksTable(Database db) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        isCompleted INTEGER,
        date TEXT
      )
    ''');
  }

  Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE reading_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER,
        surah_name TEXT,
        ayah_number INTEGER,
        read_at TEXT
      )
    ''');
  }

  // --- Reading History ---

  Future<int> addReadingHistory(ReadingHistory history) async {
    final db = await database;
    return await db.insert('reading_history', history.toMap());
  }

  Future<List<ReadingHistory>> getReadingHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reading_history', orderBy: "read_at DESC");
    return List.generate(maps.length, (i) {
      return ReadingHistory.fromMap(maps[i]);
    });
  }

  Future<int> deleteReadingHistory(int id) async {
    final db = await database;
    return await db.delete('reading_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearReadingHistory() async {
    final db = await database;
    return await db.delete('reading_history');
  }

  Future<int> addTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', orderBy: "date DESC");
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
