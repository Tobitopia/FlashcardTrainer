import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/sets/set_detail_screen.dart';
import '../../widgets/set_tile.dart';
import 'package:projects/models/visibility.dart' as model;

class SetsScreen extends StatefulWidget {
  const SetsScreen({super.key});

  @override
  SetsScreenState createState() => SetsScreenState();
}

class SetsScreenState extends State<SetsScreen> {
  late Future<List<VocabSet>> _setsFuture;

  final ISetRepository _setRepository = locator<ISetRepository>();

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
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Share StepSet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share this set as $role:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  shareLink,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: shareLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link Copied!')),
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
      ),
    );
  }

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
      isSynced: false, 
      visibility: newVisibility,
      role: set.role,
      isProgression: set.isProgression,
    );

    await _setRepository.updateSet(updatedSet);
    reloadSets(); 
  }


  void _uploadSet(VocabSet set) async {
    final String? newCloudId = await _setRepository.pushSetToCloud(set);

    if (mounted && newCloudId != null) {
      reloadSets(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(set.cloudId == null ? "Set uploaded!" : "Set updated!"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload failed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSetOptionsDialog(VocabSet set) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(set.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _editSet(set);
              },
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Edit Name'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteSet(set);
              },
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete Set', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editSet(VocabSet set) async {
    final controller = TextEditingController(text: set.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Set Name'),
          content: TextField(
            controller: controller, 
            autofocus: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.purple.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != set.name) {
      final updatedSet = VocabSet(
        id: set.id, 
        name: newName, 
        visibility: set.visibility,
        cloudId: set.cloudId,
        isProgression: set.isProgression,
        role: set.role,
      );
      await _setRepository.updateSet(updatedSet);
      await _setRepository.markSetAsUnsynced(set.id!);
      reloadSets();
    }
  }

  void _deleteSet(VocabSet set) async {
    bool deleteCloud = false;
    bool confirmed = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text("Delete Set?"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("This will permanently delete this set and its cards."),
                    if (set.cloudId != null && set.role == 'owner') ...[
                      const SizedBox(height: 20),
                      CheckboxListTile(
                        title: const Text("Delete from Cloud too"),
                        subtitle: const Text("Removes it for everyone"),
                        value: deleteCloud,
                        activeColor: Colors.red,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => deleteCloud = val ?? false),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () {
                      confirmed = true;
                      Navigator.pop(ctx);
                    },
                    child: const Text("Delete"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed) {
      if (deleteCloud && set.cloudId != null) {
        await _setRepository.deleteSetFromCloud(set.cloudId!);
      }
      await _setRepository.deleteSet(set.id!);
      reloadSets();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(deleteCloud ? "Deleted locally and from cloud." : "Deleted locally.")),
        );
      }
    }
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
          Expanded(
            child: FutureBuilder<List<VocabSet>>(
              future: _setsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No StepSets yet. Create your first one!"));
                } else {
                  final sets = snapshot.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: sets.length,
                    itemBuilder: (ctx, i) => SetCard(
                      set: sets[i],
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SetDetailScreen(vocabSet: sets[i]),
                        ));
                        reloadSets();
                      },
                      onLongPress: () => _showSetOptionsDialog(sets[i]),
                      onUpload: () => _uploadSet(sets[i]),
                      onShare: () => _shareSetLink(sets[i]),
                      onVisibilityChanged: (newVisibility) => _onVisibilityChanged(sets[i], newVisibility),
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
