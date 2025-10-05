import 'vocab_card.dart';

class VocabSet {
  int? id;
  String name;
  List<VocabCard> cards;

  VocabSet({
    this.id,
    required this.name,
    List<VocabCard>? cards,
  }) : cards = cards ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory VocabSet.fromMap(Map<String, dynamic> map) {
    return VocabSet(
      id: map['id'],
      name: map['name'],
    );
  }

  void addCard(VocabCard card) {
    cards.add(card);
  }
}
