class Post {
  final String id;
  final String motherId;
  final String fullName;
  final String title;
  final String content;
  final String? imageUrl;
  final String? profileImageUrl;
  final DateTime createdAt;
  int likesCount;
  int commentCount;
  bool isLiked;

  Post({
    required this.id,
    required this.motherId,
    required this.fullName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.profileImageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentCount,
    required this.isLiked,
  });

  factory Post.fromMap(Map<String, dynamic> map, String fullName) {
    return Post(
      id: map['id'] as String,
      motherId: map['mother_id'] as String,
      fullName: fullName,
      title: map['title'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      profileImageUrl: map['mothers']['profile_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      likesCount: map['likes_count'] as int? ?? 0,
      commentCount: map['comment_count'] as int? ?? 0,
      isLiked: false, // Set in PostProvider
    );
  }
}
