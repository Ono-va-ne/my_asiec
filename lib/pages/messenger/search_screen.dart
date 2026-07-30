import 'package:flutter/material.dart';
import '../../services/chat_api.dart';
import '../../services/crypto_service.dart';
import '../../models/chat.dart';
import '../profile/profile_screen.dart';
import 'chat_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final int currentUserId;

  const SearchScreen({super.key, required this.currentUserId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _foundUsers = [];
  List<Map<String, dynamic>> _rawMessages = [];
  List<Map<String, dynamic>> _filteredMessages = [];

  bool _isSearchingUsers = false;
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessagesForSearch();
  }

  // Загружаем сообщения один раз и расшифровываем их локально
  Future<void> _loadMessagesForSearch() async {
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await ChatApiService.getMessagesForSearch(widget.currentUserId);

      // Расшифровываем каждое сообщение на устройстве
      for (var msg in messages) {
        final chatId = msg['chat_id'] as int;
        final rawText = msg['encrypted_text'] ?? '';
        msg['decrypted_text'] = CryptoService.decryptText(rawText, chatId);
      }

      setState(() {
        _rawMessages = messages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      setState(() => _isLoadingMessages = false);
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();

    // 1. Поиск по пользователям (через API)
    if (q.length >= 2) {
      setState(() => _isSearchingUsers = true);
      ChatApiService.searchUsers(q).then((users) {
        if (mounted) {
          setState(() {
            _foundUsers = users;
            _isSearchingUsers = false;
          });
        }
      });
    } else {
      setState(() => _foundUsers = []);
    }

    // 2. Локальный поиск по расшифрованным сообщениям
    if (q.isNotEmpty) {
      setState(() {
        _filteredMessages = _rawMessages.where((msg) {
          final text = (msg['decrypted_text'] as String).toLowerCase();
          final sender = (msg['sender_name'] ?? '').toString().toLowerCase();
          final chatTitle = (msg['chat_title'] ?? '').toString().toLowerCase();

          return text.contains(q) || sender.contains(q) || chatTitle.contains(q);
        }).toList();
      });
    } else {
      setState(() => _filteredMessages = []);
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Поиск ...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Люди'),
            Tab(text: 'Сообщения'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка 1: Поиск Людей
          _buildUsersTab(),

          // Вкладка 2: Поиск Сообщений
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isSearchingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.length < 2) {
      return const Center(
        child: Text('Введите хотя бы 2 символа для поиска людей'),
      );
    }

    if (_foundUsers.isEmpty) {
      return const Center(child: Text('Пользователи не найдены'));
    }

    return ListView.separated(
      itemCount: _foundUsers.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = _foundUsers[index];
        final fullName = user['full_name'] ?? 'Без имени';
        final role = user['role'] ?? 'student';
        final group = user['college_group'];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _getInitials(fullName),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            group != null ? '@${user['login']} ($group) ' : '@${user['login']}',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          onTap: () {
            // Переход в профиль найденного пользователя
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  targetUserId: user['id'],
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().isEmpty) {
      return const Center(child: Text('Введите текст для поиска по сообщениям'));
    }

    if (_filteredMessages.isEmpty) {
      return const Center(child: Text('Сообщения не найдены'));
    }

    return ListView.separated(
      itemCount: _filteredMessages.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = _filteredMessages[index];
        final chatTitle = msg['chat_title'] ?? 'Чат';
        final senderName = msg['sender_name'] ?? 'Пользователь';
        final text = msg['decrypted_text'] ?? '';
        final date = DateTime.parse(msg['created_at']);

        return ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chatTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
          subtitle: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(fontSize: 13),
              children: [
                TextSpan(
                  text: '$senderName: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
          onTap: () {
            // Переход прямо в тот чат, где найдено сообщение
            final chat = Chat(
              id: msg['chat_id'],
              title: chatTitle,
              type: msg['chat_type'] ?? 'group',
              isReadOnly: msg['is_read_only'] ?? false,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chat: chat,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}