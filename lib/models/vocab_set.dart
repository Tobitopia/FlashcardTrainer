import 'vocab_card.dart';

class VocabSet{
  int? id;
  final String name;
  List<VocabCard> cards;

  // constructor
  VocabSet({
    this.id,
    required this.name,
    List<VocabCard>? cards,
  }): cards = cards ?? [];

  Map<String, Object?> toMap() {
    return {'name': name};
  }

  factory VocabSet.fromMap(Map<String, dynamic> map) {
    return VocabSet(id: map['id'], name: map['name']);
  }


  void addCard(VocabCard card){
    cards.add(card);
  }

}