class Note {
  int? id;
  String title;
  String body;
  bool starred;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    this.id,
    required this.title,
    required this.body,
    this.starred = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'starred': starred ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Note fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as int?,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        starred: (m['starred'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
}