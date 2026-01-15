
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/widgets/set_tile.dart';
import 'package:projects/models/visibility.dart' as model;

void main() {
  group('SetCard', () {
    testWidgets('displays set name and card count', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cards: []);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}, onUpload: () {}),
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
              onUpload: () {},
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
              onUpload: () {},
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(SetCard));
      expect(longPressed, isTrue);
    });

    testWidgets('shows upload button for non-synced sets', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cloudId: null);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}, onUpload: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
    });

    testWidgets('shows sync button for unsynced sets', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cloudId: 'a', isSynced: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}, onUpload: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('shows share button for public sets', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cloudId: 'a', isSynced: true, visibility: model.Visibility.publicView);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}, onUpload: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('shows lock button for private sets', (WidgetTester tester) async {
      final vocabSet = VocabSet(name: 'Test Set', cloudId: 'a', isSynced: true, visibility: model.Visibility.private);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetCard(set: vocabSet, onTap: () {}, onLongPress: () {}, onUpload: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
