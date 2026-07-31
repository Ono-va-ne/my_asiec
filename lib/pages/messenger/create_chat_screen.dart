import 'package:flutter/material.dart';
import '../../services/chat_api.dart';
import '../../services/auth_service.dart';

class CreateChatScreen extends StatefulWidget {
  final int currentUserId;

  const CreateChatScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedType = 'subgroup'; // По умолчанию доступны всем
  String _userRole = 'student';
  List<dynamic> _userSecondaryRoles = [];
  bool _isHeadman = false;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final Set<int> _selectedUserIds = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // 1. Узнаем роли создателя
      final profile = await AuthService.getUserProfile(widget.currentUserId);
      _userRole = profile['role'] ?? 'student';
      _userSecondaryRoles = profile['secondary_roles'] ?? [];
      
      _isHeadman = _userSecondaryRoles.any(
        (r) => r.toString().toLowerCase().contains('староста'),
      );

      // 2. Загружаем пользователей (одногруппники уже идут первыми с бэкенда)
      final users = await ChatApiService.getUsersForInvite(widget.currentUserId);

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  // Проверка прав на тип чата
  bool _canCreateNews() => _userRole == 'director' || _userRole == 'admin';
  bool _canCreateGroup() =>
      _userRole == 'director' || _userRole == 'admin' || _userRole == 'teacher' || _isHeadman;

  void _filterUsers(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((u) {
          final name = (u['full_name'] ?? '').toString().toLowerCase();
          final group = (u['college_group'] ?? '').toString().toLowerCase();
          return name.contains(q) || group.contains(q);
        }).toList();
      }
    });
  }

  // Стиль и иконка аватарки чата в зависимости от выбранного типа
  Map<String, dynamic> _getAvatarStyle() {
    switch (_selectedType) {
      case 'news':
        return {'icon': Icons.campaign, 'color': Colors.orange};
      case 'group':
        return {'icon': Icons.groups, 'color': Colors.blue};
      case 'subgroup':
      default:
        return {'icon': Icons.workspaces, 'color': Colors.purple};
    }
  }

  void _submitCreateChat() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название чата')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ChatApiService.createChat(
        title: title,
        type: _selectedType,
        createdBy: widget.currentUserId,
        memberIds: _selectedUserIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Возврат на список чатов с обновлением
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarStyle = _getAvatarStyle();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание чата'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitCreateChat,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // ВЕРХНИЙ РЯД: Аватарка чата + Название
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: avatarStyle['color'].withOpacity(0.2),
                            child: Icon(avatarStyle['icon'], color: avatarStyle['color'], size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                hintText: 'Название чата...',
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ВЫБОР ТИПА ЧАТА (ЧИПЫ С ПРОВЕРКОЙ РОЛЕЙ)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Подгруппа (Доступна всем)
                            ChoiceChip(
                              label: const Text('Подгруппа'),
                              selected: _selectedType == 'subgroup',
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedType = 'subgroup');
                              },
                            ),
                            const SizedBox(width: 8),

                            // Чат группы (Директор, Админ, Преподаватель, Староста)
                            ChoiceChip(
                              label: const Text('Чат группы'),
                              selected: _selectedType == 'group',
                              // disabledColor: Colors.grey.shade200,
                              onSelected: _canCreateGroup()
                                  ? (selected) {
                                      if (selected) setState(() => _selectedType = 'group');
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 8),

                            // Новости (Директор, Админ)
                            ChoiceChip(
                              label: const Text('Новости'),
                              selected: _selectedType == 'news',
                              // disabledColor: Colors.grey.shade200,
                              onSelected: _canCreateNews()
                                  ? (selected) {
                                      if (selected) setState(() => _selectedType = 'news');
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 8),
                // ПОИСК УЧАСТНИКОВ
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск участников...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      // fillColor: Colors.grey.shade100,
                    ),
                    onChanged: _filterUsers,
                  ),
                ),

                // СПИСОК УЧАСТНИКОВ ДЛЯ ДОБАВЛЕНИЯ
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final userId = user['id'] as int;
                      final isSelected = _selectedUserIds.contains(userId);
                      final group = user['college_group'];
                      final secRoles = (user['secondary_roles'] as List?) ?? [];

                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(user['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(group != null ? 'Группа: $group' : user['role']),
                            if (secRoles.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: secRoles.map((r) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(55),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(r.toString(), style: const TextStyle(fontSize: 10, color: Colors.blue)),
                                )).toList(),
                              ),
                          ],
                        ),
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedUserIds.add(userId);
                            } else {
                              _selectedUserIds.remove(userId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}