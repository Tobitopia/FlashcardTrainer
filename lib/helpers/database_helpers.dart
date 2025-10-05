import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
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

  // --- Set Methods ---

  Future<int> insertSet(VocabSet set) async {
    final db = await instance.database;
    return await db.insert('sets', set.toMap());
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
      final cardLabels = await _getLabelsForCard(card.id!);
      cards.add(VocabCard(
        id: card.id,
        title: card.title,
        description: card.description,
        mediaPath: card.mediaPath,
        rating: card.rating,
        labels: cardLabels,
      ));
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
      final cardLabels = await _getLabelsForCard(card.id!);
      cards.add(VocabCard(
        id: card.id,
        title: card.title,
        description: card.description,
        mediaPath: card.mediaPath,
        rating: card.rating,
        labels: cardLabels,
      ));
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
