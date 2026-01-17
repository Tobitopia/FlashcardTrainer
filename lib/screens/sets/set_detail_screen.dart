import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/training/training_screen.dart';
import 'package:projects/widgets/add_edit_card_dialog.dart';
import 'package:projects/widgets/card_tile.dart';
import 'package:projects/screens/media/video_player_screen.dart';
import 'package:projects/services/cloud_service.dart';

class SetDetailScreen extends StatefulWidget {
  final VocabSet vocabSet;
  const SetDetailScreen({super.key, required this.vocabSet});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  late Future<List<VocabCard>> _cardsFuture;

  // Repositories and services from locator
  final ICardRepository _cardRepository = locator<ICardRepository>();
  final ISetRepository _setRepository = locator<ISetRepository>();
  final CloudService _cloudService = locator<CloudService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  final Set<String> _selectedLabels = {};
  List<VocabCard> _filteredCards = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
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

  void _loadCards() {
    setState(() {
      _cardsFuture = _cardRepository.getCardsForSet(widget.vocabSet.id!);
    });
  }

  Future<void> _syncWithCloud() async {
    if (widget.vocabSet.cloudId == null) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final cloudSet = await _cloudService.downloadVocabSet(widget.vocabSet.cloudId!);
      if (cloudSet != null) {
        await _setRepository.syncSetWithCloud(cloudSet);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Set synced with cloud!")),
          );
        }
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to fetch cloud data. It might be deleted.")),
          );
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sync error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _loadCards();
      }
    }
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

  void _addOrEditCard([VocabCard? card]) async {
    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) => AddEditCardDialog(
        card: card,
        vocabSet: widget.vocabSet,
      ),
    );

    if (result != null) {
      final isEditing = card != null;
      if (isEditing) {
        await _cardRepository.updateCard(result);
      } else {
        await _cardRepository.insertCard(result, result.setId ?? widget.vocabSet.id!);
      }
      
      // If the set is synced with cloud, mark it as unsynced locally
      if (widget.vocabSet.cloudId != null) {
        await _setRepository.markSetAsUnsynced(widget.vocabSet.id!);
      }
      
      _loadCards();
    }
  }

  void _showOptionsDialog(VocabCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card.title),
        content: const Text("What would you like to do?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _addOrEditCard(card); }, child: const Text("Edit")),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteCard(card.id!); }, child: const Text("Delete")),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _viewCard(VocabCard card) {
    if (card.mediaPath != null && card.mediaPath!.endsWith('.mp4')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: card.mediaPath!, title: card.title)),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(card.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.mediaPath != null && File(card.mediaPath!).existsSync()) Image.file(File(card.mediaPath!)),
                const SizedBox(height: 8),
                Text(card.description ?? ''),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
        ),
      );
    }
  }

  void _deleteCard(int cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Card?"),
        content: const Text("Are you sure you want to permanently delete this card?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed == true) {
      await _cardRepository.deleteCard(cardId);
      
      if (widget.vocabSet.cloudId != null) {
        await _setRepository.markSetAsUnsynced(widget.vocabSet.id!);
      }
      
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vocabSet.name),
        actions: [
          if (widget.vocabSet.cloudId != null)
            _isSyncing 
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                )
              : IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _syncWithCloud,
                  tooltip: 'Sync with Cloud',
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search in this set...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Level: ${_minRating.round() == 0 ? 'Any' : _minRating.round()}'),
                    Expanded(
                      child: Slider(
                        value: _minRating,
                        onChanged: (newRating) => setState(() => _minRating = newRating),
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
          Expanded(
            child: FutureBuilder<List<VocabCard>>(
              future: _cardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No cards yet. Add one!"));
                } else {
                  final allCardsInSet = snapshot.data!;
                  final labelsInSet = allCardsInSet.expand((card) => card.labels).toSet().toList();

                  final rating = _minRating.round();
                  _filteredCards = allCardsInSet.where((card) {
                    final ratingMatch = rating == 0 || card.rating == rating;
                    final labelMatch = _selectedLabels.isEmpty || _selectedLabels.any((label) => card.labels.contains(label));
                    final query = _searchQuery.toLowerCase();
                    final searchMatch = query.isEmpty ||
                        card.title.toLowerCase().contains(query) ||
                        (card.description?.toLowerCase().contains(query) ?? false);
                    return ratingMatch && labelMatch && searchMatch;
                  }).toList();

                  return Column(
                    children: [
                      if (labelsInSet.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Wrap(
                            spacing: 8.0,
                            children: labelsInSet.map((label) => FilterChip(
                              label: Text(label),
                              selected: _selectedLabels.contains(label),
                              onSelected: (_) => _toggleLabel(label),
                            )).toList(),
                          ),
                        ),
                      Expanded(
                        child: _filteredCards.isEmpty
                            ? const Center(child: Text("No cards match your filters."))
                            : GridView.count(
                                crossAxisCount: 2,
                                children: _filteredCards.map((c) => InkWell(
                                  onTap: () => _viewCard(c),
                                  onLongPress: () => _showOptionsDialog(c),
                                  child: CardTile(card: c),
                                )).toList(),
                              ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              if (_filteredCards.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrainingScreen(cards: _filteredCards)),
                ).then((_) => _loadCards());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No cards to train with the current filters!")),
                );
              }
            },
            heroTag: 'train',
            child: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _addOrEditCard(),
            heroTag: 'add',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
