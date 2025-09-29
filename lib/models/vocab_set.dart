import 'vocab_card.dart';

class VocabSet{
  final String name;
  List<VocabCard> cards;

  // constructor
  VocabSet({
    required this.name,
    List<VocabCard>? cards,
  }): cards = cards ?? [];

  void addCard(VocabCard card){
    cards.add(card);
  }

}