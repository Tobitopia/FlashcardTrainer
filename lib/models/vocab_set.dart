import 'vocab_card.dart';
import 'visibility.dart';

class VocabSet {
  int? id;
  String name;
  List<VocabCard> cards;
  String? cloudId; 
  bool isSynced; 
  Visibility visibility;
  String? role; // New: 'owner', 'editor', or 'viewer'

  VocabSet({
    this.id,
    required this.name,
    List<VocabCard>? cards,
    this.cloudId,
    this.isSynced = true,
    this.visibility = Visibility.private,
    this.role,
  }) : cards = cards ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cloudId': cloudId,
      'isSynced': isSynced ? 1 : 0, 
      'visibility': visibility.index,
      'role': role,
    };
  }

  factory VocabSet.fromMap(Map<String, dynamic> map) {
    return VocabSet(
      id: map['id'],
      name: map['name'],
      cloudId: map['cloudId'],
      isSynced: map['isSynced'] == 1,
      visibility: Visibility.values[map['visibility'] ?? 0],
      role: map['role'],
    );
  }

  void addCard(VocabCard card) {
    cards.add(card);
  }
}
