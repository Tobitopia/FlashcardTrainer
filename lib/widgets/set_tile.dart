import 'package:flutter/material.dart';
import '../models/vocab_set.dart';

class SetCard extends StatelessWidget {
  final VocabSet set;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUpload; // New callback for the upload button

  const SetCard({
    super.key,
    required this.set,
    required this.onTap,
    required this.onLongPress,
    required this.onUpload, // Make it a required parameter
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.all(8),
        child: Stack( // Use a Stack to layer the button on top
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Constrain the text width to prevent it from overlapping the button
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
            // Position the button in the top-right corner
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent),
                onPressed: onUpload, // Hook up the new callback
                tooltip: 'Upload to Cloud',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
