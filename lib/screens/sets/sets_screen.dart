import 'package:flutter/material.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/screens/sets/set_detail_screen.dart';

class SetsScreen extends StatefulWidget {
  const SetsScreen({super.key});

  @override
  State<SetsScreen> createState() => _SetsScreenState();
}

class _SetsScreenState extends State<SetsScreen> {
  final List<VocabSet> _sets = [];

  void _addSet() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("New Set"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text("Add"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _sets.add(VocabSet(name: result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: _sets.map((set) => ListTile(
          title: Text(set.name),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SetDetailScreen(vocabSet: set),
            ));
          },
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSet,
        child: Icon(Icons.add),
      ),
    );
  }
}
