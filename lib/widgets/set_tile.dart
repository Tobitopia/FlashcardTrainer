import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projects/models/visibility.dart' as model;
import '../models/vocab_set.dart';

class SetCard extends StatelessWidget {
  final VocabSet set;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onUpload;
  final VoidCallback? onShare;
  final ValueChanged<model.Visibility>? onVisibilityChanged;

  const SetCard({
    super.key,
    required this.set,
    required this.onTap,
    required this.onLongPress,
    required this.onUpload,
    this.onShare,
    this.onVisibilityChanged,
  });

  String _visibilityToString(model.Visibility visibility) {
    switch (visibility) {
      case model.Visibility.private: return 'Private';
      case model.Visibility.publicView: return 'View Link';
      case model.Visibility.publicCooperate: return 'Edit Link';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSynced = set.isSynced;
    final bool hasCloud = set.cloudId != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8146BD).withOpacity(0.05),
                  blurRadius: 10, offset: const Offset(0, 5),
                )
              ],
            ),
            child: Stack(
              children: [
                // Background Pattern (Subtle icon, purely decorative)
                Positioned(
                  bottom: -20, right: -20,
                  child: Icon(
                    Icons.style_rounded,
                    size: 100, color: const Color(0xFF8146BD).withOpacity(0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              set.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A148C)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusIcon(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${set.cards.length} StepCards",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (hasCloud)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<model.Visibility>(
                            value: set.visibility,
                            isDense: true,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8146BD), fontWeight: FontWeight.bold),
                            icon: const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF8146BD)),
                            items: model.Visibility.values.map((v) => DropdownMenuItem(value: v, child: Text(_visibilityToString(v)))).toList(),
                            onChanged: (val) => val != null ? onVisibilityChanged?.call(val) : null,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isSynced || !hasCloud)
                  Positioned(
                    bottom: 8, right: 8,
                    child: FloatingActionButton.small(
                      onPressed: onUpload,
                      elevation: 2,
                      backgroundColor: isSynced ? const Color(0xFF8146BD) : Colors.orangeAccent,
                      child: Icon(hasCloud ? Icons.sync : Icons.cloud_upload_rounded, size: 18),
                    ),
                  )
                else if (set.visibility != model.Visibility.private)
                  Positioned(
                    bottom: 8, right: 8,
                    child: FloatingActionButton.small(
                      onPressed: onShare,
                      elevation: 2,
                      backgroundColor: const Color(0xFFE0436B),
                      child: const Icon(Icons.share_rounded, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (set.cloudId == null) return const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.grey);
    if (!set.isSynced) return const Icon(Icons.error_outline_rounded, size: 16, color: Colors.orange);
    return const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green);
  }
}
