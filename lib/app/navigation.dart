import 'dart:async';
import 'dart:ui';
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

  late final GlobalKey<SetsScreenState> _setsScreenKey;
  late final GlobalKey<AllCardsScreenState> _allCardsScreenKey;

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
        final role = uri.queryParameters['role'] ?? 'viewer';
        
        if (setId != null) {
          _showGlassySnackBar("Joining set as $role...", Colors.blueAccent);
          
          final joined = await _cloudService.joinVocabSet(setId, role);
          
          if (joined) {
            final vocabSet = await _cloudService.downloadVocabSet(setId);
            if (vocabSet != null) {
              await _setRepository.importSet(vocabSet);
              _setsScreenKey.currentState?.reloadSets();
              if (mounted) {
                _showGlassySnackBar("'${vocabSet.name}' joined successfully!", Colors.green);
              }
            } else {
              if (mounted) _showGlassySnackBar("Failed to download set data.", Colors.red);
            }
          } else {
             if (mounted) _showGlassySnackBar("Could not join set. Access restricted.", Colors.red);
          }
        }
      }
    });
  }

  void _showGlassySnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static const List<String> _appBarTitles = <String>[
    'My Sets',
    'All Cards',
    'Profile',
  ];

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutExpo,
    );
  }

  String _visibilityToString(model.Visibility visibility) {
    switch (visibility) {
      case model.Visibility.private:
        return 'Private (Internal)';
      case model.Visibility.publicView:
        return 'Link: View Only';
      case model.Visibility.publicCooperate:
        return 'Link: Cooperative';
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
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                title: const Text("Create StepSet", style: TextStyle(color: Color(0xFF8146BD))),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Set Name',
                          filled: true,
                          fillColor: Colors.purple.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Sharing:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      DropdownButton<model.Visibility>(
                        value: selectedVisibility,
                        isExpanded: true,
                        underline: const SizedBox(),
                        onChanged: (model.Visibility? newValue) {
                          if (newValue != null) setState(() => selectedVisibility = newValue);
                        },
                        items: model.Visibility.values.map((v) => DropdownMenuItem(value: v, child: Text(_visibilityToString(v)))).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(ctx, {
                          'name': controller.text.trim(),
                          'visibility': selectedVisibility,
                        });
                      }
                    },
                    child: const Text("Create"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      await _setRepository.insertSet(VocabSet(
        name: result['name'], 
        visibility: result['visibility'],
        isProgression: false, // Default to false, can be toggled inside
      ));
      _setsScreenKey.currentState?.reloadSets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 30, errorBuilder: (c, e, s) => const Icon(Icons.psychology, color: Color(0xFF8146BD))),
            const SizedBox(width: 10),
            Text(_appBarTitles[_selectedIndex]),
          ],
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        children: _widgetOptions,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          border: const Border(top: BorderSide(color: Colors.black12, width: 0.5)),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), activeIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF8146BD)), label: 'Sets'),
            BottomNavigationBarItem(icon: Icon(Icons.style_rounded), activeIcon: Icon(Icons.style_rounded, color: Color(0xFF8146BD)), label: 'Cards'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), activeIcon: Icon(Icons.person_rounded, color: Color(0xFF8146BD)), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF8146BD),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
      floatingActionButton: _selectedIndex == 2 ? null : FloatingActionButton(
        heroTag: 'main_fab', // Unique hero tag
        onPressed: _selectedIndex == 0 ? _addSet : () => _allCardsScreenKey.currentState?.filteredCards.isNotEmpty == true 
          ? Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingScreen(cards: _allCardsScreenKey.currentState!.filteredCards)))
          : null,
        child: Icon(_selectedIndex == 0 ? Icons.add : Icons.play_arrow),
      ),
    );
  }
}
