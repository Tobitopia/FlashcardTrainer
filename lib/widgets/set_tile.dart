import 'package:flutter/material.dart';
import 'package:projects/models/visibility.dart' as model;
import '../models/vocab_set.dart';

class SetCard extends StatelessWidget {
  final VocabSet set;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUpload;
  final VoidCallback? onShare; // New: Optional callback for sharing
  final ValueChanged<model.Visibility>? onVisibilityChanged;

  const SetCard({
    super.key,
    required this.set,
    required this.onTap,
    required this.onLongPress,
    required this.onUpload,
    this.onShare, // Make it an optional parameter
    this.onVisibilityChanged,
  });

  String _visibilityToString(model.Visibility visibility) {
    switch (visibility) {
      case model.Visibility.private:
        return 'Private';
      case model.Visibility.publicView:
        return 'Public (View)';
      case model.Visibility.publicCooperate:
        return 'Public (Edit)';
    }
  }

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
      // Uploaded and synced. Check visibility to decide on action button.
      if (set.visibility != model.Visibility.private) {
        // If public, show share button
        actionButton = IconButton(
          icon: const Icon(Icons.share, color: Colors.green),
          onPressed: onShare,
          tooltip: 'Share Cloud Set',
        );
      } else {
        // If private, show a lock icon instead of a share button.
        actionButton = const Padding(
          padding: EdgeInsets.all(8.0), // To align with IconButton's padding
          child: Icon(Icons.lock, color: Colors.grey),
        );
      }
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
                   if (set.cloudId != null)
                    DropdownButton<model.Visibility>(
                      value: set.visibility,
                      isExpanded: true,
                      items: model.Visibility.values.map((v) {
                        return DropdownMenuItem<model.Visibility>(
                          value: v,
                          child: Text(_visibilityToString(v),
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          onVisibilityChanged?.call(newValue);
                        }
                      },
                    ),
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
