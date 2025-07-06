class Comment {
  final String id;
  final String postId;
  final String motherId;
  final String fullName;
  final String content;
  final DateTime createdAt;
  final String? profileUrl;

  Comment({
    required this.id,
    required this.postId,
    required this.motherId,
    required this.fullName,
    required this.content,
    required this.createdAt,
    this.profileUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> map, String fullName) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      motherId: map['mother_id'] as String,
      fullName: fullName,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      profileUrl: map['mothers']['profile_url'] as String?,
    );
  }
}
