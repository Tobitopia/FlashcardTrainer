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
  final dbHelper = DatabaseHelper.instance;

  // State for new filters
  final _searchController = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  final Set<String> _selectedLabels = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Text Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search title or description...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    // Add a clear button
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Rating Slider
                Row(
                  children: [
                    Text('Min Rating: ${_minRating.round()}'),
                    Expanded(
                      child: Slider(
                        value: _minRating,
                        onChanged: (newRating) {
                          setState(() => _minRating = newRating);
                        },
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _minRating.round().toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Label Filters
          FutureBuilder<List<String>>(
            future: _allLabelsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final labels = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
          // Card Grid
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
                  // Apply all filters
                  final filteredCards = allCards.where((card) {
                    final ratingMatch = card.rating >= _minRating.round();
                    final labelMatch = _selectedLabels.isEmpty || _selectedLabels.any((label) => card.labels.contains(label));
                    final query = _searchQuery.toLowerCase();
                    final searchMatch = query.isEmpty ||
                        card.title.toLowerCase().contains(query) ||
                        card.description.toLowerCase().contains(query);
                    return ratingMatch && labelMatch && searchMatch;
                  }).toList();

                  if (filteredCards.isEmpty) {
                    return const Center(child: Text("No cards match your filters."));
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
