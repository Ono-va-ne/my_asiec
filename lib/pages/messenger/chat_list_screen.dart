import 'package:flutter/material.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:my_asiec/pages/messenger/create_chat_screen.dart';
import 'package:my_asiec/pages/messenger/search_screen.dart';
import 'package:my_asiec/some_fuv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat.dart';
import '../../services/chat_api.dart';
import '../../services/auth_service.dart';
import 'chat_detail_screen.dart';
import '../profile/auth_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int? _currentUserId;
  bool _isAuthChecked = false;
  late Future<List<Chat>> _chatsFuture;
  WebSocketChannel? _notifChannel;
  final String _wsBaseUrl = 'ws://$apiBackendUrl:$apiBackendPort';

  @override
  void initState() {
    super.initState();
    _chatsFuture = _loadInitialData();
  }

  Future<List<Chat>> _loadInitialData() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isAuthChecked = true;
      });

      // Подключаем живые уведомления, если пользователь вошел!
      if (userId != null && userId > 0 && _notifChannel == null) {
        _connectNotifications(userId);
      }
    }
    return ChatApiService.getUserChats(userId ?? 0);
  }

  // Обновление списка чатов
  Future<void> _refreshChats() async {
    setState(() {
      _chatsFuture = _loadInitialData();
    });
  }

  void _connectNotifications(int userId) {
    try {
      final wsUrl = Uri.parse('$_wsBaseUrl/ws/notifications/$userId');
      _notifChannel = WebSocketChannel.connect(wsUrl);

      _notifChannel!.stream.listen((_) {
        // Как только пришло уведомление о новом сообщении -> обновляем список чатов на лету!
        if (mounted) {
          setState(() {
            _chatsFuture = ChatApiService.getUserChats(userId);
          });
        }
      }, onError: (e) {
        print('Ошибка WS уведомлений: $e');
      });
    } catch (e) {
      print('Ошибка подключения уведомлений: $e');
    }
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
  void dispose() {
    _notifChannel?.sink.close();
    super.dispose();
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
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    currentUserId: _currentUserId ?? 0,
                  ),
                ),
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
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Ошибка загрузки чатов: ${snapshot.error}'),
                          ),
                        ),
                      ],
                    );
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          
                        ),
                        subtitle: Text(
                          chat.lastMessage ?? 'Нет сообщений',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (chat.lastMessageTime != null)
                              Text(
                                "${chat.lastMessageTime!.hour.toString().padLeft(2, '0')}:${chat.lastMessageTime!.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: chat.unreadCount > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            if (chat.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  '${chat.unreadCount}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chat: chat,
                                currentUserId: _currentUserId ?? 0,
                              ),
                            ),
                          ).then((_) => _refreshChats());
                        },
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
                  _refreshChats();
                }
              },
            )
          : null,
    );
  }
}