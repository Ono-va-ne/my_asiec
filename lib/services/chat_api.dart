import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/chat_message.dart';

class ChatApiService {
  // Для эмулятора Android — 10.0.2.2
  // Для iOS эмулятора — localhost
  // Для реального телефона — локальный IP твоего ПК в Wi-Fi (напр. 192.168.1.50)
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Получение списка чатов
  static Future<List<Chat>> getUserChats(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/chats'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить список чатов');
    }
  }
  // Получение истории чата
  static Future<List<ChatMessage>> getChatMessages(int chatId) async {
    final response = await http.get(Uri.parse('$baseUrl/chats/$chatId/messages'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatMessage.fromRestJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить историю сообщений');
    }
  }
  // Поиск пользователей по ФИО/логину
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeComponent(query)}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Ошибка поиска пользователей');
    }
  }

  // Загрузка сообщений из доступных чатов для локального поиска
  static Future<List<Map<String, dynamic>>> getMessagesForSearch(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/messages_search'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Ошибка загрузки сообщений');
    }
  }
}