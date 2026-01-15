import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/models/visibility.dart' as model;
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/all_cards/all_cards_screen.dart';
import 'package:projects/screens/sets/sets_screen.dart';
import 'package:projects/screens/profile/profile_screen.dart';
import 'package:projects/screens/training/training_screen.dart';
import 'package:projects/services/cloud_service.dart';
import 'package:app_links/app_links.dart';

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreen();
}

class _NavigationBarScreen extends State<NavigationBarScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _widgetOptions;
  StreamSubscription<Uri>? _linkSubscription;

  // Keys are now instance variables of the state
  late final GlobalKey<SetsScreenState> _setsScreenKey;
  late final GlobalKey<AllCardsScreenState> _allCardsScreenKey;

  // Dependencies from locator
  final AppLinks _appLinks = locator<AppLinks>();
  final CloudService _cloudService = locator<CloudService>();
  final ISetRepository _setRepository = locator<ISetRepository>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setsScreenKey = GlobalKey<SetsScreenState>();
    _allCardsScreenKey = GlobalKey<AllCardsScreenState>();
    _widgetOptions = <Widget>[
      SetsScreen(key: _setsScreenKey),
      AllCardsScreen(key: _allCardsScreenKey),
      const ProfileScreen(),
    ];
    _initAppLinks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      if (mounted) {
        final setId = uri.queryParameters['set'];
        if (setId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Importing set with ID: $setId...")),
          );
          final vocabSet = await _cloudService.downloadVocabSet(setId);
          if (vocabSet != null) {
            await _setRepository.importSet(vocabSet);
            _setsScreenKey.currentState?.reloadSets();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("'${vocabSet.name}' imported successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Import failed. Check the link and try again."),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    });
  }

  static const List<String> _appBarTitles = <String>[
    'My Sets',
    'All Cards',
    'My Profile',
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  String _visibilityToString(model.Visibility visibility) {
    switch (visibility) {
      case model.Visibility.private:
        return 'Private (not shared)';
      case model.Visibility.publicView:
        return 'Anyone with the link can view';
      case model.Visibility.publicCooperate:
        return 'Anyone with the link can cooperate';
    }
  }

  void _addSet() async {
    final controller = TextEditingController();
    model.Visibility selectedVisibility = model.Visibility.private;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create a New Set"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Set Name',
                      hintText: 'Enter the name of your new set',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sharing Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<model.Visibility>(
                    value: selectedVisibility,
                    isExpanded: true,
                    onChanged: (model.Visibility? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedVisibility = newValue;
                        });
                      }
                    },
                    items: model.Visibility.values.map((model.Visibility visibility) {
                      return DropdownMenuItem<model.Visibility>(
                        value: visibility,
                        child: Text(_visibilityToString(visibility)),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, {
                        'name': controller.text.trim(),
                        'visibility': selectedVisibility,
                      });
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final String name = result['name'];
      final model.Visibility visibility = result['visibility'];
      await _setRepository.insertSet(VocabSet(name: name, visibility: visibility));
      _setsScreenKey.currentState?.reloadSets();
    }
  }

  void _startAllCardsTraining() {
    final filteredCards = _allCardsScreenKey.currentState?.filteredCards ?? [];
    if (filteredCards.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrainingScreen(cards: filteredCards)),
      ).then((_) => _allCardsScreenKey.currentState?.loadData());
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
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
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
              tooltip: 'Add New Set',
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
