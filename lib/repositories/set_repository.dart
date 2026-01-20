import '../models/vocab_set.dart';

abstract class ISetRepository {
  Future<int> insertSet(VocabSet set);

  Future<void> importSet(VocabSet set);
  
  Future<void> syncSetWithCloud(VocabSet cloudSet);

  Future<String?> pushSetToCloud(VocabSet set);

  Future<bool> pullSetFromCloud(String cloudId);

  Future<List<VocabSet>> getAllSets();

  Future<int> updateSet(VocabSet set);

  Future<int> updateSetCloudStatus(int setId, String cloudId, {bool isSynced = true});

  Future<int> updateSetProgression(int setId, bool isProgression);

  Future<int> markSetAsUnsynced(int setId);

  Future<int> markSetAsSynced(int setId);

  Future<int> deleteSet(int id);

  Future<bool> deleteSetFromCloud(String cloudId); // New
}
