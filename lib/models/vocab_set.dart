import 'vocab_card.dart';
import 'visibility.dart';

class VocabSet {
  int? id;
  String name;
  List<VocabCard> cards;
  String? cloudId; // New: To store the ID from Firestore
  bool isSynced; // New: To track if local changes need to be uploaded
  Visibility visibility; // New: To control sharing settings

  VocabSet({
    this.id,
    required this.name,
    List<VocabCard>? cards,
    this.cloudId,
    this.isSynced = true, // Default to true for new or synced sets
    this.visibility = Visibility.private,
  }) : cards = cards ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cloudId': cloudId,
      'isSynced': isSynced ? 1 : 0, // SQLite doesn't have a boolean type
      'visibility': visibility.index,
    };
  }

  factory VocabSet.fromMap(Map<String, dynamic> map) {
    return VocabSet(
      id: map['id'],
      name: map['name'],
      cloudId: map['cloudId'],
      isSynced: map['isSynced'] == 1,
      visibility: Visibility.values[map['visibility'] ?? 0],
    );
  }

  void addCard(VocabCard card) {
    cards.add(card);
  }
}
