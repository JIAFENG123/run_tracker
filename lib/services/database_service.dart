import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/run_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('run_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        distance_meters REAL NOT NULL,
        calories INTEGER NOT NULL,
        avg_pace_seconds INTEGER NOT NULL,
        points_json TEXT,
        splits_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertRun(RunRecord run) async {
    final db = await database;
    return await db.insert('runs', run.toMap());
  }

  Future<List<RunRecord>> getAllRuns() async {
    final db = await database;
    final result = await db.query('runs', orderBy: 'start_time DESC');
    return result.map((json) => RunRecord.fromMap(json)).toList();
  }

  Future<RunRecord?> getRunById(int id) async {
    final db = await database;
    final maps = await db.query(
      'runs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RunRecord.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> deleteRun(int id) async {
    final db = await database;
    return await db.delete(
      'runs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>> getTotalStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_runs,
        SUM(distance_meters) as total_distance,
        SUM(duration_seconds) as total_duration,
        SUM(calories) as total_calories,
        MAX(distance_meters) as max_distance
      FROM runs
    ''');

    if (result.isNotEmpty && result.first['total_runs'] != null) {
      final row = result.first;
      return {
        'total_runs': (row['total_runs'] as num?)?.toInt() ?? 0,
        'total_distance_meters': (row['total_distance'] as num?)?.toDouble() ?? 0.0,
        'total_duration_seconds': (row['total_duration'] as num?)?.toInt() ?? 0,
        'total_calories': (row['total_calories'] as num?)?.toInt() ?? 0,
        'max_distance_meters': (row['max_distance'] as num?)?.toDouble() ?? 0.0,
      };
    }

    return {
      'total_runs': 0,
      'total_distance_meters': 0.0,
      'total_duration_seconds': 0,
      'total_calories': 0,
      'max_distance_meters': 0.0,
    };
  }

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
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<bool> hasSeenWelcome() async {
    final val = await getSetting('has_seen_welcome');
    return val == 'true';
  }

  Future<void> markWelcomeSeen() async {
    await setSetting('has_seen_welcome', 'true');
  }

  Future<double> getUserWeight() async {
    final val = await getSetting('user_weight');
    if (val != null) {
      return double.tryParse(val) ?? 65.0;
    }
    return 65.0;
  }

  Future<void> setUserWeight(double weight) async {
    await setSetting('user_weight', weight.toString());
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
