import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/repositories/label_repository.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/editor/video_editor_screen.dart';

class AddEditCardDialog extends StatefulWidget {
  final VocabCard? card;
  final VocabSet vocabSet;

  const AddEditCardDialog({
    super.key,
    this.card,
    required this.vocabSet,
  });

  @override
  State<AddEditCardDialog> createState() => _AddEditCardDialogState();
}

class _AddEditCardDialogState extends State<AddEditCardDialog> {
  late final bool isEditing;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late List<String> labels;
  late double rating;
  late int? selectedSetId;
  String? mediaPath;
  List<VocabSet> allSets = [];

  // Repositories from locator
  final ISetRepository _setRepository = locator<ISetRepository>();
  final ILabelRepository _labelRepository = locator<ILabelRepository>();

  @override
  void initState() {
    super.initState();
    isEditing = widget.card != null;
    titleController = TextEditingController(text: widget.card?.title ?? '');
    descriptionController =
        TextEditingController(text: widget.card?.description ?? '');
    labels = List<String>.from(widget.card?.labels ?? []);
    rating = (widget.card?.rating ?? 0).toDouble();
    mediaPath = widget.card?.mediaPath;
    selectedSetId = widget.card?.setId ?? widget.vocabSet.id;

    // Fetch all sets for the dropdown
    _setRepository.getAllSets().then((sets) {
      if (mounted) {
        setState(() {
          allSets = sets;
        });
      }
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: source);

    if (pickedFile != null && mounted) {
      final editedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => VideoEditorScreen(video: File(pickedFile.path)),
        ),
      );

      if (editedFile != null) {
        setState(() {
          mediaPath = editedFile.path;
        });
      }
    }
  }

  void _addLabel(StateSetter setState) async {
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
    return AlertDialog(
      title: Text(isEditing ? "Edit Card" : "New Card"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            if (isEditing)
              DropdownButtonFormField<int>(
                initialValue: allSets.any((s) => s.id == selectedSetId) ? selectedSetId : null,
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
                decoration: const InputDecoration(labelText: 'Move to Set'),
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
                  TextButton.icon(onPressed: () => _pickMedia(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text("Gallery")),
                  TextButton.icon(onPressed: () => _pickMedia(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text("Camera")),
                ],
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: labels.map((label) => GestureDetector(
                  onLongPress: () => setState(() => labels.remove(label)),
                  child: Chip(label: Text(label))
              )).toList(),
            ),
            TextButton.icon(onPressed: () => _addLabel(setState), icon: const Icon(Icons.add), label: const Text("Add Label")),
            if (isEditing)
              Slider(value: rating, onChanged: (newRating) => setState(() => rating = newRating), min: 0, max: 5, divisions: 5, label: rating.round().toString()),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              Navigator.pop(
                context,
                VocabCard(
                  id: widget.card?.id,
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
          child: Text(isEditing ? "Save" : "Add"),
        ),
      ],
    );
  }
}
