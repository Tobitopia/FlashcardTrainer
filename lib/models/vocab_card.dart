class VocabCard {
  String front;
  String back;
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