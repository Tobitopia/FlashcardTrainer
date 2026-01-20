class VocabCard {
  int? id;
  String title;
  String? description;
  String? mediaPath; // Local path on device
  String? remoteUrl; // Firebase Storage URL
  List<String> labels;
  int rating;
  DateTime? lastTrained;
  DateTime? createdAt; 
  int? setId; 

  VocabCard({
    this.id,
    required this.title,
    this.description,
    this.mediaPath,
    this.remoteUrl,
    this.labels = const [],
    this.rating = 0,
    this.lastTrained,
    this.createdAt,
    this.setId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaPath': mediaPath,
      'remoteUrl': remoteUrl,
      'rating': rating,
      'lastTrained': lastTrained?.millisecondsSinceEpoch,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      'setId': setId,
    };
  }

  factory VocabCard.fromMap(Map<String, dynamic> map) {
    return VocabCard(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      mediaPath: map['mediaPath'],
      remoteUrl: map['remoteUrl'],
      rating: map['rating'],
      lastTrained: map['lastTrained'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTrained'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      setId: map['setId'],
    );
  }
}
