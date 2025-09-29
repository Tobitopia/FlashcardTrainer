import 'package:flutter/material.dart';
import 'package:projects/models/vocab_set.dart';
import '../../models/vocab_card.dart';

class SetDetailScreen extends StatefulWidget {
  final VocabSet vocabSet;
  const SetDetailScreen({super.key, required this.vocabSet});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  void _addCard() async {
    final frontController = TextEditingController();
    final backController = TextEditingController();

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("New Card"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: frontController, decoration: InputDecoration(labelText: "Front")),
            TextField(controller: backController, decoration: InputDecoration(labelText: "Back")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                Navigator.pop(ctx, VocabCard(front: frontController.text, back: backController.text));
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => widget.vocabSet.addCard(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vocabSet.name)),
      body: ListView(
        children: widget.vocabSet.cards
            .map((card) => ListTile(title: Text(card.front), subtitle: Text(card.back)))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
      ),
    );
  }
}
