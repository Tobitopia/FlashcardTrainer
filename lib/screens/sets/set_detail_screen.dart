import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projects/app/locator.dart';
import 'package:projects/models/vocab_card.dart';
import 'package:projects/models/vocab_set.dart';
import 'package:projects/repositories/card_repository.dart';
import 'package:projects/repositories/set_repository.dart';
import 'package:projects/screens/training/training_screen.dart';
import 'package:projects/widgets/add_edit_card_dialog.dart';
import 'package:projects/widgets/card_tile.dart';
import 'package:projects/screens/media/video_player_screen.dart';
import 'package:projects/services/cloud_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class SetDetailScreen extends StatefulWidget {
  final VocabSet vocabSet;
  const SetDetailScreen({super.key, required this.vocabSet});

  @override
  State<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends State<SetDetailScreen> {
  late Future<List<VocabCard>> _cardsFuture;
  final ICardRepository _cardRepository = locator<ICardRepository>();
  final ISetRepository _setRepository = locator<ISetRepository>();
  final CloudService _cloudService = locator<CloudService>();

  final _searchController = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  final Set<String> _selectedLabels = {};
  List<VocabCard> _filteredCards = [];
  bool _isSyncing = false;
  late bool _isProgression;

  @override
  void initState() {
    super.initState();
    _isProgression = widget.vocabSet.isProgression;
    _loadCards();
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCards() {
    setState(() {
      _cardsFuture = _cardRepository.getCardsForSet(widget.vocabSet.id!);
    });
  }

  void _toggleProgression() async {
    setState(() {
      _isProgression = !_isProgression;
      widget.vocabSet.isProgression = _isProgression;
    });
    // Use the specific update method to avoid overwriting isSynced
    await _setRepository.updateSetProgression(widget.vocabSet.id!, _isProgression);
  }

  Future<void> _pullFromCloud() async {
    if (widget.vocabSet.cloudId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sync from Cloud?"),
        content: const Text("This will overwrite all local cards with the version from the cloud. Your local unsynced cards will be lost."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sync Now")),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSyncing = true);
    try {
      final cloudSet = await _cloudService.downloadVocabSet(widget.vocabSet.cloudId!);
      if (cloudSet != null) {
        await _setRepository.syncSetWithCloud(cloudSet);
        
        // Update local widget state to reflect sync
        setState(() {
           _isProgression = cloudSet.isProgression;
           widget.vocabSet.isProgression = _isProgression;
           widget.vocabSet.isSynced = true; // Crucial update
        });
        
        _loadCards();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pulled latest from cloud!")));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _pushToCloud() async {
    setState(() => _isSyncing = true);
    try {
      final cards = await _cardRepository.getCardsForSet(widget.vocabSet.id!);
      final fullSet = VocabSet(
        id: widget.vocabSet.id,
        name: widget.vocabSet.name,
        cards: cards,
        cloudId: widget.vocabSet.cloudId,
        visibility: widget.vocabSet.visibility,
        isProgression: _isProgression,
        role: widget.vocabSet.role,
      );

      final newCloudId = await _setRepository.pushSetToCloud(fullSet);
      if (newCloudId != null) {
        setState(() {
          widget.vocabSet.isSynced = true; // Crucial update
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pushed changes to cloud!")));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _addOrEditCard([VocabCard? card]) async {
    final result = await showDialog<VocabCard>(
      context: context,
      builder: (ctx) => AddEditCardDialog(card: card, vocabSet: widget.vocabSet),
    );

    if (result != null) {
      if (card != null) {
        await _cardRepository.updateCard(result);
      } else {
        await _cardRepository.insertCard(result, widget.vocabSet.id!);
      }
      if (widget.vocabSet.cloudId != null) {
        await _setRepository.markSetAsUnsynced(widget.vocabSet.id!);
        setState(() => widget.vocabSet.isSynced = false);
      }
      _loadCards();
    }
  }

  void _viewCard(VocabCard card) {
    if (card.mediaPath != null && card.mediaPath!.endsWith('.mp4')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: card.mediaPath!, title: card.title)));
    } else {
      showDialog(
        context: context,
        builder: (ctx) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            title: Text(card.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card.mediaPath != null && File(card.mediaPath!).existsSync()) 
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(card.mediaPath!))),
                  const SizedBox(height: 12),
                  Text(card.description ?? '', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
          ),
        ),
      );
    }
  }

  void _showOptionsDialog(VocabCard card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card.title),
        content: const Text("What would you like to do?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _addOrEditCard(card); }, child: const Text("Edit")),
          TextButton(onPressed: () { Navigator.pop(ctx); _deleteCard(card.id!); }, child: const Text("Delete")),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _deleteCard(int cardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Card?"),
        content: const Text("Are you sure you want to permanently delete this card?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed == true) {
      await _cardRepository.deleteCard(cardId);
      if (widget.vocabSet.cloudId != null) {
        await _setRepository.markSetAsUnsynced(widget.vocabSet.id!);
        setState(() => widget.vocabSet.isSynced = false);
      }
      _loadCards();
    }
  }

  Future<String?> _getThumbnail(String videoPath) async {
    final fileName = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 100, // smaller thumbnail for timeline
      quality: 75,
    );
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    final bool isViewer = widget.vocabSet.role == 'viewer';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.vocabSet.name),
            if (isViewer) const Text("VIEW ONLY", style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isProgression ? Icons.grid_view_rounded : Icons.timeline_rounded),
            onPressed: _toggleProgression,
            tooltip: _isProgression ? 'Switch to Grid' : 'Switch to Timeline',
          ),
          if (widget.vocabSet.cloudId != null) ...[
            if (_isSyncing)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else ...[
              IconButton(icon: const Icon(Icons.cloud_download_outlined), onPressed: _pullFromCloud, tooltip: 'Pull from Cloud'),
              if (!isViewer) IconButton(icon: const Icon(Icons.cloud_upload_outlined), onPressed: _pushToCloud, tooltip: 'Push to Cloud'),
            ],
          ]
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDF7FF), Color(0xFFFFF0F5)],
          ),
        ),
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildCardsList()),
          ],
        ),
      ),
      floatingActionButton: isViewer ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'train_set_fab',
            onPressed: () {
              if (_filteredCards.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingScreen(cards: _filteredCards))).then((_) => _loadCards());
            },
            child: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_card_fab',
            onPressed: () => _addOrEditCard(), 
            child: const Icon(Icons.add)
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white.withOpacity(0.5),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF8146BD)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Expanded(
                      child: Slider(
                        value: _minRating,
                        onChanged: (v) => setState(() => _minRating = v),
                        min: 0, max: 5, divisions: 5,
                        activeColor: const Color(0xFF8146BD),
                      ),
                    ),
                    Text('${_minRating.round()}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardsList() {
    return FutureBuilder<List<VocabCard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final allCards = snapshot.data!;
        _filteredCards = allCards.where((c) {
          final q = _searchQuery.toLowerCase();
          return (q.isEmpty || c.title.toLowerCase().contains(q)) && (_minRating == 0 || c.rating == _minRating.round());
        }).toList();

        if (_filteredCards.isEmpty) return const Center(child: Text("Empty here..."));

        if (_isProgression) {
          return _buildTimelineView(_filteredCards);
        } else {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: _filteredCards.length,
            itemBuilder: (ctx, i) => InkWell(
              onTap: () => _viewCard(_filteredCards[i]), 
              onLongPress: widget.vocabSet.role == 'viewer' ? null : () => _showOptionsDialog(_filteredCards[i]),
              child: CardTile(card: _filteredCards[i])
            ),
          );
        }
      },
    );
  }

  Widget _buildTimelineView(List<VocabCard> cards) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (ctx, i) {
        final card = cards[i];
        final dateStr = DateFormat('MMM dd, yyyy').format(card.createdAt ?? DateTime.now());
        
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(width: 2, color: const Color(0xFF8146BD).withOpacity(0.3), child: const SizedBox(height: 20)),
                  Container(
                    width: 12, height: 12,
                    decoration: const BoxDecoration(color: Color(0xFF8146BD), shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(width: 2, color: const Color(0xFF8146BD).withOpacity(0.3))),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () => _viewCard(card),
                    onLongPress: widget.vocabSet.role == 'viewer' ? null : () => _showOptionsDialog(card),
                    borderRadius: BorderRadius.circular(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.white.withOpacity(0.6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Media Preview
                              if (card.mediaPath != null && File(card.mediaPath!).existsSync())
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.black12,
                                  child: card.mediaPath!.endsWith('.mp4')
                                    ? FutureBuilder<String?>(
                                        future: _getThumbnail(card.mediaPath!),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data != null) {
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.file(File(snapshot.data!), fit: BoxFit.cover),
                                                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40)),
                                              ],
                                            );
                                          }
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                        },
                                      )
                                    : Image.file(File(card.mediaPath!), fit: BoxFit.cover),
                                ),
                              
                              // Text Content
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    if (card.description?.isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Text(card.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: List.generate(5, (idx) => Icon(Icons.star, size: 14, color: idx < card.rating ? Colors.amber : Colors.grey[300])),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
