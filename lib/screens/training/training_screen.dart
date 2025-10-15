import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:projects/helpers/database_helpers.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _trainingDeck = _createTrainingDeck(widget.cards);
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  List<VocabCard> _createTrainingDeck(List<VocabCard> cards) {
    final random = Random();
    cards.sort((a, b) {
      int ratingCompare = a.rating.compareTo(b.rating);
      if (ratingCompare != 0) return ratingCompare;

      DateTime now = DateTime.now();
      DateTime lastTrainedA = a.lastTrained ?? now.subtract(const Duration(days: 365));
      DateTime lastTrainedB = b.lastTrained ?? now.subtract(const Duration(days: 365));
      int timeCompare = lastTrainedA.compareTo(lastTrainedB);
      if (timeCompare != 0) return timeCompare;

      return random.nextInt(3) - 1;
    });
    return cards;
  }

  void _initializeVideoPlayer() {
    _videoController?.dispose();
    final card = _trainingDeck.isNotEmpty ? _trainingDeck[_currentIndex] : null;
    if (card != null && card.mediaPath != null && card.mediaPath!.endsWith('.mp4')) {
      _videoController = VideoPlayerController.file(File(card.mediaPath!))
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized
          setState(() {});
        });
    } else {
      _videoController = null;
    }
  }

  void _showNextCard() {
    setState(() {
      _showAnswer = false;
      
      if (_currentIndex < _trainingDeck.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You've completed the deck! Starting over.")),
        );
      }
      _initializeVideoPlayer();
    });
  }

  void _updateCardRating(int rating) async {
    final card = _trainingDeck[_currentIndex];
    setState(() {
      card.rating = rating;
    });
    card.lastTrained = DateTime.now();
    await DatabaseHelper.instance.updateCard(card);

    await Future.delayed(const Duration(milliseconds: 400));

    _showNextCard();
  }

  Widget _buildMediaWidget(VocabCard card) {
    if (card.mediaPath == null) return const SizedBox.shrink();

    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        },
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (!_videoController!.value.isPlaying)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 70),
                ),
            ],
          ),
        ),
      );
    } else if (File(card.mediaPath!).existsSync()) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Image.file(File(card.mediaPath!)),
      );
    }
    return const Center(child: CircularProgressIndicator());
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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_showAnswer)
                  Column(
                    children: [
                      Text(
                        currentCard.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentCard.description ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                if (_showAnswer)
                  Column(
                    children: [
                      _buildMediaWidget(currentCard),
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNextCard,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
