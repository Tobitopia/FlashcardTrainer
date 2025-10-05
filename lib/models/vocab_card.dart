class VocabCard {
  int? id;
  String title;
  String description;
  String? mediaPath;
  List<String> labels;
  int rating;
  int? setId; // The ID of the set this card belongs to

  VocabCard({
    this.id,
    required this.title,
    required this.description,
    this.mediaPath,
    this.labels = const [],
    this.rating = 0,
    this.setId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaPath': mediaPath,
      'rating': rating,
      'setId': setId, // Add setId to the map
    };
  }

  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      mediaPath: map['mediaPath'],
      rating: map['rating'],
      setId: map['setId'], // Get setId from the map
    );
  }
}
