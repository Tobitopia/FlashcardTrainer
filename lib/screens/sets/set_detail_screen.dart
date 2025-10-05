import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/widgets/card_tile.dart';
import 'package:projects/screens/media/video_player_screen.dart';

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

  void _addOrEditCard([VocabCard? card]) async {
    final isEditing = card != null;
    final titleController = TextEditingController(text: card?.title ?? '');
    final descriptionController = TextEditingController(text: card?.description ?? '');
    final labels = List<String>.from(card?.labels ?? []);
    var rating = (card?.rating ?? 0).toDouble();
    String? mediaPath = card?.mediaPath;

    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Card" : "New Card"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                    TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                    const SizedBox(height: 16),
                    // --- Improved Media Display Logic ---
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
                    // --- End of Improved Media Display ---
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
                          id: card?.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          mediaPath: mediaPath,
                          labels: labels,
                          rating: rating.round(),
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? "Save" : "Add"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (isEditing) {
        await dbHelper.updateCard(result);
      } else {
        await dbHelper.insertCard(result, widget.vocabSet.id!);
      }
      _loadCards();
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
                if (card.mediaPath != null && File(card.mediaPath!).existsSync()) 
                  Image.file(File(card.mediaPath!)),
                const SizedBox(height: 8),
                Text(card.description),
              ],
            ),
          ),
          actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")) ],
        ),
      );
    }
  }

  void _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    _loadCards();
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
              children: allLabels.map((label) => FilterChip(label: Text(label), selected: labels.contains(label), onSelected: (selected) { if (selected) { setState(() => labels.add(label)); } else { setState(() => labels.remove(label)); } Navigator.pop(ctx); },)).toList(),
            ),
          ],
        ),
        actions: [ TextButton(onPressed: () { if (labelController.text.isNotEmpty) { Navigator.pop(ctx, labelController.text); } }, child: const Text("Add New")) ],
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
                onTap: () => _viewCard(c),
                onLongPress: () => _showOptionsDialog(c),
                child: CardTile(card: c),
              )).toList(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCard(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
