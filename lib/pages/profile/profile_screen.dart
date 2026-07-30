import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/chat.dart';
import '../messenger/chat_detail_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int targetUserId; // Чей профиль смотрим
  final int currentUserId; // Наш ID

  const ProfileScreen({
    super.key,
    required this.targetUserId,
    required this.currentUserId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  bool get isMyProfile => widget.targetUserId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.getUserProfile(widget.targetUserId);
  }

  // Генерация инициалов для красивой аватарки
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }

  // Красивый заголовок роли
  Map<String, dynamic> _getRoleBadge(String role) {
    switch (role) {
      case 'teacher':
        return {'label': 'Преподаватель', 'color': Colors.blue};
      case 'council':
        return {'label': 'Студенческий совет', 'color': Colors.green};
      case 'director':
        return {'label': 'Дирекция', 'color': Colors.amber.shade800};
      case 'admin':
        return {'label': 'Администратор', 'color': Colors.red};
      case 'student':
      default:
        return {'label': 'Студент', 'color': Colors.grey.shade700};
    }
  }

  void _openDirectChat() async {
    try {
      final chatId = await AuthService.getOrCreateDirectChat(
        widget.currentUserId,
        widget.targetUserId,
      );

      final profile = await _profileFuture;

      if (mounted) {
        final directChat = Chat(
          id: chatId,
          title: profile['full_name'],
          type: 'direct',
          isReadOnly: false,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chat: directChat,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия чата: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Мой профиль' : 'Профиль пользователя'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: () async {
                await AuthService.logout();
                if (mounted) {
                  Navigator.pop(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final profile = snapshot.data!;
          final initials = _getInitials(profile['full_name'] ?? '');
          final roleBadge = _getRoleBadge(profile['role'] ?? 'student');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Аватарка с инициалами
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Имя
                Text(
                  profile['full_name'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Бейдж Роли
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleBadge['color'].withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    roleBadge['label'],
                    style: TextStyle(
                      color: roleBadge['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),

                // Группа (если студент)
                if (profile['college_group'] != null)
                  ListTile(
                    leading: const Icon(Icons.group),
                    title: const Text('Группа'),
                    subtitle: Text(profile['college_group']),
                  ),

                // Логин
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Логин'),
                  subtitle: Text(profile['login'] ?? ''),
                ),

                const SizedBox(height: 32),

                // Кнопка "Написать сообщение" (показываем только на чужом профиле)
                if (!isMyProfile)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text('Написать сообщение'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _openDirectChat,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}