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

  setUpAll(() {
    app.main();
  });

  group('end-to-end test', () {
    testWidgets('full app user journey', (WidgetTester tester) async {
      // -- 1. Ensure Logged Out State --
      await tester.pumpAndSettle(const Duration(seconds: 3));
      if (tester.any(find.byIcon(Icons.person_rounded))) {
        await tester.tap(find.byIcon(Icons.person_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
      }

      // -- 2. Register a NEW, UNIQUE User --
      final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';
      const password = 'password123';

      await tester.pumpUntilFound(find.text('Welcome Back'));

      // Switch to Register Mode
      await tester.tap(find.textContaining("Don't have an account? Register"));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);

      // Enter credentials
      await tester.enterText(find.widgetWithText(TextField, 'Email'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
      await tester.pumpAndSettle();

      // Tap Register
      await tester.tap(find.widgetWithText(ElevatedButton, 'REGISTER'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.pumpUntilFound(find.byIcon(Icons.add)); 

      // -- 3. Add a new set --
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Set Name'), 'Test Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(find.text('Test Set'), findsOneWidget);

      // -- 4. Add a card to the set --
      await tester.tap(find.text('Test Set'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Test Card');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Card Description');
      await tester.tap(find.text('Save'));
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
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Test Card 2'));

      // Start the training session
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Wait for the first card ("Test Card") to appear
      await tester.pumpUntilFound(find.text('Test Card'));
      // Note: Training screen shows description immediately, no flip animation needed for text.
      
      // Rate the card by tapping a rating star (border because it's unrated)
      // We look for either star or star_border to be safe
      final starFinder = find.byIcon(Icons.star_border);
      if (tester.any(starFinder)) {
         await tester.tap(starFinder.first);
      } else {
         await tester.tap(find.byIcon(Icons.star).first);
      }
      await tester.pumpAndSettle();

      // Tap Next Card
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
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Updated Set Name'), findsNothing);

      // -- 8. Log out from profile screen --
      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.pumpUntilFound(find.text('Welcome Back'));
    });
  });
}
