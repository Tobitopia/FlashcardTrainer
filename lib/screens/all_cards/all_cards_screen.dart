import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart'; // Import VocabSet
import 'package:projects/widgets/card_tile.dart';
import 'package:projects/screens/media/video_player_screen.dart';

class AllCardsScreen extends StatefulWidget {
  const AllCardsScreen({super.key});

  @override
  State<AllCardsScreen> createState() => _AllCardsScreenState();
}

class _AllCardsScreenState extends State<AllCardsScreen> {
  late Future<List<VocabCard>> _allCardsFuture;
  late Future<List<String>> _allLabelsFuture;
  final dbHelper = DatabaseHelper.instance;

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

  void _addOrEditCard([VocabCard? card]) async {
    final isEditing = card != null;
    if (!isEditing) return;

    // --- Fetch all sets for the dropdown ---
    final allSets = await dbHelper.getAllSets();

    final titleController = TextEditingController(text: card?.title ?? '');
    final descriptionController = TextEditingController(text: card?.description ?? '');
    final labels = List<String>.from(card?.labels ?? []);
    var rating = (card?.rating ?? 0).toDouble();
    String? mediaPath = card?.mediaPath;
    // --- State for the selected set ID ---
    int? selectedSetId = card?.setId;

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
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                    // --- Dropdown to Move Set ---
                    DropdownButtonFormField<int>(
                      value: selectedSetId,
                      items: allSets.map((set) {
                        return DropdownMenuItem<int>(
                          value: set.id,
                          child: Text(set.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSetId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Set'),
                    ),
                    const SizedBox(height: 16),
                    if (mediaPath != null)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text("Video selected", style: TextStyle(fontStyle: FontStyle.italic))),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => setState(() => mediaPath = null),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(onPressed: () => _pickMedia(ImageSource.gallery, (path) => setState(() => mediaPath = path)), icon: const Icon(Icons.photo_library), label: const Text("Gallery")),
                          TextButton.icon(onPressed: () => _pickMedia(ImageSource.camera, (path) => setState(() => mediaPath = path)), icon: const Icon(Icons.camera_alt), label: const Text("Camera")),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      children: labels.map((label) => Chip(label: Text(label), onDeleted: () => setState(() => labels.remove(label)))).toList(),
                    ),
                    TextButton.icon(onPressed: () => _addLabel(labels, setState), icon: const Icon(Icons.add), label: const Text("Add Label")),
                    Slider(value: rating, onChanged: (newRating) => setState(() => rating = newRating), min: 0, max: 5, divisions: 5, label: rating.round().toString()),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                      Navigator.pop(
                        ctx,
                        VocabCard(
                          id: card!.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          mediaPath: mediaPath,
                          labels: labels,
                          rating: rating.round(),
                          // --- Pass the selected set ID to the card ---
                          setId: selectedSetId,
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
      _loadData();
    }
  }

  Future<void> _pickMedia(ImageSource source, Function(String path) onPicked) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: source);
    if (pickedFile != null) {
      onPicked(pickedFile.path);
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
                Text(card.description),
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
      await dbHelper.deleteCard(cardId);
      _loadData();
    }
  }

  void _addLabel(List<String> labels, StateSetter setState) async {
    final labelController = TextEditingController();
    final allLabels = await dbHelper.getAllLabels();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return AlertDialog(
              title: const Text("Add Label"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: "New Label",
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final newLabel = labelController.text;
                            if (newLabel.isNotEmpty && !labels.contains(newLabel)) {
                              setState(() {
                                labels.add(newLabel);
                              });
                              dialogSetState(() {});
                              labelController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (allLabels.isNotEmpty) ...[
                      const Text("Or select existing:"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: allLabels.map((label) {
                          final isSelected = labels.contains(label);
                          return FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  labels.add(label);
                                } else {
                                  labels.remove(label);
                                }
                              });
                              dialogSetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search title or description...',
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
                  Text('Min Rating: ${_minRating.round()}'),
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
                  children: filteredCards.map((c) => InkWell(
                    onTap: () => _viewCard(c),
                    onLongPress: () => _showOptionsDialog(c),
                    child: CardTile(card: c),
                  )).toList(),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
