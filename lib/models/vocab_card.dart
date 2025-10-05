class VocabCard {
  int? id;
  String title;
  String description;
  String? mediaPath;
  List<String> labels;
  int rating;
  DateTime? lastTrained;
  int? setId; // The ID of the set this card belongs to

  VocabCard({
    this.id,
    required this.title,
    required this.description,
    this.mediaPath,
    this.labels = const [],
    this.rating = 0,
    this.lastTrained,
    this.setId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaPath': mediaPath,
      'rating': rating,
      'lastTrained': lastTrained?.millisecondsSinceEpoch,
      'setId': setId,
    };
  }

  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      mediaPath: map['mediaPath'],
      rating: map['rating'],
      lastTrained: map['lastTrained'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTrained'])
          : null,
      setId: map['setId'],
    );
  }
}
