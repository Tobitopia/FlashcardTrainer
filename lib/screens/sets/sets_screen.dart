import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/sets/set_detail_screen.dart';
import 'package:projects/services/cloud_service.dart';
import '../../widgets/set_tile.dart';
import 'package:projects/services/auth_service.dart';
import 'package:projects/models/visibility.dart' as model;

class SetsScreen extends StatefulWidget {
  const SetsScreen({super.key});

  @override
  SetsScreenState createState() => SetsScreenState();
}

class SetsScreenState extends State<SetsScreen> {
  late Future<List<VocabSet>> _setsFuture;

  // Repositories and Services from locator
  final ISetRepository _setRepository = locator<ISetRepository>();
  final ICardRepository _cardRepository = locator<ICardRepository>();
  final CloudService _cloudService = locator<CloudService>();
  final AuthService _authService = locator<AuthService>();

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  void reloadSets() {
    setState(() {
      _setsFuture = _setRepository.getAllSets();
    });
  }

  void _loadSets() {
    setState(() {
      _setsFuture = _setRepository.getAllSets();
    });
  }

  void _showShareDialog(VocabSet set) {
    String role = "viewer";
    if (set.visibility == model.Visibility.publicCooperate) {
      role = "editor";
    }
    
    final shareLink = "https://stepnote.app/share?set=${set.cloudId}&role=$role";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this set as $role:'),
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

  // New: Function to handle sharing a synced set
  void _shareSetLink(VocabSet set) {
    if (set.cloudId != null) {
      _showShareDialog(set);
    }
  }
  
    void _onVisibilityChanged(VocabSet set, model.Visibility newVisibility) async {
    final updatedSet = VocabSet(
      id: set.id,
      name: set.name,
      cards: set.cards,
      cloudId: set.cloudId,
      isSynced: false, // Mark as unsynced
      visibility: newVisibility,
    );

    await _setRepository.updateSet(updatedSet);
    reloadSets(); // Refresh UI
  }


  // Updated: Handles both upload and update
  void _uploadSet(VocabSet set) async {
    final cards = await _cardRepository.getCardsForSet(set.id!);
    final fullSet = VocabSet(id: set.id, name: set.name, cards: cards, cloudId: set.cloudId, visibility: set.visibility);

    final String? newCloudId = await _cloudService.uploadOrUpdateVocabSet(fullSet, existingCloudId: set.cloudId);

    if (mounted && newCloudId != null) {
      // Update local database with the cloud ID and mark as synced
      await _setRepository.updateSetCloudStatus(set.id!, newCloudId, isSynced: true);
      reloadSets(); // Refresh UI to show the new sync status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(set.cloudId == null ? "Set uploaded successfully!" : "Set updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
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

  // Updated: Marks set as unsynced after editing
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

    if (newName != null && newName.isNotEmpty && newName != set.name) {
      final updatedSet = VocabSet(id: set.id, name: newName, visibility: set.visibility);
      await _setRepository.updateSet(updatedSet);
      // Mark as unsynced after a successful name change
      await _setRepository.markSetAsUnsynced(set.id!);
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
      await _setRepository.deleteSet(setId);
      reloadSets();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onShare: () => _shareSetLink(s), // Pass the new share function
                onVisibilityChanged: (newVisibility) => _onVisibilityChanged(s, newVisibility),
              )).toList(),
            );
          }
        },
      ),
    );
  }
}
