import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    // Increment database version for schema changes
    final db = await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgradeDB);
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cloudId TEXT,
        isSynced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        mediaPath TEXT,
        rating INTEGER NOT NULL,
        lastTrained INTEGER,
        setId INTEGER NOT NULL,
        FOREIGN KEY (setId) REFERENCES sets (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE labels(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cardId INTEGER NOT NULL,
        FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
        await db.execute("ALTER TABLE cards ADD COLUMN lastTrained INTEGER");
    }
    // Add cloudId and isSynced columns for database version 3
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE sets ADD COLUMN cloudId TEXT");
      await db.execute("ALTER TABLE sets ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 1");
    }
  }
}
