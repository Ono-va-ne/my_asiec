import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Измените IP при необходимости

  // Сохранить данные сессии
  static Future<void> saveSession(int userId, String fullName, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentUserId', userId);
    await prefs.setString('userFullName', fullName);
    await prefs.setString('userRole', role);
  }

  // Получить ID текущего залогиненного пользователя
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('currentUserId');
  }

  // Выход из системы
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Вход
  static Future<Map<String, dynamic>> login(String loginStr, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'login': loginStr, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveSession(data['userId'], data['full_name'], data['role']);
      return data;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Ошибка авторизации');
    }
  }

  // Регистрация
  static Future<void> register({
    required String login,
    required String password,
    required String fullName,
    required String role,
    String? studentGroup,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login,
        'password': password,
        'full_name': fullName,
        'role': role,
        'college_group': studentGroup?.isEmpty == true ? null : studentGroup,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Ошибка регистрации');
    }
  }

  // Загрузка профиля пользователя по ID
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Не удалось загрузить профиль');
    }
  }

  // Открыть/Создать личный чат
  static Future<int> getOrCreateDirectChat(int currentUserId, int targetUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/direct'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user1_id': currentUserId,
        'user2_id': targetUserId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['chatId'];
    } else {
      throw Exception('Не удалось создать личный чат');
    }
  }
}