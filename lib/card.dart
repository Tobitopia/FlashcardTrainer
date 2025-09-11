import 'package:flutter/material.dart';

class VocabCard {
  final String front;
  final String back;
  final List<String> labels;
  int rating;

  // constructor
  VocabCard({
    required this.front,
    required this.back,
    this.labels = const [],
    this.rating = 0,
  });

  void updateRating(int newRating){
    rating = newRating;
  }
}

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

void testVocabs() {
  // create a Vocab set
  var mySet = VocabSet(name: 'GermanEnglish');

  // create two cards
  var card1 = VocabCard(front: 'Haus', back: 'House');
  var card2 = VocabCard(front: 'Hund', back: 'Dog');

  // add cards to set
  mySet.addCard(card1);
  mySet.addCard(card2);

  // print cards
  print('Name of Set: ${mySet.name}');
  for (var card in mySet.cards){
    print('Front: ${card.front}, Back: ${card.back}');

    //change rating
    card.updateRating(5);
  }
  // print rating of first card
  print(mySet.cards.first.rating);
}