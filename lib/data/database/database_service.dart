import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'yeogibwayong.db'),
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pets (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        image_path TEXT NOT NULL,
        is_active INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE monitored_apps (
        id INTEGER PRIMARY KEY,
        package_name TEXT UNIQUE NOT NULL,
        app_name TEXT,
        daily_limit_seconds INTEGER NOT NULL,
        is_enabled INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE usage_log_daily (
        id INTEGER PRIMARY KEY,
        package_name TEXT,
        date_string TEXT,
        duration_seconds INTEGER,
        UNIQUE(package_name, date_string)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_usage_date ON usage_log_daily(date_string)',
    );

    await db.execute('''
      CREATE TABLE popup_history (
        id INTEGER PRIMARY KEY,
        trigger_type TEXT,
        package_name TEXT,
        pet_id INTEGER,
        shown_at TEXT
      )
    ''');

    await _createActiveTimer(db);

    await db.execute('''
      CREATE TABLE timer_sessions (
        id INTEGER PRIMARY KEY,
        duration_seconds INTEGER,
        started_at TEXT,
        completed_at TEXT,
        was_interrupted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createActiveTimer(Database db) => db.execute(
    'CREATE TABLE active_timer (id INTEGER PRIMARY KEY CHECK (id = 1), payload TEXT NOT NULL)',
  );

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createActiveTimer(db);
  }
}
