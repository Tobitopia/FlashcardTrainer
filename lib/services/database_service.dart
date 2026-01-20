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
    // Increment database version for remoteUrl support
    final db = await openDatabase(path, version: 7, onCreate: _createDB, onUpgrade: _onUpgradeDB);
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cloudId TEXT,
        isSynced INTEGER NOT NULL DEFAULT 1,
        visibility INTEGER NOT NULL DEFAULT 0,
        role TEXT,
        isProgression INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        mediaPath TEXT,
        remoteUrl TEXT,
        rating INTEGER NOT NULL,
        lastTrained INTEGER,
        setId INTEGER NOT NULL,
        createdAt INTEGER,
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
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE sets ADD COLUMN cloudId TEXT");
      await db.execute("ALTER TABLE sets ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 1");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE sets ADD COLUMN visibility INTEGER NOT NULL DEFAULT 0");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE sets ADD COLUMN role TEXT");
    }
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE sets ADD COLUMN isProgression INTEGER NOT NULL DEFAULT 0");
      await db.execute("ALTER TABLE cards ADD COLUMN createdAt INTEGER");
    }
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE cards ADD COLUMN remoteUrl TEXT");
    }
  }
}
