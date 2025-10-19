
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/widgets/set_tile.dart';

void main() {
  group('SetCard', () {
    testWidgets('displays set name and card count', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cards: []);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}),
          ),
        ),
      );

      expect(find.text('Test Set'), findsOneWidget);
      expect(find.text('0 cards'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      final vocabSet = VocabSet(name: 'Test Set');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(
              set: vocabSet,
              onTap: () => tapped = true,
              onLongPress: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SetCard));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (WidgetTester tester) async {
      bool longPressed = false;
      final vocabSet = VocabSet(name: 'Test Set');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(
              set: vocabSet,
              onTap: () {},
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(SetCard));
      expect(longPressed, isTrue);
    });
  });
}
