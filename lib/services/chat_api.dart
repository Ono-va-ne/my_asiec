import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';

class ChatApiService {
  // Для эмулятора Android — 10.0.2.2
  // Для iOS эмулятора — localhost
  // Для реального телефона — локальный IP твоего ПК в Wi-Fi (напр. 192.168.1.50)
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<List<Chat>> getUserChats(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/chats'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Не удалось загрузить список чатов');
    }
  }
}