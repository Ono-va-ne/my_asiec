import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_asiec/services/media_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_asiec/pages/profile/profile_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat.dart';
import '../../models/chat_message.dart';
import '../../services/chat_api.dart';
import '../../services/crypto_service.dart';
import '../../some_fuv.dart';
import 'chat_info_screen.dart';

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
  final List<PlatformFile> _pendingFiles = [];
  bool _isLoading = true;
  bool _isUploadingFile = false;
  int? _interlocutorId;

  final String _wsBaseUrl = 'ws://$apiBackendUrl:$apiBackendPort';

  int _membersCount = 0;
  bool _isInterlocutorOnline = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    try {
      final info = await ChatApiService.getChatInfo(widget.chat.id, widget.currentUserId);
      if (mounted) {
        setState(() {
          _membersCount = info['members_count'] ?? 0;
          _isInterlocutorOnline = info['is_online'] ?? false;
          _interlocutorId = info['interlocutor_id'];
        });
      }
    } catch (e) {
      print('Ошибка загрузки инфо о чате: $e');
    }
  }

  // Правильное склонение русского слова "участник"
  String _formatMembersCount(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count участник';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return '$count участника';
    } else {
      return '$count участников';
    }
  }

  // Формирование текста подзаголовка
  Widget? _buildAppBarSubtitle() {
    if (widget.chat.type == 'group' || widget.chat.type == 'subgroup') {
      return Text(
        _formatMembersCount(_membersCount),
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      );
    } else if (widget.chat.type == 'direct') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isInterlocutorOnline ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            ),
          ),
          Text(
            _isInterlocutorOnline ? 'В сети' : 'Не в сети',
            style: TextStyle(
              fontSize: 12,
              color: _isInterlocutorOnline ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      );
    } else if (widget.chat.type == 'news') {
      return null; // Для новостей ничего не отображаем
    }
    return null;
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
          mediaFiles: msg.mediaFiles,
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
        try {
          final jsonMsg = jsonDecode(data);

          final decryptedText = CryptoService.decryptText(
            jsonMsg['text'] ?? '',
            widget.chat.id,
          );

          final newMessage = ChatMessage.fromWsJson({
            ...jsonMsg,
            'text': decryptedText,
          });

          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
        } catch (e, stack) {
          print('Ошибка обработки сообщения: $e');
          print(stack);
        }
      },
      onError: (error) {
        print('WebSocket ошибка: $error');
      },
    );
  }

  void _openFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl)
            )
          )
        )
      )
    );
  }
  Future<void> _openDocumentFile(MediaAttachment media) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Открытие файла "${media.originalName}"...'),
          duration: const Duration(seconds: 2),
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final localFilePath = '${tempDir.path}/${media.originalName}';
      final localFile = File(localFilePath);

      // Скачиваем файл во временный кэш, если его еще нет
      if (!await localFile.exists()) {
        final fullUrl = '${MediaService.baseUrl}${media.url}';
        final response = await http.get(Uri.parse(fullUrl));
        await localFile.writeAsBytes(response.bodyBytes);
      }

      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Открываем файл через системный просмотрщик (Word, PowerPoint, PDF Reader и т.д.)
      final result = await OpenFile.open(localFilePath);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия файла: $e')),
        );
      }
    }
  }

  // Выбор обработчика в зависимости от типа файла
  void _handleMediaTap(MediaAttachment media) {
    final isImage = media.mimeType.startsWith('image/');
    final fullUrl = '${MediaService.baseUrl}${media.url}';

    if (isImage) {
      _openFullImage(fullUrl);
    } else {
      _openDocumentFile(media);
    }
  }

  // ВЫБОР И ОТПРАВКА МЕДИАФАЙЛА
  Future<void> _pickAndSendMedia() async {
    final result = await FilePicker.pickFiles();
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _pendingFiles.addAll(result.files.where((f) => f.path != null));
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    print('Отправлено');
    if (text.isEmpty && _pendingFiles.isEmpty) return;
    if (_wsChannel == null) return;

    List<int> uploadedMediaIds = [];

    // Если есть прикрепленные файлы — загружаем их на сервер
    if (_pendingFiles.isNotEmpty) {
      setState(() => _isUploadingFile = true);
      try {
        for (var pFile in _pendingFiles) {
          final file = File(pFile.path!);
          final mediaData = await MediaService.uploadOrGetMedia(file, pFile.name);
          uploadedMediaIds.add(mediaData['media_id']);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки файлов: $e')),
          );
        }
        setState(() => _isUploadingFile = false);
        return;
      }
    }

    // Зашифровываем перед отправкой
    final encryptedText = CryptoService.encryptText(text, widget.chat.id);

    // Отправляем зашифрованный JSON в WebSocket
    final payload = jsonEncode({
      "encrypted_text": encryptedText,
      "media_ids": uploadedMediaIds,
    });

    _wsChannel!.sink.add(payload);
    _messageController.clear();
    setState(() {
      _pendingFiles.clear();
      _isUploadingFile = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Открыть/скачать файл при клике
  void _openFile(String? mediaUrl) async {
    if (mediaUrl == null) return;
    final fullUrl = '${MediaService.baseUrl}$mediaUrl';
    final uri = Uri.parse(fullUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _onAppBarTap() async {
    if (widget.chat.type == 'direct') {
      int? targetId = _interlocutorId;

      // Если ID собеседника еще не успел подгрузиться, загружаем его прямо сейчас!
      if (targetId == null) {
        try {
          final info = await ChatApiService.getChatInfo(widget.chat.id, widget.currentUserId);
          targetId = info['interlocutor_id'];
          if (mounted) {
            setState(() {
              _interlocutorId = targetId;
            });
          }
        } catch (e) {
          print('Ошибка получения ID собеседника: $e');
        }
      }

      // Если ID найден — открываем его профиль!
      if (targetId != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              targetUserId: targetId!,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      }
    } else {
      // Для групп и каналов открываем экран информации о чате
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatInfoScreen(
            chatId: widget.chat.id,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    }
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
        title: InkWell(
          onTap: _onAppBarTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.chat.title),
              if (_buildAppBarSubtitle() != null) _buildAppBarSubtitle()!,
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isUploadingFile)
            LinearProgressIndicator(backgroundColor: Theme.of(context).primaryColor),
          // Список сообщений
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final isMe = msg.senderId == widget.currentUserId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          if (_pendingFiles.isNotEmpty) _buildPendingFilesBar(),
          // Поле ввода текста (скрывается, если новостной канал / read-only)
          if (!widget.chat.isReadOnly) _buildInputArea(),
        ],
      ),
    );
  }
  
  // Панель с миниатюрами прикрепленных файлов перед отправкой
  Widget _buildPendingFilesBar() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingFiles.length,
        itemBuilder: (context, index) {
          final file = _pendingFiles[index];
          final isImage = ['jpg', 'jpeg', 'png', 'webp'].any((ext) => file.name.toLowerCase().endsWith(ext));

          return Stack(
            children: [
              Container(
                width: 65,
                height: 65,
                margin: const EdgeInsets.only(right: 8, top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isImage && file.path != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(file.path!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
              ),

              // Удаление прикреплённого файла
              Positioned(
                top: 0,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _pendingFiles.removeAt(index);
                    });
                  },
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    child: Icon(Icons.close, size: 12, color: Theme.of(context).colorScheme.onTertiary),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Виджет сообщения ("Облачко")
  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceBright,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Имя отправителя
            if (!isMe && msg.senderName != null && widget.chat.type != 'direct')
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed:() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        targetUserId: msg.senderId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Text(
                  msg.senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ),

            // Отрисовка списка прикрепленных файлов
            if (msg.mediaFiles.isNotEmpty)
              Column(
                children: msg.mediaFiles.map((media) {
                  final isImage = media.mimeType.startsWith('image/');
                  final fullUrl = '${MediaService.baseUrl}${media.url}';

                  if (isImage) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0, top: 4),
                      child: GestureDetector(
                        onTap: () => _handleMediaTap(media),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(fullUrl, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () => _handleMediaTap(media),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.primary,
                            foregroundColor: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                            child: Icon(Icons.insert_drive_file)
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  media.originalName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                Text(
                                  _formatFileSize(media.fileSize),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Theme.of(context).colorScheme.onPrimary.withAlpha(155) : Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Icon(Icons.download, color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimaryContainer),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (msg.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  msg.text,
                  textAlign: TextAlign.start,
                  style: TextStyle(color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface),
                ),
              ),

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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
              onPressed: _isUploadingFile ? null : _pickAndSendMedia,
            ),
            Expanded(
              child: TextFormField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                minLines: 1,
                maxLength: 4096,
                onChanged: (value) {
                  setState(() {});
                },
                buildCounter: (
                  BuildContext context, {
                  required int currentLength,
                  required int? maxLength,
                  required bool isFocused,
                }) {
                  // Показывать счетчик только если введено больше 10 символов
                  if (currentLength > 3072) {
                    return Text(
                      '$currentLength / $maxLength',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    );
                  }
                  return null; // Возвращаем null, чтобы полностью скрыть счетчик и убрать отступ под полем
                },
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  contentPadding: EdgeInsets.symmetric(
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