import 'package:flutter/material.dart';
import '../../models/chat.dart';

class ChatDetailScreen extends StatelessWidget {
  final Chat chat;
  final int currentUserId;

  const ChatDetailScreen({
    Key? key,
    required this.chat,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat.title),
            Text(
              chat.isReadOnly ? 'Только чтение (Канал)' : 'Чат',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Center(
        child: Text(
          'Здесь будет переписка для chatId: ${chat.id}\n'
          'Подключение через WebSocket: ws://10.0.2.2:8000/ws/chat/${chat.id}/$currentUserId',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}