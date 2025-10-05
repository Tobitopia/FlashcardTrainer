import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_card.dart';

void main() {
  group('VocabCard', () {
    test('toMap() should return a valid map', () {
      // Arrange: Create a VocabCard instance
      final card = VocabCard(
        id: 1,
        title: 'Hello',
        description: 'Hola',
        mediaPath: '/path/to/media.mp4',
        rating: 4,
        labels: ['greeting', 'spanish'],
      );

      // Act: Convert the card to a map
      final cardMap = card.toMap();

      // Assert: Check if the map contains the correct values
      expect(cardMap['id'], 1);
      expect(cardMap['title'], 'Hello');
      expect(cardMap['description'], 'Hola');
      expect(cardMap['mediaPath'], '/path/to/media.mp4');
      expect(cardMap['rating'], 4);
    });

    test('fromMap() should return a valid VocabCard object', () {
      // Arrange: Create a map with card data
      final cardMap = {
        'id': 2,
        'title': 'Goodbye',
        'description': 'Adiós',
        'mediaPath': '/path/to/another/media.jpg',
        'rating': 5,
      };

      // Act: Create a VocabCard from the map
      final card = VocabCard.fromMap(cardMap);

      // Assert: Check if the card has the correct properties
      expect(card.id, 2);
      expect(card.title, 'Goodbye');
      expect(card.description, 'Adiós');
      expect(card.mediaPath, '/path/to/another/media.jpg');
      expect(card.rating, 5);
      expect(card.labels, isEmpty);
    });
  });
}
