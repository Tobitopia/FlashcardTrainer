import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/vocab_card.dart';
import '../models/vocab_set.dart';
import '../services/database_service.dart';
import 'card_repository.dart';
import 'set_repository.dart';

class SetRepositoryImpl implements ISetRepository {
  final DatabaseService _databaseService;
  final ICardRepository _cardRepository;

  SetRepositoryImpl(this._databaseService, this._cardRepository);

  @override
  Future<int> insertSet(VocabSet set) async {
    final db = await _databaseService.database;
    return await db.insert('sets', set.toMap());
  }

  @override
  Future<void> importSet(VocabSet set) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      int newSetId = await txn.insert('sets', {'name': set.name, 'cloudId': set.cloudId, 'isSynced': 1});

      for (VocabCard card in set.cards) {
        if (card.mediaPath != null && card.mediaPath!.startsWith('http')) {
          final localPath = await _downloadAndSaveMedia(card.mediaPath!);
          card.mediaPath = localPath;
        }

        final cardMap = card.toMap();
        cardMap['setId'] = newSetId;

        await txn.insert('cards', cardMap);
      }
    });
  }

  @override
  Future<List<VocabSet>> getAllSets() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> setMaps = await db.query('sets', orderBy: 'name');

    if (setMaps.isEmpty) {
      return [];
    }

    List<VocabSet> sets = setMaps.map((map) => VocabSet.fromMap(map)).toList();

    for (var set in sets) {
      set.cards = await _cardRepository.getCardsForSet(set.id!);
    }

    return sets;
  }

  @override
  Future<int> updateSet(VocabSet set) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      set.toMap(),
      where: 'id = ?',
      whereArgs: [set.id],
    );
  }

  @override
  Future<int> updateSetCloudStatus(int setId, String cloudId, {bool isSynced = true}) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      {'cloudId': cloudId, 'isSynced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  @override
  Future<int> markSetAsUnsynced(int setId) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      {'isSynced': 0},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  @override
  Future<int> deleteSet(int id) async {
    final db = await _databaseService.database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  // TODO: This should be extracted to a separate MediaService
  Future<String?> _downloadAndSaveMedia(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(url).split('?').first; // Get original filename
        final localPath = p.join(directory.path, fileName);
        final file = File(localPath);
        await file.writeAsBytes(response.bodyBytes);
        return localPath;
      }
      return null;
    } catch (e) {
      print("Error downloading media: $e");
      return null;
    }
  }
}
