class Note {
  int? id;
  String title;
  String content;
  String createdAt;
  String updatedAt;
  bool isPinned;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      isPinned: map['isPinned'] == 1,
    );
  }
}