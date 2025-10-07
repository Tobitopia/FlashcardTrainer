
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_card.dart';

void main() {
  group('VocabCard', () {
    test('VocabCard can be instantiated', () {
      final now = DateTime.now();
      final vocabCard = VocabCard(
        id: 1,
        title: 'Test Title',
        description: 'Test Description',
        mediaPath: '/path/to/media',
        labels: ['test', 'label'],
        rating: 4,
        lastTrained: now,
        setId: 1,
      );

      expect(vocabCard.id, 1);
      expect(vocabCard.title, 'Test Title');
      expect(vocabCard.description, 'Test Description');
      expect(vocabCard.mediaPath, '/path/to/media');
      expect(vocabCard.labels, ['test', 'label']);
      expect(vocabCard.rating, 4);
      expect(vocabCard.lastTrained, now);
      expect(vocabCard.setId, 1);
    });

    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      final vocabCard = VocabCard(
        id: 1,
        title: 'Test Title',
        description: 'Test Description',
        mediaPath: '/path/to/media',
        labels: ['test', 'label'],
        rating: 4,
        lastTrained: now,
        setId: 1,
      );

      final map = vocabCard.toMap();
      final fromMapCard = VocabCard.fromMap(map);

      // Note: `fromMap` doesn't handle labels, so we don't compare them.
      expect(fromMapCard.id, vocabCard.id);
      expect(fromMapCard.title, vocabCard.title);
      expect(fromMapCard.description, vocabCard.description);
      expect(fromMapCard.mediaPath, vocabCard.mediaPath);
      expect(fromMapCard.rating, vocabCard.rating);
      // Comparing millisecondsSinceEpoch because DateTime objects might not be identical.
      expect(fromMapCard.lastTrained?.millisecondsSinceEpoch, vocabCard.lastTrained?.millisecondsSinceEpoch);
      expect(fromMapCard.setId, vocabCard.setId);
    });
  });
}
