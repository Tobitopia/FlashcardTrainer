import 'package:flutter/material.dart';

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