class ChatMessage {
  final int? id;
  final int senderId;
  final String? senderName;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.createdAt,
  });

  // Из REST API (история)
  factory ChatMessage.fromRestJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['full_name'],
      text: json['encrypted_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Из WebSocket (в реальном времени)
  factory ChatMessage.fromWsJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['sender_id'],
      text: json['text'] ?? '',
      createdAt: DateTime.now(),
    );
  }
}