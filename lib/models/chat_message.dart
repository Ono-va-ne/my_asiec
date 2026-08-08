class MediaAttachment {
  final int id;
  final String url;
  final String originalName;
  final String mimeType;
  final int fileSize;

  MediaAttachment({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'],
      url: json['url'] ?? '',
      originalName: json['original_name'] ?? 'Файл',
      mimeType: json['mime_type'] ?? 'application/octet-stream',
      fileSize: json['file_size'] ?? 0,
    );
  }
}

class ChatMessage {
  final int? id;
  final int senderId;
  final String? senderName;
  final String text;
  final DateTime createdAt;
  final List<MediaAttachment> mediaFiles;

  ChatMessage({
    this.id,
    required this.senderId,
    this.senderName,
    required this.text,
    required this.createdAt,
    this.mediaFiles = const [],
  });

  factory ChatMessage.fromRestJson(Map<String, dynamic> json) {
    final rawMedia = (json['media_files'] as List? ?? []);
    final mediaList = rawMedia
        .map((m) => MediaAttachment.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();

    return ChatMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['full_name'],
      text: json['encrypted_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      mediaFiles: mediaList,
    );
  }

  factory ChatMessage.fromWsJson(Map<String, dynamic> json) {
    final rawMedia = (json['media_files'] as List? ?? []);
    final mediaList = rawMedia
        .map((m) => MediaAttachment.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();

    return ChatMessage(
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      text: json['text'] ?? '',
      createdAt: DateTime.now(),
      mediaFiles: mediaList,
    );
  }
}