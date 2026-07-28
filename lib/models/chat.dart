class Chat {
  final int id;
  final String title;
  final String type; // news, group, subgroup, direct
  final bool isReadOnly;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  Chat({
    required this.id,
    required this.title,
    required this.type,
    required this.isReadOnly,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      isReadOnly: json['is_read_only'] ?? false,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'])
          : null,
    );
  }
}