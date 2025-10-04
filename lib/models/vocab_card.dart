class VocabCard {
  int? id;
  String front;
  String back;
  final List<String> labels; // Now active
  int rating;

  // constructor
  VocabCard({    this.id,
    required this.front,
    required this.back,
    this.labels = const [], // Now active, defaults to an empty list
    this.rating = 0,
  });

  // The toMap() method does NOT change. We don't save the labels list directly.
  Map<String, dynamic> toMap() {
    return {'id': id, 'front': front, 'back': back, 'rating': rating};
  }

  // The fromMap() method creates a card, but the labels will be added later.
  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(id: map['id'], front: map['front'], back: map['back'], rating: map['rating']);
  }

  void updateRating(int newRating){
    rating = newRating;
  }
}
