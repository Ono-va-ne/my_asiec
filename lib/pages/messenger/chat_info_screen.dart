import 'package:flutter/material.dart';
import '../../services/chat_api.dart';
import '../profile/profile_screen.dart';

class ChatInfoScreen extends StatefulWidget {
  final int chatId;
  final int currentUserId;

  const ChatInfoScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  late Future<Map<String, dynamic>> _chatInfoFuture;
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _chatInfoFuture = ChatApiService.getChatInfo(widget.chatId, widget.currentUserId);
    _membersFuture = ChatApiService.getChatMembers(widget.chatId);
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "?";
  }

  Map<String, dynamic> _getChatTypeStyle(String type) {
    switch (type) {
      case 'news':
        return {'icon': Icons.campaign, 'color': Colors.orange, 'label': 'Новостной канал'};
      case 'group':
        return {'icon': Icons.groups, 'color': Colors.blue, 'label': 'Чат группы'};
      case 'subgroup':
      default:
        return {'icon': Icons.workspaces, 'color': Colors.purple, 'label': 'Подгруппа'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Информация о чате')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _chatInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final chatInfo = snapshot.data!;
          final style = _getChatTypeStyle(chatInfo['type']);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Аватарка чата
                CircleAvatar(
                  radius: 45,
                  backgroundColor: style['color'].withOpacity(0.2),
                  child: Icon(style['icon'], color: style['color'], size: 45),
                ),
                const SizedBox(height: 12),

                // Название чата
                Text(
                  chatInfo['title'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Тип и ID чата
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(
                      label: Text(style['label'], style: TextStyle(fontSize: 11, color: style['color'])),
                      backgroundColor: style['color'].withOpacity(0.15),
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('ID: #${chatInfo['id']}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                      backgroundColor: Theme.of(context).primaryColor,
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Заголовок Участников
                if (chatInfo['type'] != "news")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Участники (${chatInfo['members_count']})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Список участников
                if (chatInfo['type'] != "news")
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _membersFuture,
                    builder: (context, membersSnapshot) {
                      if (membersSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final members = membersSnapshot.data ?? [];

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: members.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = members[index];
                          final userId = user['id'] as int;
                          final fullName = user['full_name'] ?? 'Участник';
                          final isAdmin = user['is_admin'] == true;
                          final group = user['student_group'];
                          // final secRoles = (user['secondary_roles'] as List?) ?? [];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                _getInitials(fullName),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isAdmin)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Админ',
                                      style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(group != null ? 'Группа: $group' : user['role']),
                            onTap: () {
                              // Клик открывает профиль участника
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    targetUserId: userId,
                                    currentUserId: widget.currentUserId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}