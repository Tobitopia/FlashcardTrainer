import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/widgets/card_tile.dart';

class SetDetailScreen extends StatefulWidget {
  final VocabSet vocabSet;
  const SetDetailScreen({super.key, required this.vocabSet});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  late Future<List<VocabCard>> _cardsFuture;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    setState(() {
      _cardsFuture = dbHelper.getCardsForSet(widget.vocabSet.id!);
    });
  }

  void _addCard() async {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final labels = <String>[];
    var rating = 0.0;

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("New Card"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: frontController, decoration: const InputDecoration(labelText: "Front")),
                    TextField(controller: backController, decoration: const InputDecoration(labelText: "Back")),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      children: labels.map((label) => Chip(
                        label: Text(label),
                        onDeleted: () {
                          setState(() => labels.remove(label));
                        },
                      )).toList(),
                    ),
                    TextButton.icon(
                      onPressed: () => _addLabel(labels, setState),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Label"),
                    ),
                    Slider(
                      value: rating,
                      onChanged: (newRating) {
                        setState(() => rating = newRating);
                      },
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: rating.round().toString(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                      Navigator.pop(
                        ctx,
                        VocabCard(
                          front: frontController.text,
                          back: backController.text,
                          labels: labels,
                          rating: rating.round(),
                        ),
                      );
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
      await dbHelper.insertCard(result, widget.vocabSet.id!);
      _loadCards();
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
            child: const Text("Edit"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCard(card.id!);
            },
            child: const Text("Delete"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    _loadCards();
  }

  void _editCard(VocabCard card) async {
    final frontController = TextEditingController(text: card.front);
    final backController = TextEditingController(text: card.back);
    final labels = List<String>.from(card.labels);
    var rating = card.rating.toDouble();

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Card"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: frontController, decoration: const InputDecoration(labelText: "Front")),
                    TextField(controller: backController, decoration: const InputDecoration(labelText: "Back")),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      children: labels.map((label) => Chip(
                        label: Text(label),
                        onDeleted: () {
                          setState(() => labels.remove(label));
                        },
                      )).toList(),
                    ),
                    TextButton.icon(
                      onPressed: () => _addLabel(labels, setState),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Label"),
                    ),
                    Slider(
                      value: rating,
                      onChanged: (newRating) {
                        setState(() => rating = newRating);
                      },
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: rating.round().toString(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    if (frontController.text.isNotEmpty && backController.text.isNotEmpty) {
                      Navigator.pop(
                        ctx,
                        VocabCard(
                          id: card.id,
                          front: frontController.text,
                          back: backController.text,
                          labels: labels,
                          rating: rating.round(),
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await dbHelper.updateCard(result);
      _loadCards();
    }
  }

  void _addLabel(List<String> labels, StateSetter setState) async {
    final labelController = TextEditingController();
    final allLabels = await dbHelper.getAllLabels();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Label"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: "New Label")),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: allLabels.map((label) => FilterChip(
                label: Text(label),
                selected: labels.contains(label),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => labels.add(label));
                  } else {
                    setState(() => labels.remove(label));
                  }
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                Navigator.pop(ctx, labelController.text);
              }
            },
            child: const Text("Add New"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => labels.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vocabSet.name)),
      body: FutureBuilder<List<VocabCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: \${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No cards yet. Add one!"));
          } else {
            final cards = snapshot.data!;
            return GridView.count(
              crossAxisCount: 2,
              children: cards.map((c) => InkWell(
                onTap: () => _showCardDialog(c),
                child: CardTile(card: c),
              )).toList(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
      ),
    );
  }
}
