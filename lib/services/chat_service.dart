import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../some_fuv.dart';

class ChatService {
  late WebSocketChannel channel;

  void connectToChat(int chatId, int userId) {
    final wsUrl = Uri.parse('ws://$apiBackendUrl:$apiBackendPort/ws/chat/$chatId/$userId');
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