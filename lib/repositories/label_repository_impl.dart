import 'package:sqflite/sqflite.dart';

import '../services/database_service.dart';
import 'label_repository.dart';

class LabelRepositoryImpl implements ILabelRepository {
  final DatabaseService _databaseService;

  LabelRepositoryImpl(this._databaseService);

  @override
  Future<List<String>> getAllLabels() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> labelMaps = await db.query(
      'labels',
      columns: ['name'],
      distinct: true,
      orderBy: 'name',
    );

    if (labelMaps.isEmpty) {
      return [];
    }

    return labelMaps.map((map) => map['name'] as String).toList();
  }
}
