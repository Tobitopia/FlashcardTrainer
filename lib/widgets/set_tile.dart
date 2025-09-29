import 'package:flutter/material.dart';
import '../models/vocab_set.dart';

class SetCard extends StatelessWidget {
  final VocabSet set;
  final VoidCallback onTap;
  const SetCard({super.key, required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(set.name, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text("${set.cards.length} cards"),
            ],
          ),
        ),
      ),
    );
  }
}
