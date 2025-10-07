import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/screens/sets/set_detail_screen.dart';
import '../../widgets/set_tile.dart';

class SetsScreen extends StatefulWidget {
  const SetsScreen({super.key});

  @override
  SetsScreenState createState() => SetsScreenState();
}

class SetsScreenState extends State<SetsScreen> {
  late Future<List<VocabSet>> _setsFuture;
  final dbHelper = DatabaseHelper.instance;

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
    return FutureBuilder<List<VocabSet>>(
      future: _setsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: \${snapshot.error}"));
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
                reloadSets(); // Use reloadSets to refresh
              },
              onLongPress: () => _showSetOptionsDialog(s), // Changed to show options
            )).toList(),
          );
        }
      },
    );
  }
}
