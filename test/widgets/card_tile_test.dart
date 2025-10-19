
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/widgets/card_tile.dart';

void main() {
  group('CardTile', () {
    testWidgets('displays card title, description, labels, and rating', (WidgetTester tester) async {
      final vocabCard = VocabCard(
        title: 'Test Title',
        description: 'Test Description',
        labels: ['label1', 'label2'],
        rating: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTile(card: vocabCard),
          ),
        ),
      );

      // Wait for any async operations to complete (like thumbnail generation, though it won't happen here).
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('label1'), findsOneWidget);
      expect(find.text('label2'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });
  });
}
