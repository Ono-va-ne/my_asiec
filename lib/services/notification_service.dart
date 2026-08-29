import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chat_api.dart'; // Проверьте правильность пути к вашему сервису
import 'crypto_service.dart'; // Проверьте правильность пути к сервису шифрования

class NotificationService {
  // Синглтон для доступа к сервису
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Инициализация плагина
  Future<void> init() async {
    // Настройки для Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Настройки для iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Общие настройки
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Подключаем обработчик нажатий на уведомления и кнопки в шторке
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationAction,
    );
  }

  // Обработчик кликов по кнопкам "Ответить" и "Прочитать" в шторке
  static void _onNotificationAction(NotificationResponse response) async {
    final payloadStr = response.payload;
    if (payloadStr == null) return;

    try {
      final payload = jsonDecode(payloadStr);
      final chatId = payload['chat_id'] as int;
      final userId = payload['user_id'] as int;
      final messageId = payload['message_id'] as int;

      // 1. Клик по кнопке "ПРОЧИТАТЬ"
      if (response.actionId == 'mark_read') {
        await ChatApiService.markChatAsRead(chatId, userId, messageId);
        await NotificationService().cancelNotification(chatId);
      }

      // 2. Клик по кнопке "ОТВЕТИТЬ" (быстрый ответ из шторки)
      if (response.actionId == 'reply' && response.input != null) {
        await ChatApiService.markChatAsRead(chatId, userId, messageId);
        await NotificationService().cancelNotification(chatId);
      }
    } catch (e) {
      print('Ошибка обработки действия уведомления: $e');
    }
  }

  // Запрос разрешений (особенно важно для Android 13+ и iOS)
  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // ===========================================================================
  // УВЕДОМЛЕНИЯ МЕССЕНДЖЕРА (TELEGRAM STYLE)
  // ===========================================================================
  Future<void> showMessageNotification({
    required int chatId,
    required int currentUserId,
    required int messageId,
    required String chatTitle,
    required String senderName,
    required String encryptedText,
    required List<dynamic> mediaIds,
  }) async {
    // 1. Расшифровываем текст сообщения
    String bodyText = CryptoService.decryptText(encryptedText, chatId);

    // Если текста нет, но есть вложения:
    if (bodyText.isEmpty && mediaIds.isNotEmpty) {
      bodyText = '📷 Прикрепленный файл';
    }

    final payload = jsonEncode({
      'chat_id': chatId,
      'user_id': currentUserId,
      'message_id': messageId,
    });

    // Настройка канала и кнопок действий для Android
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messenger_messages_channel', // ID канала мессенджера
      'Messenger Notifications', // Имя канала
      channelDescription: 'Уведомления о новых сообщениях в чатах колледжа',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      actions: <AndroidNotificationAction>[
        // Кнопка быстрого ответа
        const AndroidNotificationAction(
          'reply',
          'Ответить',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Введите ответ...',
            ),
          ],
        ),
        // Кнопка "Прочитать"
        const AndroidNotificationAction(
          'mark_read',
          'Прочитать',
          showsUserInterface: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // Показываем уведомление (ID уведомления = ID чата, чтобы группировать сообщения)
    await flutterLocalNotificationsPlugin.show(
      id: chatId,
      title: chatTitle.isNotEmpty ? chatTitle : senderName,
      body: chatTitle.isNotEmpty ? '$senderName: $bodyText' : bodyText,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  // ===========================================================================
  // УВЕДОМЛЕНИЯ ДЛЯ POMODORO ТАЙМЕРА
  // ===========================================================================

  // Показать уведомление с прогрессом
  Future<void> showProgressNotification(String title, String body, int maxProgress, int progress) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'pomodoro_progress_channel', // ID канала
        'Pomodoro Progress', // Имя канала
        channelDescription: 'Shows the progress of the pomodoro timer.',
        importance: Importance.low, // Низкий приоритет, чтобы не мешать
        priority: Priority.low,
        showProgress: true,
        maxProgress: maxProgress,
        progress: progress,
        onlyAlertOnce: true, // Не издавать звук при обновлении
        playSound: false,
      );
    final NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics
    );
  }

  // Показать уведомление о завершении с звуком
  Future<void> showCompletionNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pomodoro_completion_channel', // ID канала
      'Pomodoro Completion', // Имя канала
      channelDescription: 'Notifies when a pomodoro session is complete.',
      importance: Importance.max, // Максимальный приоритет, чтобы было видно и слышно
      priority: Priority.high,
      playSound: true, // Включаем звук
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics
    );
  }

  // Отменить конкретное уведомление по ID
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  // Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}