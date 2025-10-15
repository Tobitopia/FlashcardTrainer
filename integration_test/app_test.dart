
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projects/main.dart' as app;
import 'package:video_player/video_player.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    // --- Previous tests go here ---
    testWidgets('adds a new vocabulary set', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'New Test Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('New Test Set'), findsOneWidget);
    });

    testWidgets('adds a card to a set', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set for Card Test');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set for Card Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Test Card Title');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Test Card Description');
      await tester.tap(find.text('Add Label'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'New Label'), 'test label');
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.text('Test Card Title'), findsOneWidget);
      expect(find.text('test label'), findsNWidgets(2));
    });

    testWidgets('edits a set name', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Original Name');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Original Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Updated Name');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Original Name'), findsNothing);
      expect(find.text('Updated Name'), findsOneWidget);
    });

    testWidgets('edits an existing card', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set for Editing Card');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set for Editing Card'));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Original Title');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Original Desc');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Original Title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Updated Title');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Updated Desc');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Original Title'), findsNothing);
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Updated Desc'), findsOneWidget);
    });

    testWidgets('filters cards by label', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Filter Test Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filter Test Set'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Card A');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Desc A');
      await tester.tap(find.text('Add Label'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'New Label'), 'label-a');
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Card B');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Desc B');
      await tester.tap(find.text('Add Label'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'New Label'), 'label-b');
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'label-a'));
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'label-a'));
      await tester.pumpAndSettle();

      expect(find.text('Card A'), findsOneWidget);
      expect(find.text('Card B'), findsOneWidget);
    });

    testWidgets('training updates ratings and stats screen reflects them', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      double getRatingCount(int rating) {
        if (tester.any(find.byType(BarChart))) {
          final barChart = tester.widget<BarChart>(find.byType(BarChart));
          final group = barChart.data.barGroups.firstWhere((g) => g.x == rating, orElse: () => BarChartGroupData(x: rating, barRods: [BarChartRodData(toY: 0)]));
          return group.barRods.first.toY;
        }
        return 0;
      }

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final initialCount3 = getRatingCount(3);
      final initialCount5 = getRatingCount(5);

      await tester.tap(find.byIcon(Icons.folder_copy_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Stats Training Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stats Training Set'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Card 1');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Desc 1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Card 2');
      await tester.enterText(find.widgetWithText(TextField, 'Description'), 'Desc 2');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'train'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_border).at(2));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_border).at(4));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.insights_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final finalCount3 = getRatingCount(3);
      final finalCount5 = getRatingCount(5);

      expect(finalCount3, initialCount3 + 1);
      expect(finalCount5, initialCount5 + 1);
    });

    testWidgets('records and plays back video', (WidgetTester tester) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            return null;
          }
          return null;
        },
      );

      final ByteData data = await rootBundle.load('assets/videos/sample.mp4');
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/sample.mp4');
      await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);

      binding.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel('plugins.flutter.io/image_picker'), (MethodCall methodCall) async {
        if (methodCall.method == 'pickVideo') {
          return tempFile.path;
        }
        return null;
      });

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Video Test Set');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Video Test Set'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Video Card');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // FIX: The thumbnail is generated asynchronously. We need to be patient.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.text('Video Card'));
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'train'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      expect(find.byType(VideoPlayer), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('deletes a card after confirmation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set for Deletion');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set for Deletion'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Card to Delete');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Card to Delete'), findsOneWidget);

      // FIX: Make the finder more precise to avoid ambiguity.
      await tester.longPress(find.widgetWithText(InkWell, 'Card to Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // FIX: Be specific about which 'Delete' button to press.
      final deleteDialog = find.widgetWithText(AlertDialog, 'Delete Card?');
      await tester.tap(find.descendant(of: deleteDialog, matching: find.text('Delete')));
      await tester.pumpAndSettle();

      expect(find.text('Card to Delete'), findsNothing);
    });

    testWidgets('deletes a set after confirmation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set to be Deleted');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Set to be Deleted'), findsOneWidget);

      await tester.longPress(find.text('Set to be Deleted'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Set'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Set to be Deleted'), findsNothing);
    });

    testWidgets('moves a card between sets', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set A');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Set B');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set A'));
      await tester.pumpAndSettle();

      await tester.tap(find.byWidgetPredicate((widget) => widget is FloatingActionButton && widget.heroTag == 'add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Movable Card');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Movable Card'), findsOneWidget);

      // FIX: Use a more robust finder for the long-press action.
      await tester.longPress(find.widgetWithText(InkWell, 'Movable Card'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set B').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Movable Card'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Set B'));
      await tester.pumpAndSettle();

      expect(find.text('Movable Card'), findsOneWidget);
    });
  });
}
