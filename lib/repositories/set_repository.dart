import '../models/vocab_set.dart';

abstract class ISetRepository {
  Future<int> insertSet(VocabSet set);

  Future<void> importSet(VocabSet set);

  Future<List<VocabSet>> getAllSets();

  Future<int> updateSet(VocabSet set);

  Future<int> updateSetCloudStatus(int setId, String cloudId, {bool isSynced = true});

  Future<int> markSetAsUnsynced(int setId);

  Future<int> deleteSet(int id);
}
