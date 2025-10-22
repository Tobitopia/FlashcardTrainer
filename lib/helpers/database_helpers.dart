import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/vocab_set.dart';
import '../models/vocab_card.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vocab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    final db = await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgradeDB);
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
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
  }

  /// Helper method to download a file from a URL and save it locally.
  Future<String?> _downloadAndSaveMedia(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(url).split('?').first; // Get original filename
        final localPath = p.join(directory.path, fileName);
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return localPath;
      }
      return null;
    } catch (e) {
      print("Error downloading media: $e");
      return null;
    }
  }

  // --- Set Methods ---

  Future<int> insertSet(VocabSet set) async {
    final db = await instance.database;
    return await db.insert('sets', set.toMap());
  }

  Future<void> importSet(VocabSet set) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      int newSetId = await txn.insert('sets', {'name': set.name});

      for (VocabCard card in set.cards) {
        if (card.mediaPath != null && card.mediaPath!.startsWith('http')) {
          final localPath = await _downloadAndSaveMedia(card.mediaPath!);
          card.mediaPath = localPath; 
        }

        final cardMap = card.toMap();
        cardMap['setId'] = newSetId;

        int newCardId = await txn.insert('cards', cardMap);
        
        final batch = txn.batch();
        for (final label in card.labels) {
          batch.insert('labels', {'name': label, 'cardId': newCardId});
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<List<VocabSet>> getAllSets() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> setMaps = await db.query('sets', orderBy: 'name');

    if (setMaps.isEmpty) {
      return [];
    }

    List<VocabSet> sets = setMaps.map((map) => VocabSet.fromMap(map)).toList();

    for (var set in sets) {
      set.cards = await getCardsForSet(set.id!);
    }

    return sets;
  }

  Future<int> updateSet(VocabSet set) async {
    final db = await instance.database;
    return await db.update(
      'sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  Future<int> deleteSet(int id) async {
    final db = await instance.database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  // --- Card Methods ---

  Future<int> insertCard(VocabCard card, int setId) async {
    final db = await instance.database;
    final cardMap = card.toMap();
    cardMap['setId'] = setId;

    final cardId = await db.insert('cards', cardMap);

    await _insertLabels(card.labels, cardId);

    return cardId;
  }

  Future<List<VocabCard>> getCardsForSet(int setId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> cardMaps = await db.query(
      'cards',
      where: 'setId = ?',
      whereArgs: [setId],
    );

    List<VocabCard> cards = [];
    for (var cardMap in cardMaps) {
      final card = VocabCard.fromMap(cardMap);
      card.labels = await _getLabelsForCard(card.id!);
      cards.add(card);
    }
    return cards;
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCard(VocabCard card) async {
    final db = await instance.database;

    final result = await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );

    await db.delete('labels', where: 'cardId = ?', whereArgs: [card.id]);
    await _insertLabels(card.labels, card.id!);

    return result;
  }

  Future<List<String>> getAllLabels() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> labelMaps = await db.query(
      'labels',
      columns: ['name'],
      distinct: true,
      orderBy: 'name',
    );

    if (labelMaps.isEmpty) {
      return [];
    }

    return labelMaps.map((map) => map['name'] as String).toList();
  }

  Future<List<VocabCard>> getAllCards() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> cardMaps = await db.query('cards', orderBy: 'id DESC');

    if (cardMaps.isEmpty) {
      return [];
    }

    List<VocabCard> cards = [];
    for (var cardMap in cardMaps) {
      final card = VocabCard.fromMap(cardMap);
      card.labels = await _getLabelsForCard(card.id!);
      cards.add(card);
    }
    return cards;
  }

  Future<void> _insertLabels(List<String> labels, int cardId) async {
    final db = await instance.database;
    final batch = db.batch();
    for (final label in labels) {
      batch.insert('labels', {'name': label, 'cardId': cardId});
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> _getLabelsForCard(int cardId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> labelMaps = await db.query(
      'labels',
      columns: ['name'],
      where: 'cardId = ?',
      whereArgs: [cardId],
    );

    if (labelMaps.isEmpty) {
      return [];
    }

    return labelMaps.map((map) => map['name'] as String).toList();
  }
}
