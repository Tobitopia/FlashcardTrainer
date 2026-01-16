
import '../models/vocab_card.dart';
import '../services/database_service.dart';
import 'card_repository.dart';

class CardRepositoryImpl implements ICardRepository {
  final DatabaseService _databaseService;

  CardRepositoryImpl(this._databaseService);

  @override
  Future<int> insertCard(VocabCard card, int setId) async {
    final db = await _databaseService.database;
    final cardMap = card.toMap();
    cardMap['setId'] = setId;

    final cardId = await db.insert('cards', cardMap);
    await _insertLabels(card.labels, cardId);
    await _markSetAsUnsynced(setId); // Mark set as unsynced when a card is added
    return cardId;
  }

  @override
  Future<List<VocabCard>> getCardsForSet(int setId) async {
    final db = await _databaseService.database;
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

  @override
  Future<int> deleteCard(int id) async {
    final db = await _databaseService.database;
    // First, get the setId before deleting the card to mark the set as unsynced
    final List<Map<String, dynamic>> cards = await db.query(
      'cards',
      columns: ['setId'],
      where: 'id = ?',
      whereArgs: [id],
    );
    int? setId;
    if (cards.isNotEmpty) {
      setId = cards.first['setId'] as int;
    }

    final result = await db.delete('cards', where: 'id = ?', whereArgs: [id]);
    if (setId != null) {
      await _markSetAsUnsynced(setId); // Mark set as unsynced when a card is deleted
    }
    return result;
  }

  @override
  Future<int> updateCard(VocabCard card) async {
    final db = await _databaseService.database;

    final result = await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );

    await db.delete('labels', where: 'cardId = ?', whereArgs: [card.id]);
    await _insertLabels(card.labels, card.id!);

    // Get setId for the updated card to mark the parent set as unsynced
    final List<Map<String, dynamic>> cards = await db.query(
      'cards',
      columns: ['setId'],
      where: 'id = ?',
      whereArgs: [card.id],
    );
    int? setId;
    if (cards.isNotEmpty) {
      setId = cards.first['setId'] as int;
    }
    if (setId != null) {
      await _markSetAsUnsynced(setId); // Mark set as unsynced when a card is updated
    }

    return result;
  }

  @override
  Future<List<VocabCard>> getAllCards() async {
    final db = await _databaseService.database;
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
    final db = await _databaseService.database;
    final batch = db.batch();
    for (final label in labels) {
      batch.insert('labels', {'name': label, 'cardId': cardId});
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> _getLabelsForCard(int cardId) async {
    final db = await _databaseService.database;
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

  Future<int> _markSetAsUnsynced(int setId) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      {'isSynced': 0},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }
}
