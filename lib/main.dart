import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: NavigationBarScreen());
  }
}

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreen();
}

class _NavigationBarScreen extends State<NavigationBarScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SetsScreen(),
    AllCardsScreen(),
    StatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning to switch states')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Sets'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_bar_chart),
            label: 'Stats',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SetsScreen extends StatelessWidget {
  const SetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(title: Text("Example Set 1")),
          ListTile(title: Text("Example Set 2")),
        ],
      ),
    );
  }
}

class AllCardsScreen extends StatelessWidget {
  const AllCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("All cards will go here"));
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Stats will go here"));
  }
}
