import 'package:flutter/material.dart';
import 'package:projects/models/vocab_set.dart';
import '../../models/vocab_card.dart';
import '../../widgets/card_tile.dart';

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


  void _showCardDialog(VocabCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card.front),
        content: Text(card.back),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editCard(card);
            },
            child: Text("Edit"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }


  void _editCard(VocabCard card) async {
    final frontController = TextEditingController(text: card.front);
    final backController = TextEditingController(text: card.back);

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Card"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: frontController, decoration: InputDecoration(labelText: "Front")),
            TextField(controller: backController, decoration: InputDecoration(labelText: "Back")),
          ],
        ),
        actions: [
          // This "Cancel" button was added for better usability
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Just close the dialog
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                Navigator.pop(ctx, VocabCard(front: frontController.text, back: backController.text));
              }
            },
            child: Text("Save"),
          ),
        ],
      ), // The semicolon was moved from here...
    ); // ...to here, after the showDialog call.

    if (result != null) {
      setState(() {
        card.front = result.front;
        card.back = result.back;
      });
    }
  } // A closing brace was added here to properly close the method.


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vocabSet.name)),
      body: GridView.count(
        crossAxisCount: 2,
        children: widget.vocabSet.cards.map((c) => InkWell(
            onTap: () => _showCardDialog(c),
            child: CardTile(card: c),
        )).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
      ),
    );
  }
  }
