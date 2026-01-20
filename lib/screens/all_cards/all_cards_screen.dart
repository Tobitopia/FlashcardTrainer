import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:projects/repositories/label_repository.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/widgets/card_tile.dart';
import 'package:projects/screens/media/video_player_screen.dart';

class AllCardsScreen extends StatefulWidget {
  const AllCardsScreen({super.key});

  @override
  AllCardsScreenState createState() => AllCardsScreenState();
}

class AllCardsScreenState extends State<AllCardsScreen> {
  late Future<List<VocabCard>> _allCardsFuture;
  late Future<List<String>> _allLabelsFuture;

  final ICardRepository _cardRepository = locator<ICardRepository>();
  final ILabelRepository _labelRepository = locator<ILabelRepository>();
  final ISetRepository _setRepository = locator<ISetRepository>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  final Set<String> _selectedLabels = {};
  List<VocabCard> _filteredCards = [];

  List<VocabCard> get filteredCards => _filteredCards;

  @override
  void initState() {
    super.initState();
    loadData();
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

  void loadData() {
    setState(() {
      _allCardsFuture = _cardRepository.getAllCards();
      _allLabelsFuture = _labelRepository.getAllLabels();
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

    final allSets = await _setRepository.getAllSets();

    final titleController = TextEditingController(text: card.title);
    final descriptionController = TextEditingController(text: card.description ?? '');
    final labels = List<String>.from(card.labels);
    var rating = (card.rating).toDouble();
    String? mediaPath = card.mediaPath;
    int? selectedSetId = card.setId;

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Edit StepCard"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController, 
                        decoration: InputDecoration(
                          labelText: "Title",
                          filled: true,
                          fillColor: Colors.purple.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        )
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController, 
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Description",
                          filled: true,
                          fillColor: Colors.purple.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        )
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: selectedSetId,
                        items: allSets.map((set) => DropdownMenuItem<int>(value: set.id, child: Text(set.name))).toList(),
                        onChanged: (value) => setState(() => selectedSetId = value),
                        decoration: const InputDecoration(labelText: 'Belongs to Set'),
                      ),
                      const SizedBox(height: 16),
                      if (mediaPath != null)
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(child: Text("Media attached", style: TextStyle(fontStyle: FontStyle.italic))),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20, color: Colors.red),
                              onPressed: () => setState(() => mediaPath = null),
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
                      Slider(
                        value: rating, 
                        onChanged: (newRating) => setState(() => rating = newRating), 
                        min: 0, max: 5, divisions: 5, 
                        label: rating.round().toString(),
                        activeColor: const Color(0xFF8146BD),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        Navigator.pop(
                          ctx,
                          VocabCard(
                            id: card.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            mediaPath: mediaPath,
                            labels: labels,
                            rating: rating.round(),
                            setId: selectedSetId,
                          ),
                        );
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      await _cardRepository.updateCard(result);
      loadData();
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
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            SimpleDialogOption(
              onPressed: () { Navigator.pop(ctx); _addOrEditCard(card); },
              child: const Row(children: [Icon(Icons.edit_outlined, color: Colors.blue), SizedBox(width: 12), Text("Edit")])
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(ctx); _deleteCard(card.id!); },
              child: const Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 12), Text("Delete")])
            ),
          ],
        ),
      ),
    );
  }

  void _viewCard(VocabCard card) {
    if (card.mediaPath != null && card.mediaPath!.endsWith('.mp4')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: card.mediaPath!, title: card.title)));
    } else {
      showDialog(
        context: context,
        builder: (ctx) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(card.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card.mediaPath != null && File(card.mediaPath!).existsSync()) 
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(card.mediaPath!))),
                  const SizedBox(height: 12),
                  Text(card.description ?? '', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
          ),
        ),
      );
    }
  }

  void _deleteCard(int cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Delete StepCard?"),
          content: const Text("This will permanently delete this card from its set."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _cardRepository.deleteCard(cardId);
      loadData();
    }
  }

  void _addLabel(List<String> labels, StateSetter setState) async {
    final labelController = TextEditingController();
    final allLabels = await _labelRepository.getAllLabels();

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDF7FF), Color(0xFFFFF0F5)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: kToolbarHeight + 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white.withOpacity(0.5),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search all cards...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF8146BD)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Expanded(
                            child: Slider(
                              value: _minRating,
                              onChanged: (newRating) => setState(() => _minRating = newRating),
                              min: 0,
                              max: 5,
                              divisions: 5,
                              label: _minRating.round().toString(),
                              activeColor: const Color(0xFF8146BD),
                            ),
                          ),
                          Text('${_minRating.round()}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                padding: const EdgeInsets.all(16),
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
                  return const Center(child: Text("No cards yet. Start building your repertoire!"));
                } else {
                  final allCards = snapshot.data!;
                  final rating = _minRating.round();
                  _filteredCards = allCards.where((card) {
                    final ratingMatch = rating == 0 || card.rating == rating;
                    final labelMatch = _selectedLabels.isEmpty || _selectedLabels.any((label) => card.labels.contains(label));
                    final query = _searchQuery.toLowerCase();
                    final searchMatch = query.isEmpty ||
                        card.title.toLowerCase().contains(query) ||
                        (card.description?.toLowerCase().contains(query) ?? false);
                    return ratingMatch && labelMatch && searchMatch;
                  }).toList();

                  if (_filteredCards.isEmpty) {
                    return const Center(child: Text("No cards match your filters."));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _filteredCards.length,
                    itemBuilder: (ctx, i) => InkWell(
                      onTap: () => _viewCard(_filteredCards[i]),
                      onLongPress: () => _showOptionsDialog(_filteredCards[i]),
                      child: CardTile(card: _filteredCards[i]),
                    ),
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
