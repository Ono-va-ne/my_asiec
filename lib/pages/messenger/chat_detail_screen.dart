import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat.dart';
import '../../models/chat_message.dart';
import '../../services/chat_api.dart';
import '../../services/crypto_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Chat chat;
  final int currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _wsChannel;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  // Базовый адрес WebSocket:
  // 10.0.2.2 — для Android эмулятора
  // localhost — для iOS эмулятора
  // 192.168.x.x — локальный IP вашего ПК для физического телефона
  final String _wsBaseUrl = 'ws://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Загружаем историю из PostgreSQL и РАСШИФРОВЫВАЕМ каждое сообщение
    try {
      final rawHistory = await ChatApiService.getChatMessages(widget.chat.id);

      final decryptedHistory = rawHistory.map((msg) {
        return ChatMessage(
          id: msg.id,
          senderId: msg.senderId,
          senderName: msg.senderName,
          text: CryptoService.decryptText(msg.text, widget.chat.id),
          createdAt: msg.createdAt,
        );
      }).toList();

      setState(() {
        _messages = decryptedHistory;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки истории: $e')),
        );
      }
    }

    // 2. Подключаем WebSocket для мгновенных сообщений
    final wsUrl = Uri.parse(
      '$_wsBaseUrl/ws/chat/${widget.chat.id}/${widget.currentUserId}',
    );

    _wsChannel = WebSocketChannel.connect(wsUrl);

    // Слушаем входящие сообщения из сокета
    _wsChannel!.stream.listen(
      (data) {
        final jsonMsg = jsonDecode(data);

        final decryptedText = CryptoService.decryptText(
          jsonMsg['text'] ?? '',
          widget.chat.id,
        );

        final newMessage = ChatMessage(
          senderId: jsonMsg['sender_id'],
          senderName: jsonMsg['sender_name'], // <--- Передаем имя, прилетевшее из WS
          text: decryptedText,
          createdAt: DateTime.now(),
        );

        setState(() {
          _messages.add(newMessage);
        });

        _scrollToBottom();
      },
      onError: (error) {
        print('WebSocket ошибка: $error');
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _wsChannel == null) return;

    // 1. Зашифровываем перед отправкой
    final encryptedText = CryptoService.encryptText(text, widget.chat.id);

    // 2. Отправляем зашифрованный JSON в WebSocket
    final payload = jsonEncode({
      "encrypted_text": encryptedText,
    });

    _wsChannel!.sink.add(payload);
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chat.title),
            Text(
              widget.chat.isReadOnly ? 'Новостной канал' : widget.chat.type,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Нет сообщений'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == widget.currentUserId;

                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Поле ввода текста (скрывается, если новостной канал / read-only)
          if (!widget.chat.isReadOnly) _buildInputArea(),
        ],
      ),
    );
  }

  // Виджет сообщения ("Облачко")
  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Имя отправителя (отображаем только для чужих сообщений)
            if (!isMe && msg.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  msg.senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Панель ввода и отправки текста
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                onFieldSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
              ),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}