import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:video_player/video_player.dart';

class TrainingScreen extends StatefulWidget {
  final List<VocabCard> cards;

  const TrainingScreen({super.key, required this.cards});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  int _currentIndex = 0;
  late List<VocabCard> _trainingDeck;
  VideoPlayerController? _videoController;
  double _currentPlaybackSpeed = 1.0;

  final ICardRepository _cardRepository = locator<ICardRepository>();

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
          setState(() {});
        });
      _videoController!.addListener(() {
        setState(() {});
      });
      _videoController!.setLooping(true);
      _videoController!.setPlaybackSpeed(_currentPlaybackSpeed);
    } else {
      _videoController = null;
    }
  }

  void _showNextCard() {
    setState(() {
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
    await _cardRepository.updateCard(card);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  Widget _buildMediaWidget(VocabCard card) {
    if (card.mediaPath == null) return const SizedBox.shrink();
    final isVideo = card.mediaPath!.toLowerCase().endsWith('.mp4');

    if (isVideo) {
      if (_videoController != null && _videoController!.value.isInitialized) {
        return Column(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoController!),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                    child: Center(
                      child: _videoController!.value.isPlaying
                          ? const SizedBox.shrink()
                          : Container(
                              color: Colors.black.withOpacity(0.5),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 70),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_videoController!.value.position),
                        style: const TextStyle(color: Colors.white),
                      ),
                      PopupMenuButton<double>(
                        initialValue: _currentPlaybackSpeed,
                        onSelected: (speed) {
                          setState(() {
                            _currentPlaybackSpeed = speed;
                            _videoController!.setPlaybackSpeed(speed);
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 0.25, child: Text("0.25x")),
                          const PopupMenuItem(value: 0.5, child: Text("0.5x")),
                          const PopupMenuItem(value: 1.0, child: Text("1.0x")),
                          const PopupMenuItem(value: 1.5, child: Text("1.5x")),
                          const PopupMenuItem(value: 2.0, child: Text("2.0x")),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${_currentPlaybackSpeed}x',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                          });
                        },
                      ),
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      // It's an image
      return Image.file(
        File(card.mediaPath!),
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // This will show a generic error icon if the image fails to load
          // for any reason other than the initial loading flicker.
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
          );
        },
      );
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Added bottom padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Title and Description --
            Text(
              currentCard.title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (currentCard.description != null && currentCard.description!.isNotEmpty)
              Text(
                currentCard.description!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),

            // -- Rating Controls --
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return IconButton(
                  icon: Icon(
                    rating <= currentCard.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => _updateCardRating(rating),
                );
              }),
            ),
            const SizedBox(height: 32),
            
            // -- Media Widget --
            _buildMediaWidget(currentCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNextCard,
        tooltip: 'Next Card',
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
