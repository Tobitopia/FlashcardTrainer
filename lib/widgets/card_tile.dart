import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CardTile extends StatefulWidget {
  final VocabCard card;
  const CardTile({super.key, required this.card});

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  Uint8List? _thumbnailBytes;
  bool _isLoadingThumbnail = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(covariant CardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.mediaPath != oldWidget.card.mediaPath) {
      // If the card's media has changed, we need to regenerate the thumbnail
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    // Reset state before generating a new thumbnail
    if (mounted) {
      setState(() {
        _isLoadingThumbnail = true;
        _thumbnailBytes = null;
      });
    }

    if (widget.card.mediaPath != null && widget.card.mediaPath!.endsWith('.mp4')) {
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: widget.card.mediaPath!,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );
      if (mounted) {
        setState(() {
          _thumbnailBytes = thumbnailBytes;
          _isLoadingThumbnail = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _buildMediaPreview(),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.card.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(widget.card.description ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (widget.card.labels.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 0,
                        children: widget.card.labels.map((l) => Chip(label: Text(l), visualDensity: VisualDensity.compact)).toList(),
                      ),
                    const SizedBox(height: 8),
                    _buildStars(widget.card.rating),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final path = widget.card.mediaPath;
    if (path != null && path.isNotEmpty) {
      if (path.endsWith('.mp4')) {
        if (_isLoadingThumbnail) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_thumbnailBytes != null) {
          return Image.memory(_thumbnailBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        }
      } else {
        // This handles image files
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        }
      }
    }
    // Placeholder for no media or if the file doesn't exist
    return Container(
      color: Colors.grey[300],
      child: Center(child: Icon(Icons.photo_size_select_actual_outlined, color: Colors.grey[500])),
    );
  }
}
