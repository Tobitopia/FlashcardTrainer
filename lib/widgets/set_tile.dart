import 'package:flutter/material.dart';
import '../models/vocab_set.dart';

class SetCard extends StatelessWidget {
  final VocabSet set;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUpload;
  final VoidCallback? onShare; // New: Optional callback for sharing

  const SetCard({
    super.key,
    required this.set,
    required this.onTap,
    required this.onLongPress,
    required this.onUpload,
    this.onShare, // Make it an optional parameter
  });

  @override
  Widget build(BuildContext context) {
    Widget actionButton;

    if (set.cloudId == null) {
      // Not uploaded yet
      actionButton = IconButton(
        icon: const Icon(Icons.cloud_upload, color: Colors.blueAccent),
        onPressed: onUpload,
        tooltip: 'Upload to Cloud',
      );
    } else if (!set.isSynced) {
      // Uploaded, but needs update
      actionButton = IconButton(
        icon: const Icon(Icons.sync, color: Colors.orange),
        onPressed: onUpload, // This will trigger the update logic in SetsScreen
        tooltip: 'Update Cloud Set',
      );
    } else {
      // Uploaded and synced (show share icon)
      actionButton = IconButton(
        icon: const Icon(Icons.share, color: Colors.green),
        onPressed: onShare, // This will trigger the share link logic in SetsScreen
        tooltip: 'Share Cloud Set',
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Text(
                      set.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text("${set.cards.length} cards"),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: actionButton,
            ),
          ],
        ),
      ),
    );
  }
}
