import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ChatService {
  late WebSocketChannel channel;

  void connectToChat(int chatId, int userId) {
    // В локальной сети / эмуляторе:
    // Android Emulator -> 10.0.2.2, iOS / реальное устройство -> IP твоего ПК в Wi-Fi
    final wsUrl = Uri.parse('ws://10.0.2.2:8000/ws/chat/$chatId/$userId');
    channel = WebSocketChannel.connect(wsUrl);

    // Слушаем входящие сообщения
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      print("Новое сообщение от ${data['sender_id']}: ${data['text']}");
      // Здесь код расшифровки и обновления UI
    });
  }

  void sendMessage(String encryptedText) {
    final payload = jsonEncode({
      "encrypted_text": encryptedText,
    });
    channel.sink.add(payload);
  }

  void close() {
    channel.sink.close();
  }
}