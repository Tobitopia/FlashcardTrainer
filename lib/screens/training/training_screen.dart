import 'dart:math';
import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';

class TrainingScreen extends StatefulWidget {
  final List<VocabCard> cards;

  const TrainingScreen({super.key, required this.cards});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  late List<VocabCard> _trainingDeck;

  @override
  void initState() {
    super.initState();
    _trainingDeck = _createTrainingDeck(widget.cards);
  }

  List<VocabCard> _createTrainingDeck(List<VocabCard> cards) {
    final random = Random();
    cards.sort((a, b) {
      // Prioritize lower ratings
      int ratingCompare = a.rating.compareTo(b.rating);
      if (ratingCompare != 0) {
        return ratingCompare;
      }

      // Prioritize cards that haven't been trained recently
      DateTime now = DateTime.now();
      DateTime lastTrainedA = a.lastTrained ?? now.subtract(const Duration(days: 365));
      DateTime lastTrainedB = b.lastTrained ?? now.subtract(const Duration(days: 365));
      int timeCompare = lastTrainedA.compareTo(lastTrainedB);
      if (timeCompare != 0) {
        return timeCompare;
      }

      // Finally, add some randomness
      return random.nextInt(3) - 1; // -1, 0, or 1
    });
    return cards;
  }

  void _showNextCard() {
    setState(() {
      _showAnswer = false;
      if (_currentIndex < _trainingDeck.length - 1) {
        _currentIndex++;
      } else {
        // Optionally, loop or end the session
        _currentIndex = 0; // Simple loop for now
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You've completed the deck! Starting over.")),
        );
      }
    });
  }

  void _updateCardRating(int rating) async {
    final card = _trainingDeck[_currentIndex];
    card.rating = rating;
    card.lastTrained = DateTime.now();
    await DatabaseHelper.instance.updateCard(card);
    _showNextCard();
  }

  @override
  Widget build(BuildContext context) {
    if (_trainingDeck.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Training')),
        body: const Center(child: Text("No cards to train!")),
      );
    }

    final currentCard = _trainingDeck[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              currentCard.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_showAnswer)
              Column(
                children: [
                  Text(
                    currentCard.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Text("How did you do?"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      return IconButton(
                        icon: Icon(
                          rating <= currentCard.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => _updateCardRating(rating),
                      );
                    }),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => setState(() => _showAnswer = true),
                child: const Text('Show Answer'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNextCard,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
