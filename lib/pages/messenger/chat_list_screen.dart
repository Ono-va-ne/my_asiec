import 'package:flutter/material.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:my_asiec/pages/messenger/create_chat_screen.dart';
import 'package:my_asiec/pages/messenger/search_screen.dart';
import '../../models/chat.dart';
import '../../services/chat_api.dart';
import '../../services/auth_service.dart';
import 'chat_detail_screen.dart';
import '../profile/auth_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int? _currentUserId;
  bool _isAuthChecked = false;
  late Future<List<Chat>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    _chatsFuture = _loadInitialData();
  }

  Future<List<Chat>> _loadInitialData() async {
    final userId = await AuthService.getCurrentUserId();
    if(mounted) {
      setState(() {
        _currentUserId = userId;
        _isAuthChecked = true;
      });
    }
    return ChatApiService.getUserChats(userId ?? 0);
  }

  // This method is called to refresh the UI.
  Future<void> _refreshChats() async {
    _chatsFuture = _loadInitialData();
    setState(() {}); // Trigger rebuild
  }

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
        title: Text(AppLocalizations.of(context)!.messengerScreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Поиск",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen(
                  currentUserId: _currentUserId ?? 0,
                ) )
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: Column(
          children: [
            // Баннер для гостевого режима
            if (_isAuthChecked && _currentUserId == null)
              Container(
                color: Colors.amber.withAlpha(55),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Гостевой режим: видны только каналы.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                        if (res == true) _refreshChats();
                      },
                      child: const Text('Войти'),
                    ),
                  ],
                ),
              ),

            // Список чатов
            Expanded(
              child: FutureBuilder<List<Chat>>(
                future: _chatsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  }

                  final chats = snapshot.data ?? [];

                  if (chats.isEmpty) {
                    return const Center(child: Text('Чаты не найдены'));
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
                        title: Text(
                          chat.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          chat.lastMessage ?? 'Нет сообщений',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chat: chat,
                                // Если гость, передаем id = 0 (только для чтения)
                                currentUserId: _currentUserId ?? 0, 
                              ),
                            ),
                          ).then((_) => _refreshChats());
                        },
                        trailing: chat.lastMessageTime != null
                      ? Text(
                          "${chat.lastMessageTime!.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        )
                      : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentUserId != null
        ? FloatingActionButton(
            child: const Icon(Icons.add_comment),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateChatScreen(
                    currentUserId: _currentUserId!,
                  ),
                ),
              );
              if (created == true) {
                _refreshChats(); // Обновляем список чатов
              }
            },
          )
        : null,
    );
  }
}