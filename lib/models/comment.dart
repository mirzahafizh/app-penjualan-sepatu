class Comment {
  final int id;
  final String text;
  final String userName;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.userName,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      text: json['comment_text'],
      userName: json['user']['name'], // Adjust according to your API response
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
