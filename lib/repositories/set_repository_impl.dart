import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:projects/services/cloud_service.dart';

import '../models/vocab_card.dart';
import '../models/vocab_set.dart';
import '../services/database_service.dart';
import 'card_repository.dart';
import 'set_repository.dart';

class SetRepositoryImpl implements ISetRepository {
  final DatabaseService _databaseService;
  final ICardRepository _cardRepository;
  final CloudService _cloudService; 

  SetRepositoryImpl(this._databaseService, this._cardRepository, this._cloudService);

  @override
  Future<int> insertSet(VocabSet set) async {
    final db = await _databaseService.database;
    return await db.insert('sets', set.toMap());
  }

  @override
  Future<void> importSet(VocabSet set) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      int newSetId = await txn.insert('sets', {
        'name': set.name, 
        'cloudId': set.cloudId, 
        'isSynced': 1,
        'visibility': set.visibility.index,
        'role': set.role,
        'isProgression': set.isProgression ? 1 : 0,
      });

      for (VocabCard card in set.cards) {
        String? localPath;
        if (card.remoteUrl != null) {
          localPath = await _downloadAndSaveMedia(card.remoteUrl!);
        }

        final cardMap = card.toMap();
        cardMap['setId'] = newSetId;
        cardMap['mediaPath'] = localPath; 

        await txn.insert('cards', cardMap);
      }
    });
  }

  @override
  Future<void> syncSetWithCloud(VocabSet cloudSet) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> sets = await db.query(
      'sets', 
      where: 'cloudId = ?', 
      whereArgs: [cloudSet.cloudId]
    );
    
    if (sets.isEmpty) return;
    
    final localSetId = sets.first['id'] as int;
    
    await db.transaction((txn) async {
      await txn.update(
        'sets', 
        {
          'name': cloudSet.name,
          'visibility': cloudSet.visibility.index,
          'isSynced': 1,
          'role': cloudSet.role,
          'isProgression': cloudSet.isProgression ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [localSetId]
      );
      
      await txn.delete('cards', where: 'setId = ?', whereArgs: [localSetId]);
      
      for (VocabCard card in cloudSet.cards) {
        String? localPath;
        if (card.remoteUrl != null) {
          localPath = await _downloadAndSaveMedia(card.remoteUrl!);
        }

        final cardMap = card.toMap();
        cardMap['setId'] = localSetId;
        cardMap['mediaPath'] = localPath; 
        
        await txn.insert('cards', cardMap);
      }
    });
  }

  @override
  Future<String?> pushSetToCloud(VocabSet set) async {
    final cards = await _cardRepository.getCardsForSet(set.id!);
    final fullSet = VocabSet(
      id: set.id,
      name: set.name,
      cards: cards,
      cloudId: set.cloudId,
      visibility: set.visibility,
      isProgression: set.isProgression,
      role: set.role,
    );

    final String? newCloudId = await _cloudService.uploadOrUpdateVocabSet(fullSet, existingCloudId: set.cloudId);
    
    if (newCloudId != null) {
      await updateSetCloudStatus(set.id!, newCloudId, isSynced: true);
      
      // Update local cards with any new remoteUrls generated during upload
      for (var card in fullSet.cards) {
        if (card.id != null && card.remoteUrl != null) {
          // We can use the card repository to update just the remoteUrl
          // But since _cardRepository.updateCard updates everything, we should be careful.
          // Let's do a direct SQL update for efficiency and safety.
          final db = await _databaseService.database;
          await db.update(
            'cards',
            {'remoteUrl': card.remoteUrl},
            where: 'id = ?',
            whereArgs: [card.id],
          );
        }
      }
    }
    return newCloudId;
  }

  @override
  Future<bool> pullSetFromCloud(String cloudId) async {
    try {
      final cloudSet = await _cloudService.downloadVocabSet(cloudId);
      if (cloudSet != null) {
        await syncSetWithCloud(cloudSet);
        return true;
      }
      return false;
    } catch (e) {
      print("Error pulling set from cloud: $e");
      return false;
    }
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
  Future<int> updateSetProgression(int setId, bool isProgression) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      {'isProgression': isProgression ? 1 : 0},
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
  Future<int> markSetAsSynced(int setId) async {
    final db = await _databaseService.database;
    return await db.update(
      'sets',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  @override
  Future<int> deleteSet(int id) async {
    final db = await _databaseService.database;
    return await db.delete('sets', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> deleteSetFromCloud(String cloudId) async {
    return await _cloudService.deleteVocabSet(cloudId);
  }

  Future<String?> _downloadAndSaveMedia(String url) async {
    try {
      final uri = Uri.parse(url);
      final fileName = p.basename(uri.path); 
      
      final directory = await getApplicationDocumentsDirectory();
      final localPath = p.join(directory.path, fileName);
      final file = File(localPath);

      if (await file.exists()) {
        return localPath; 
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
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
