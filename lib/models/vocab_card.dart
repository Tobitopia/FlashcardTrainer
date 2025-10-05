class VocabCard {
  int? id;
  String front;
  String back;
  List<String> labels;
  int rating;

  VocabCard({
    this.id,
    required this.front,
    required this.back,
    this.labels = const [],
    this.rating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'rating': rating,
    };
  }

  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(
      id: map['id'],
      front: map['front'],
      back: map['back'],
      rating: map['rating'],
    );
  }
}
