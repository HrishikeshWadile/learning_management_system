class VideoAndNotesModel {
  String title;
  String description;
  String type;
  String? youtubeLink;
  String? fileUrl;
  DateTime timestamp;

  VideoAndNotesModel({
    required this.title,
    required this.description,
    required this.type,
    this.youtubeLink,
    this.fileUrl,
    required this.timestamp,
  });

  factory VideoAndNotesModel.fromMap(Map<String, dynamic> map) {
    return VideoAndNotesModel(
      title: map['title'],
      description: map['description'],
      type: map['type'],
      youtubeLink: map['youtube_link'],
      fileUrl: map['file_url'],
      timestamp: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'youtube_link': youtubeLink,
      'file_url': fileUrl,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
