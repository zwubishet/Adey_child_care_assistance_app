class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isSeen;
  final bool isEdited;
  final String senderName;
  final String receiverName;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isSeen,
    required this.isEdited,
    required this.senderName,
    required this.receiverName,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSeen: map['is_seen'] as bool? ?? false,
      isEdited: map['is_edited'] as bool? ?? false,
      senderName: map['sender']?['full_name'] as String? ?? 'Unknown',
      receiverName: map['receiver']?['full_name'] as String? ?? 'Unknown',
    );
  }
}
