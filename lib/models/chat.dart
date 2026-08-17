import '/services/crypto_service.dart';

class Chat {
  final int id;
  final String title;
  final String type; // news, group, subgroup, direct
  final bool isReadOnly;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Chat({
    required this.id,
    required this.title,
    required this.type,
    required this.isReadOnly,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final chatId = json['id'] as int;
    final rawLastMessage = json['last_message'] as String?;

    // Расшифровываем последнее сообщение с помощью ключа этого чата
    final decryptedLastMsg = rawLastMessage != null
        ? CryptoService.decryptText(rawLastMessage, chatId)
        : null;

    return Chat(
      id: chatId,
      title: json['title'],
      type: json['type'],
      isReadOnly: json['is_read_only'] ?? false,
      lastMessage: decryptedLastMsg,
      lastMessageTime: json['last_message_time'] != null
        ? DateTime.parse(json['last_message_time'])
        : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}