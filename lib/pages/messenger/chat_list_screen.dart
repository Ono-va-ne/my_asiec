import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_asiec/l10n/app_localizations.dart';
import 'package:my_asiec/main.dart';
import 'package:my_asiec/pages/messenger/create_chat_screen.dart';
import 'package:my_asiec/pages/messenger/search_screen.dart';
import 'package:my_asiec/some_fuv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat.dart';
import '../../services/chat_api.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import 'chat_detail_screen.dart';
import '../profile/auth_screen.dart';
import 'dart:convert';
import '../../services/notification_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  int? _currentUserId;
  bool _isAuthChecked = false;
  late Future<List<Chat>> _chatsFuture;
  WebSocketChannel? _notifChannel;
  StreamSubscription<dynamic>? _notifSubscription;
  Timer? _notifReconnectTimer;
  int _notifConnectionId = 0;
  final String _wsBaseUrl = 'ws://$apiBackendUrl:$apiBackendPort';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatsFuture = _loadInitialData();
  }

  void _scheduleNotifReconnect(int userId) {
    _notifReconnectTimer?.cancel();
    _notifReconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _currentUserId == null || _currentUserId! <= 0) {
        return;
      }

      _connectNotifications(userId);
    });
  }

  Future<void> _handleAppResume() async {
    await _disconnectNotifications();

    final userId = _currentUserId;
    if (userId != null && userId > 0) {
      _connectNotifications(userId);
    }

    await _refreshChats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _disconnectNotifications();
    }
  }

  Future<List<Chat>> _loadInitialData() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _isAuthChecked = true;
      });

      // Подключаем живые уведомления, если пользователь вошел!
      if (userId != null && userId > 0) {
        await PushNotificationService.instance.configureForUser(userId);

        if (_notifChannel == null) {
          _connectNotifications(userId);
        }
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
    if (!mounted || _notifChannel != null || userId <= 0) {
      return;
    }

    try {
      final wsUrl = Uri.parse('$_wsBaseUrl/ws/notifications/$userId');
      final connectionId = ++_notifConnectionId;
      final channel = WebSocketChannel.connect(wsUrl);
      _notifChannel = channel;

      _notifSubscription = channel.stream.listen((data) {
        final notif = jsonDecode(data);

        if (notif['type'] == 'new_message') {
          final chatId = notif['chat_id'] as int;

          // Покажем уведомление в шторке только если пользователь НЕ находится сейчас внутри этого чата
          NotificationService().showMessageNotification(
            chatId: chatId,
            currentUserId: userId,
            messageId: notif['message_id'] ?? 0,
            chatTitle: notif['chat_title'] ?? '',
            senderName: notif['sender_name'] ?? 'Пользователь',
            encryptedText: notif['encrypted_text'] ?? '',
            mediaIds: notif['media_ids'] ?? [],
          );

          // Обновляем список чатов
          if (mounted) {
            setState(() {
              _chatsFuture = ChatApiService.getUserChats(userId);
            });
          }
        }
      }, onDone: () {
        print('WS уведомлений закрыт');
        if (mounted && connectionId == _notifConnectionId) {
          _notifChannel = null;
          _notifSubscription = null;
          _scheduleNotifReconnect(userId);
        }
      }, onError: (e) {
        print('Ошибка WS уведомлений: $e');
        if (mounted && connectionId == _notifConnectionId) {
          _notifChannel = null;
          _notifSubscription = null;
          channel.sink.close();
          _scheduleNotifReconnect(userId);
        }
      }, cancelOnError: true);
    } catch (e) {
      print('Ошибка подключения уведомлений: $e');
    }
  }

  Future<void> _disconnectNotifications() async {
    _notifReconnectTimer?.cancel();
    _notifReconnectTimer = null;

    // Invalidate callbacks from this socket before closing it.
    _notifConnectionId++;
    final subscription = _notifSubscription;
    final channel = _notifChannel;
    _notifSubscription = null;
    _notifChannel = null;

    await subscription?.cancel();
    await channel?.sink.close();
  }

  // Отображение последнего сообщения или названия файла
  Widget _buildSubtitle(Chat chat, BuildContext context) {
    final text = chat.lastMessage?.trim() ?? '';
    final mime = chat.lastMessageMimeType ?? '';
    final fileName = chat.lastMessageFileName ?? '';

    // Есть текст, нет файла
    if (text.isNotEmpty && (mime.isEmpty && fileName.isEmpty)) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    IconData? icon;
    String label = 'Медиафайл';

    // обработка разных типов файлов
    if (fileName.startsWith('voice_')) {
      icon = Icons.mic_rounded;
      label = 'Голосовое сообщение';
    } else if (mime.startsWith('audio/') && !fileName.startsWith('voice_')) {
      icon = Icons.audiotrack_rounded;
      label = fileName.isNotEmpty ? fileName : 'Аудио';
    } else if (mime.startsWith('image/')) {
      icon = Icons.photo_rounded;
      label = fileName.isNotEmpty ? fileName : 'Фотография';
    } else if (mime.startsWith('video/')) {
      icon = Icons.videocam_rounded;
      label = fileName.isNotEmpty ? fileName : 'Видео';
    } else if (mime.isNotEmpty || fileName.isNotEmpty) {
      icon = Icons.insert_drive_file_rounded;
      label = fileName.isNotEmpty ? fileName : 'Файл';
    } else {
      // Нет текста, нет файла (пустой чат)
      return const Text('Нет сообщений');
    }

    // Иконка + подпись в цвете темы
    return Row(
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontVariations: [FontVariation('XTRA', 500), FontVariation('wght', 600)]
          ),
        ),
        if (text.isNotEmpty)
          Text(', '),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              // color: Theme.of(context).colorScheme.primary,
              fontVariations: [FontVariation('wght', 500)]
            ),
          ),
      ],
    );
  }

  Map<String, dynamic> _getChatTypeStyle(String type) {
    switch (type) {
      case 'news':
        return {'icon': Icons.campaign, 'color': shiftHue(Theme.of(context).colorScheme.primary, 0), 'label': 'Канал'};
      case 'group':
        return {'icon': Icons.groups, 'color': shiftHue(Theme.of(context).colorScheme.primary, 100), 'label': 'Группа'};
      case 'subgroup':
        return {'icon': Icons.workspaces, 'color': shiftHue(Theme.of(context).colorScheme.primary, 200), 'label': 'Подгруппа'};
      case 'direct':
      default:
        return {'icon': Icons.person, 'color': shiftHue(Theme.of(context).colorScheme.primary, 300), 'label': 'ЛС'};
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectNotifications();
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
                color: shiftHue(Theme.of(context).colorScheme.primaryContainer, -180).withAlpha(55),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: shiftHue(Theme.of(context).colorScheme.primary, -180)),
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
                        // Иконка чата
                        leading: CircleAvatar(
                          backgroundColor: style['color'].withOpacity(0.2),
                          child: Icon(style['icon'], color: style['color']),
                        ),
                        // Название чата
                        title: Text(
                          chat.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Последнее сообщение (или файл)
                        subtitle: _buildSubtitle(chat, context),
                        // Время последнего сообщения и бейдж непрочитанных
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
      // Создание нового чата
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
