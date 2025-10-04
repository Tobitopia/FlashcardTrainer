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
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        rating INTEGER NOT NULL,
        setId INTEGER NOT NULL,
        FOREIGN KEY (setId) REFERENCES sets (id) ON DELETE CASCADE
      )
    ''');

    // --- NEW TABLE for Labels ---
    // This creates a link between cards and their labels.
    await db.execute('''
      CREATE TABLE labels(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cardId INTEGER NOT NULL,
        FOREIGN KEY (cardId) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- VocabSet Methods (no changes here) ---

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

  Future<int> deleteSet(int id) async {
    final db = await instance.database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  // --- VocabCard & Label Methods ---

  Future<int> insertCard(VocabCard card, int setId) async {
    final db = await instance.database;
    final cardMap = card.toMap();
    cardMap['setId'] = setId;

    // Insert the card and get its new ID
    final cardId = await db.insert('cards', cardMap);

    // --- NEW: Now, save the labels for this card ---
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
      // Create the card object
      final card = VocabCard.fromMap(cardMap);
      // --- NEW: Fetch the labels for this specific card ---
      final cardLabels = await _getLabelsForCard(card.id!);
      // Create a new card instance that includes the fetched labels
      cards.add(VocabCard(
        id: card.id,
        front: card.front,
        back: card.back,
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


  /// Inserts a list of labels for a given cardId.
  Future<void> _insertLabels(List<String> labels, int cardId) async {
    final db = await instance.database;
    // Use a "batch" to perform multiple inserts at once, which is more efficient.
    final batch = db.batch();
    for (final label in labels) {
      batch.insert('labels', {'name': label, 'cardId': cardId});
    }
    await batch.commit(noResult: true); // Commit the batch
  }

  /// Retrieves all labels for a given cardId.
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

    // Extract the 'name' from each map and return it as a list of strings.
    return labelMaps.map((map) => map['name'] as String).toList();
  }
}
