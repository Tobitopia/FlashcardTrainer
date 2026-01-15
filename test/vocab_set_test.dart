
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/visibility.dart';

void main() {
  group('VocabSet', () {
    test('VocabSet can be instantiated with default values', () {
      final vocabSet = VocabSet(name: 'Test Set');
      expect(vocabSet.name, 'Test Set');
      expect(vocabSet.cards, isEmpty);
      expect(vocabSet.isSynced, isTrue);
      expect(vocabSet.visibility, Visibility.private);
      expect(vocabSet.cloudId, isNull);
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

    test('toMap returns correct map representation', () {
      final vocabSet = VocabSet(
        id: 1,
        name: 'Test Set',
        cloudId: 'cloud123',
        isSynced: false,
        visibility: Visibility.publicView,
      );

      final map = vocabSet.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test Set');
      expect(map['cloudId'], 'cloud123');
      expect(map['isSynced'], 0);
      expect(map['visibility'], Visibility.publicView.index);
    });

    test('fromMap creates correct VocabSet object', () {
      final map = {
        'id': 2,
        'name': 'Map Set',
        'cloudId': 'cloud456',
        'isSynced': 1,
        'visibility': Visibility.publicCooperate.index,
      };

      final vocabSet = VocabSet.fromMap(map);

      expect(vocabSet.id, 2);
      expect(vocabSet.name, 'Map Set');
      expect(vocabSet.cloudId, 'cloud456');
      expect(vocabSet.isSynced, isTrue);
      expect(vocabSet.visibility, Visibility.publicCooperate);
    });
  });
}
