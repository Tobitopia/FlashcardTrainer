import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/widgets/card_tile.dart';

class AllCardsScreen extends StatefulWidget {
  const AllCardsScreen({super.key});

  @override
  State<AllCardsScreen> createState() => _AllCardsScreenState();
}

class _AllCardsScreenState extends State<AllCardsScreen> {
  late Future<List<VocabCard>> _allCardsFuture;
  late Future<List<String>> _allLabelsFuture;
  final Set<String> _selectedLabels = {};
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _allCardsFuture = dbHelper.getAllCards();
      _allLabelsFuture = dbHelper.getAllLabels();
    });
  }

  void _toggleLabel(String label) {
    setState(() {
      if (_selectedLabels.contains(label)) {
        _selectedLabels.remove(label);
      } else {
        _selectedLabels.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Cards")),
      body: Column(
        children: [
          FutureBuilder<List<String>>(
            future: _allLabelsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final labels = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: labels.map((label) => FilterChip(
                    label: Text(label),
                    selected: _selectedLabels.contains(label),
                    onSelected: (_) => _toggleLabel(label),
                  )).toList(),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<VocabCard>>(
              future: _allCardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: \${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No cards found."));
                } else {
                  final allCards = snapshot.data!;
                  final filteredCards = _selectedLabels.isEmpty
                      ? allCards
                      : allCards.where((card) => _selectedLabels.any((label) => card.labels.contains(label))).toList();

                  if (filteredCards.isEmpty) {
                    return const Center(child: Text("No cards match your filter."));
                  }

                  return GridView.count(
                    crossAxisCount: 2,
                    children: filteredCards.map((c) => CardTile(card: c)).toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
