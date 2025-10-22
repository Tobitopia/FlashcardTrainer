import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/screens/all_cards/all_cards_screen.dart';
import 'package:projects/screens/sets/sets_screen.dart';
import 'package:projects/screens/stats/stats_screen.dart';
import 'package:projects/screens/training/training_screen.dart';
import 'package:projects/services/cloud_service.dart';
import 'package:app_links/app_links.dart'; // Import the new package

final GlobalKey<SetsScreenState> setsScreenKey = GlobalKey<SetsScreenState>();
final GlobalKey<AllCardsScreenState> allCardsScreen_key = GlobalKey<AllCardsScreenState>();

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreen();
}

class _NavigationBarScreen extends State<NavigationBarScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _widgetOptions;
  StreamSubscription<Uri>? _linkSubscription; // Changed to use app_links's stream

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _widgetOptions = <Widget>[
      SetsScreen(key: setsScreenKey),
      AllCardsScreen(key: allCardsScreen_key),
      const StatsScreen(),
    ];
    _initAppLinks(); // Changed the method name for clarity
  }

  @override
  void dispose() {
    _pageController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    final appLinks = AppLinks(); // Use the AppLinks class

    _linkSubscription = appLinks.uriLinkStream.listen((uri) {
      if (mounted) {
        final setId = uri.queryParameters['set'];
        if (setId != null) {
          _showImportDialog(prefilledId: setId);
        }
      }
    });
  }

  static const List<String> _appBarTitles = <String>[
    'My Sets',
    'All Cards',
    'My Stats',
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void _addSet() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Set"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Add"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.insertSet(VocabSet(name: result));
      setsScreenKey.currentState?.reloadSets();
    }
  }

  void _showImportDialog({String? prefilledId}) {
    final controller = TextEditingController(text: prefilledId);
    final cloudService = CloudService();
    final dbHelper = DatabaseHelper.instance;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Set'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Paste Set ID or use link'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final setId = controller.text.trim();
              if (setId.isNotEmpty) {
                final vocabSet = await cloudService.downloadVocabSet(setId);
                if (vocabSet != null) {
                  await dbHelper.importSet(vocabSet);
                  setsScreenKey.currentState?.reloadSets();
                  if (mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("'${vocabSet.name}' imported successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  if (mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Import failed. Check the ID and try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _startAllCardsTraining() {
    final filteredCards = allCardsScreen_key.currentState?.filteredCards ?? [];
    if (filteredCards.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainingScreen(cards: filteredCards)),
      ).then((_) => allCardsScreen_key.currentState?.loadData());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No cards to train with the current filters!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles.elementAt(_selectedIndex)),
        centerTitle: true,
        elevation: 4.0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: PageView(
        controller: _pageController,
        children: _widgetOptions,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_outlined), label: 'Sets'),
          BottomNavigationBarItem(icon: Icon(Icons.style_outlined), label: 'All Cards'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Stats'),
        ],
        currentIndex: _selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.primary,
        selectedItemColor: Theme.of(context).colorScheme.onPrimary,
        unselectedItemColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  onPressed: _showImportDialog,
                  tooltip: 'Import Set',
                  child: const Icon(Icons.cloud_download_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: _addSet,
                  tooltip: 'Add New Set',
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : _selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: _startAllCardsTraining,
                  child: const Icon(Icons.play_arrow),
                )
              : null,
    );
  }
}
