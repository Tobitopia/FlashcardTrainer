import '../models/vocab_card.dart';

abstract class ICardRepository {
  Future<int> insertCard(VocabCard card, int setId);

  Future<List<VocabCard>> getCardsForSet(int setId);

  Future<int> deleteCard(int id);

  Future<int> updateCard(VocabCard card);

  Future<List<VocabCard>> getAllCards();
}
