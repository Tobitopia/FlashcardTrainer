
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/models/vocab_card.dart';

void main() {
  group('VocabSet', () {
    test('VocabSet can be instantiated', () {
      final vocabSet = VocabSet(name: 'Test Set');
      expect(vocabSet.name, 'Test Set');
      expect(vocabSet.cards, isEmpty);
    });

    test('addCard adds a card to the set', () {
      final vocabSet = VocabSet(name: 'Test Set');
      final vocabCard = VocabCard(
        title: 'Title',
        description: 'Description',
        rating: 3,
        labels: ['label1'],
      );
      vocabSet.addCard(vocabCard);
      expect(vocabSet.cards, hasLength(1));
      expect(vocabSet.cards.first, vocabCard);
    });
  });
}
