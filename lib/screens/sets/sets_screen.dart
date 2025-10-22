import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/screens/sets/set_detail_screen.dart';
import 'package:projects/services/cloud_service.dart';
import '../../widgets/set_tile.dart';

class SetsScreen extends StatefulWidget {
  // Add the key parameter here
  const SetsScreen({super.key});

  @override
  SetsScreenState createState() => SetsScreenState();
}

class SetsScreenState extends State<SetsScreen> {
  late Future<List<VocabSet>> _setsFuture;
  final dbHelper = DatabaseHelper.instance;
  final _cloudService = CloudService();

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  void reloadSets() {
    _loadSets();
  }

  void _loadSets() {
    setState(() {
      _setsFuture = dbHelper.getAllSets();
    });
  }

  void _showShareDialog(String setId) {
    final shareLink = "https://vocabtrainer.app/share?set=$setId";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Uploaded!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this link with others:'),
            const SizedBox(height: 8),
            SelectableText(
              shareLink,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link Copied to Clipboard!')),
              );
            },
            child: const Text('Copy Link'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _uploadSet(VocabSet set) async {
    final cards = await dbHelper.getCardsForSet(set.id!);
    final fullSet = VocabSet(id: set.id, name: set.name, cards: cards);

    final String? setId = await _cloudService.uploadVocabSet(fullSet);

    if (mounted && setId != null) {
      _showShareDialog(setId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSetOptionsDialog(VocabSet set) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(set.name),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _editSet(set);
            },
            child: const Text('Edit Name'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSet(set.id!);
            },
            child: const Text('Delete Set', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editSet(VocabSet set) async {
    final controller = TextEditingController(text: set.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Set Name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final updatedSet = VocabSet(id: set.id, name: newName);
      await dbHelper.updateSet(updatedSet);
      reloadSets();
    }
  }

  void _deleteSet(int setId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Set?"),
        content: const Text("Are you sure you want to delete this set and all its cards?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deleteSet(setId);
      reloadSets();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Scaffold was removed previously, but it's good practice for each screen to have its own.
    return Scaffold(
      body: FutureBuilder<List<VocabSet>>(
        future: _setsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No sets yet. Add one!"));
          } else {
            final sets = snapshot.data!;
            return GridView.count(
              padding: const EdgeInsets.all(8),
              crossAxisCount: 2,
              children: sets.map((s) => SetCard(
                set: s,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SetDetailScreen(vocabSet: s),
                  ));
                  reloadSets();
                },
                onLongPress: () => _showSetOptionsDialog(s),
                onUpload: () => _uploadSet(s),
              )).toList(),
            );
          }
        },
      ),
    );
  }
}
