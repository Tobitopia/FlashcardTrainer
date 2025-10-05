import 'package:flutter/material.dart';
import '../models/vocab_card.dart';

class CardTile extends StatelessWidget {
  final VocabCard card;
  const CardTile({super.key, required this.card});

  Widget _buildStars(int rating) {
    return Row(
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.front, style: Theme.of(context).textTheme.titleMedium),
            Text(card.back, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: card.labels.map((l) => Chip(label: Text(l), visualDensity: VisualDensity.compact)).toList(),
            ),
            const Spacer(),
            _buildStars(card.rating),
          ],
        ),
      ),
    );
  }
}
