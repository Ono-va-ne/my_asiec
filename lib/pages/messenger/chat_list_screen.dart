import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../services/chat_api.dart';
import 'chat_detail_screen.dart'; // Экран конкретного чата с сообщениями

class ChatListScreen extends StatefulWidget {
  final int currentUserId;

  const ChatListScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Chat>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _refreshChats();
  }

  void _refreshChats() {
    setState(() {
      _chatsFuture = ChatApiService.getUserChats(widget.currentUserId);
    });
  }

  // Выбор иконки и цвета в зависимости от типа чата
  Map<String, dynamic> _getChatTypeStyle(String type) {
    switch (type) {
      case 'news':
        return {'icon': Icons.campaign, 'color': Colors.orange, 'label': 'Канал'};
      case 'group':
        return {'icon': Icons.groups, 'color': Colors.blue, 'label': 'Группа'};
      case 'subgroup':
        return {'icon': Icons.workspaces, 'color': Colors.purple, 'label': 'Подгруппа'};
      case 'direct':
      default:
        return {'icon': Icons.person, 'color': Colors.green, 'label': 'ЛС'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshChats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshChats(),
        child: FutureBuilder<List<Chat>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Ошибка: ${snapshot.error}'),
              );
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return const Center(
                child: Text('У вас пока нет активных чатов'),
              );
            }

            return ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final style = _getChatTypeStyle(chat.type);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: style['color'].withOpacity(0.2),
                    child: Icon(style['icon'], color: style['color']),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isReadOnly)
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(Icons.lock, size: 14, color: Colors.grey),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    chat.lastMessage ?? 'Нет сообщений',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat.lastMessage == null ? Colors.grey : Colors.white,
                    ),
                  ),
                  trailing: chat.lastMessageTime != null
                      ? Text(
                          "${chat.lastMessageTime!.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      : null,
                  onTap: () {
                    // Переход к экрану переписки
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chat: chat,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    ).then((_) => _refreshChats()); // Обновляем список после возврата
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}