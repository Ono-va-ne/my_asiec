import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../some_fuv.dart';
import 'notification_service.dart';

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;
  int? _userId;
  bool _configured = false;

  Future<void> configureForUser(int userId) async {
    _userId = userId;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (_configured) {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      return;
    }

  _configured = true;

    _messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    FirebaseMessaging.onMessageOpenedApp.listen(_openChatFromMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _openChatFromMessage(initialMessage);
    }
  }

  Future<void> _registerToken(String token) async {
    final userId = _userId;
    if (userId == null) return;

    await http.post(
      Uri.parse('http://$apiBackendUrl:$apiBackendPort/users/$userId/push-tokens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'platform': 'android'}),
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = message.data;
    final chatId = int.tryParse('${data['chat_id']}');
    if (chatId == null || _userId == null) return;

    await NotificationService().showMessageNotification(
      chatId: chatId,
      currentUserId: _userId!,
      messageId: int.tryParse('${data['message_id']}') ?? 0,
      chatTitle: '${data['chat_title'] ?? ''}',
      senderName: '${data['sender_name'] ?? 'Пользователь'}',
      encryptedText: '${data['encrypted_text'] ?? ''}',
      mediaIds: const [],
    );
  }

  void _openChatFromMessage(RemoteMessage message) {
    final chatId = int.tryParse('${message.data['chat_id']}');
    if (chatId == null) return;

    // Здесь получите Chat по chatId и откройте ChatDetailScreen
    // через NavigatorService.navigatorKey.currentState.
  }
}