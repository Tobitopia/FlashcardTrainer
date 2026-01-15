import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:projects/main.dart' as app;

extension on WidgetTester {
  Future<void> pumpUntilFound(Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
    bool found = false;
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime) && !found) {
      await pumpAndSettle();
      found = any(finder);
    }
    if (!found) {
      throw TimeoutException('Timed out waiting for $finder');
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Using setUpAll to ensure the app is only started once.
  setUpAll(() {
    app.main();
  });

  group('end-to-end test', () {
    testWidgets('full app user journey', (WidgetTester tester) async {
      // -- 1. Ensure Logged Out State --
      // This is a safety check in case the app was already open.
      await tester.pump(const Duration(seconds: 2));
      if (tester.any(find.byIcon(Icons.person_outline))) {
        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
      }

      // -- 2. Register a NEW, UNIQUE User --
      // This avoids all stateful login issues from previous test runs.
      final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const password = 'password123';

      await tester.pumpUntilFound(find.byType(TextField));
      await tester.enterText(find.byType(TextField).at(0), uniqueEmail);
      await tester.enterText(find.byType(TextField).at(1), password);
      await tester.pumpAndSettle();

      // Tap Register and wait for navigation to complete.
      await tester.tap(find.widgetWithText(TextButton, 'Register'));
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Allow time for Firebase to respond
      await tester.pumpUntilFound(find.byIcon(Icons.add)); // We must be on the main screen now.

      // -- 3. Add a new set --
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Test Set'), findsOneWidget);

      // -- 4. Add a card to the set --
      await tester.tap(find.text('Test Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add)); // FAB to add card
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Test Card');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Card Description');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Test Card'));
      expect(find.text('Test Card'), findsOneWidget);

      // -- 5. Go back to sets screen --
      await tester.pageBack();
      await tester.pumpAndSettle();

      // -- NEW: Test the training session flow --
      await tester.tap(find.text('Test Set'));
      await tester.pumpAndSettle();

      // Add a second card to allow for navigation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Test Card 2');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Second Card Description');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Test Card 2'));

      // Start the training session
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Wait for the first card to appear and flip it
      await tester.pumpUntilFound(find.text('Test Card'));
      await tester.tap(find.text('Test Card')); // Tap to flip the card
      await tester.pumpAndSettle();

      // Rate the card by tapping a rating star
      await tester.tap(find.byIcon(Icons.star).first);
      await tester.pumpAndSettle();

      // IMPORTANT: Tap the "Next Card" Floating Action Button
      // This is the new step that was previously missing.
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Verify that the second card is now visible
      await tester.pumpUntilFound(find.text('Test Card 2'));
      expect(find.text('Test Card 2'), findsOneWidget);

      // Go back to exit the training session
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Go back to the sets screen
      await tester.pageBack();
      await tester.pumpAndSettle();


      // -- 6. Edit the set name --
      await tester.longPress(find.text('Test Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Updated Set Name');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Updated Set Name'), findsOneWidget);

      // -- 7. Delete the set --
      await tester.longPress(find.text('Updated Set Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Updated Set Name'), findsNothing);

      // -- 8. Log out from profile screen --
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Forgot Password?'));
      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });
}
