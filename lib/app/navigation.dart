import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/screens/all_cards/all_cards_screen.dart';
import 'package:projects/screens/sets/sets_screen.dart';
import 'package:projects/screens/stats/stats_screen.dart';
import 'package:projects/screens/training/training_screen.dart';

final GlobalKey<SetsScreenState> setsScreenKey = GlobalKey<SetsScreenState>();
final GlobalKey<AllCardsScreenState> allCardsScreenKey = GlobalKey<AllCardsScreenState>();

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreen();
}

class _NavigationBarScreen extends State<NavigationBarScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      SetsScreen(key: setsScreenKey),
      AllCardsScreen(key: allCardsScreenKey),
      const StatsScreen(),
    ];
  }

  static const List<String> _appBarTitles = <String>[
    'My Sets',
    'All Cards',
    'My Stats',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

  void _startAllCardsTraining() {
    final filteredCards = allCardsScreenKey.currentState?.filteredCards ?? [];
    if (filteredCards.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainingScreen(cards: filteredCards)),
      ).then((_) => allCardsScreenKey.currentState?.loadData());
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
      body: _widgetOptions.elementAt(_selectedIndex),
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
          ? FloatingActionButton(
              onPressed: _addSet,
              child: const Icon(Icons.add),
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
