import 'package:flutter/material.dart';
import 'package:projects/card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('MyVocabTrainer')),
      body: Center(child: Text('Hello')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {  },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          fixedColor: Colors.green,
          items: const [
            BottomNavigationBarItem(
              label: "Sets",
              icon: Icon(Icons.account_balance_wallet),
            ),
            BottomNavigationBarItem(
              label: "Cards",
              icon: Icon(Icons.add_card),
            ),
            BottomNavigationBarItem(
              label: "Training",
              icon: Icon(Icons.directions_run),
            ),
          ],
            onTap: (int indexOfItem) {}),
    ),
    );
  }
}
