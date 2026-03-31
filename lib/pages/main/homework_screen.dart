import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../models/homework.dart';
import '../homework_edit_screen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../services/local_homework_service.dart';
import '../../services/settings_service.dart'; // Импортируем сервис настроек
import '../../l10n/app_localizations.dart';
import '../../services/homework_completion_service.dart';
import '../../data/text_emojis.dart';
import '../homework_view_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  String? _userGroupId; // ID группы пользователя из настроек
  Stream<List<Homework>>? _homeworkStream;
  StreamSubscription? _serverSubscription;

  bool _isDueDateTodayOrFuture(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueDatestart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDatestart.isAtSameMomentAs(todayStart) || dueDatestart.isAfter(todayStart);
  }

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в ID группы и статусах выполнения
    settingsService.defaultGroupIdNotifier.addListener(_setupAndLoadData);
    homeworkCompletionService.completedIdsNotifier.addListener(_onCompletionChanged);

    // Первоначальная загрузка
    _setupAndLoadData();
  }

  void _setupAndLoadData() {
    _loadUserGroupId();

    // Отменяем старую подписку на сервер, если она была
    _serverSubscription?.cancel();

    // Основной поток данных для UI теперь идет из локального сервиса (кэш + локальные)
    _homeworkStream = _localHomeworkService.getHomeworkStream().map((homeworks) {
      homeworks.sort((a, b) => a.due_date.compareTo(b.due_date));
      return homeworks;
    });

    // В фоне подписываемся на сервер для обновления кэша
    final serverStream = _client.from('homework').stream(primaryKey: ['id']).order('due_date');

    _serverSubscription = serverStream
        .timeout(const Duration(seconds: 5)) // Добавляем таймаут
        .listen((data) {
      final serverHomeworks = (data as List)
          .map((row) => Homework.fromJson(row as Map<String, dynamic>, (row['id'] ?? '').toString()))
          .toList();
      // Кэшируем успешные данные
      _localHomeworkService.cacheServerHomework(serverHomeworks);
    }, onError: (error) {
      // При ошибке или таймауте просто логируем ее.
      // UI продолжит показывать данные из кэша.
      print("Ошибка или таймаут при получении данных с сервера: $error");
    });

    if (mounted) setState(() {});
  }

  void _onCompletionChanged() {
    // Просто перестраиваем виджет, когда меняется список выполненных
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    settingsService.defaultGroupIdNotifier.removeListener(_setupAndLoadData);
    homeworkCompletionService.completedIdsNotifier.removeListener(_onCompletionChanged);
    _serverSubscription?.cancel(); // Не забываем отписаться
    super.dispose();
  }
  // Метод для загрузки ID группы пользователя из настроек
  Future<void> _loadUserGroupId() async {
    final groupId = settingsService.getDefaultGroupId();
    setState(() {
      _userGroupId = groupId;
    });
  }

  Future<void> _refreshHomework() async {
    // Принудительное обновление просто перезапускает логику загрузки
    _setupAndLoadData();
    if (mounted) setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0, // Скрываем стандартный AppBar
            bottom: TabBar(
              tabs: [
                const Tab(text: 'Актуальные'),
                Tab(
                  child: ValueListenableBuilder<int>(
                    valueListenable: homeworkCompletionService.overdueCountNotifier,
                    builder: (context, count, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Text('Просроченные', overflow: TextOverflow.ellipsis),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Badge(
                              label: Text(count.toString()),
                            ),
                          ],
                        ],
                      );
                    }
                  ),
                ),
                const Tab(text: 'Выполненные'),
              ],
            ),
          ),
          body: StreamBuilder<List<Homework>>(
            stream: _homeworkStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.none) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return RefreshIndicator(
                  onRefresh: _refreshHomework,
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Ошибка загрузки: ${snapshot.error}',
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }

              final allHomeworks = snapshot.data ?? [];
              final completedIds = homeworkCompletionService.getCompletedIds();

              // Фильтруем ДЗ только для группы пользователя
              final userHomeworks = allHomeworks
                  .where((hw) => _userGroupId == null || hw.group_id == _userGroupId)
                  .toList();

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final active = userHomeworks.where((hw) {
                final dueDate = DateTime(hw.due_date.year, hw.due_date.month, hw.due_date.day);
                return !completedIds.contains(hw.id) && (dueDate.isAtSameMomentAs(today) || dueDate.isAfter(today));
              }).toList();

              final overdue = userHomeworks.where((hw) {
                 final dueDate = DateTime(hw.due_date.year, hw.due_date.month, hw.due_date.day);
                return !completedIds.contains(hw.id) && dueDate.isBefore(today);
              }).toList();

              final completed = userHomeworks.where((hw) => completedIds.contains(hw.id)).toList();

              // Обновляем счетчик просроченных заданий в сервисе
              // Используем addPostFrameCallback, чтобы избежать ошибки "setState() called during build"
              SchedulerBinding.instance.addPostFrameCallback((_) {
                homeworkCompletionService.updateOverdueCount(overdue.length);
              });

              return TabBarView(
                children: [
                  _HomeworkList(
                    homeworks: active,
                    onRefresh: _refreshHomework,
                    emptyListMessage: 'Нет актуальных заданий.',
                    l10n: l10n,
                  ),
                  _HomeworkList(
                    homeworks: overdue,
                    onRefresh: _refreshHomework,
                    emptyListMessage: 'Нет просроченных заданий.',
                    l10n: l10n,
                  ),
                  _HomeworkList(
                    homeworks: completed,
                    onRefresh: _refreshHomework,
                    emptyListMessage: 'Нет выполненных заданий.',
                    l10n: l10n,
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeworkEditScreen()),
              );
            },
            tooltip: 'Добавить домашнее задание',
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class _HomeworkList extends StatelessWidget {
  final List<Homework> homeworks;
  final Future<void> Function() onRefresh;
  final String emptyListMessage;
  final AppLocalizations l10n;

  const _HomeworkList({
    required this.homeworks,
    required this.onRefresh,
    required this.emptyListMessage,
    required this.l10n,
  });

  bool _isDueDateToday(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    print(todayStart);
    final dueDatestart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    print(dueDatestart);
    return dueDatestart.isAtSameMomentAs(todayStart);
  }

  @override
  Widget build(BuildContext context) {
    if (homeworks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(getRandomEmoji(), style: TextStyle(fontSize: 72, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text(emptyListMessage, style: TextStyle(fontSize: 18, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: homeworks.length,
        itemBuilder: (context, index) {
          final entry = homeworks[index];
          final isCompleted = homeworkCompletionService.isCompleted(entry.id!);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: _isDueDateToday(entry.due_date)
                  ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)
                  : BorderSide.none,
            ),
            child: ListTile(
              leading: Checkbox(
                value: isCompleted,
                onChanged: (bool? value) {
                  homeworkCompletionService.toggleCompletionStatus(entry.id!);
                },
              ),
              title: Text(entry.discipline, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.task.length > 100 ? '${entry.task.substring(0, 100)}...' : entry.task,
                  ),
                  const SizedBox(height: 4.0),
                  Text('Срок сдачи: ${DateFormat('dd.MM.yyyy').format(entry.due_date)}'),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeworkViewScreen(homeworkEntry: entry),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
