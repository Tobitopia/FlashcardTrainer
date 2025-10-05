class VocabCard {
  int? id;
  String title;
  String description;
  String? mediaPath; // Path to the video or image file
  List<String> labels;
  int rating;

  VocabCard({
    this.id,
    required this.title,
    required this.description,
    this.mediaPath,
    this.labels = const [],
    this.rating = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaPath': mediaPath,
      'rating': rating,
    };
  }

  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      mediaPath: map['mediaPath'],
      rating: map['rating'],
    );
  }
}
