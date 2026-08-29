import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../models/homework.dart';
import '../homework_edit_screen.dart';
import 'package:intl/intl.dart';
import '../../services/local_homework_service.dart';
import '../../services/settings_service.dart'; // Импортируем сервис настроек
import '../../l10n/app_localizations.dart';
import '../../services/homework_completion_service.dart';
import '../../data/text_emojis.dart';
import '../homework_view_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  HomeworkScreenState createState() => HomeworkScreenState();
}

class HomeworkScreenState extends State<HomeworkScreen> {
  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  String? _userGroupId; // ID группы пользователя из настроек
  Stream<List<Homework>>? _homeworkStream;
  StreamSubscription? _serverSubscription;

  @override
  void initState() {
    super.initState();
    // Слушаем изменения в ID группы и статусах выполнения
    settingsService.defaultGroupIdNotifier.addListener(_setupAndLoadData);
    homeworkCompletionService.completedIdsNotifier.addListener(
      _onCompletionChanged,
    );

    // Первоначальная загрузка
    _setupAndLoadData();
  }

  void _setupAndLoadData() {
    _loadUserGroupId();

    // Отменяем старую подписку на сервер, если она была
    _serverSubscription?.cancel();

    // Основной поток данных для UI теперь идет из локального сервиса (кэш + локальные)
    _homeworkStream = _localHomeworkService.getHomeworkStream().map((
      homeworks,
    ) {
      homeworks.sort((a, b) => a.due_date.compareTo(b.due_date));
      return homeworks;
    });

    // В фоне подписываемся на сервер для обновления кэша
    final serverStream = _client
        .from('homework')
        .stream(primaryKey: ['id'])
        .order('due_date');

    _serverSubscription = serverStream
        .timeout(const Duration(seconds: 5)) // Добавляем таймаут
        .listen(
          (data) {
            final serverHomeworks =
                (data as List)
                    .map(
                      (row) => Homework.fromJson(
                        row as Map<String, dynamic>,
                        (row['id'] ?? '').toString(),
                      ),
                    )
                    .toList();
            // Кэшируем успешные данные
            _localHomeworkService.cacheServerHomework(serverHomeworks);
          },
          onError: (error) {
            // При ошибке или таймауте просто логируем ее.
            // UI продолжит показывать данные из кэша.
            print("Ошибка или таймаут при получении данных с сервера: $error");
          },
        );

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
    homeworkCompletionService.completedIdsNotifier.removeListener(
      _onCompletionChanged,
    );
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Ошибка загрузки: ${snapshot.error}'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            final allHomeworks = snapshot.data ?? [];
            final completedIds = homeworkCompletionService.getCompletedIds();

            final userHomeworks =
                allHomeworks
                    .where(
                      (hw) =>
                          _userGroupId == null || hw.group_id == _userGroupId,
                    )
                    .toList();

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final active =
                userHomeworks.where((hw) {
                  final dueDate = DateTime(
                    hw.due_date.year,
                    hw.due_date.month,
                    hw.due_date.day,
                  );
                  return !completedIds.contains(hw.id) &&
                      (dueDate.isAtSameMomentAs(today) ||
                          dueDate.isAfter(today));
                }).toList();

            final overdue =
                userHomeworks.where((hw) {
                  final dueDate = DateTime(
                    hw.due_date.year,
                    hw.due_date.month,
                    hw.due_date.day,
                  );
                  return !completedIds.contains(hw.id) &&
                      dueDate.isBefore(today);
                }).toList();

            final completed =
                userHomeworks
                    .where((hw) => completedIds.contains(hw.id))
                    .toList();
            final pending = [...active, ...overdue]
              ..sort((a, b) => a.due_date.compareTo(b.due_date));

            SchedulerBinding.instance.addPostFrameCallback((_) {
              homeworkCompletionService.updateOverdueCount(overdue.length);
            });

            return RefreshIndicator(
              onRefresh: _refreshHomework,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HomeworkSectionCard(
                    title: 'Активные',
                    homeworks: pending,
                    emptyMessage: 'Ура! Все задачи выполнены.',
                    l10n: l10n,
                    isHappy: true,
                  ),
                  const SizedBox(height: 16),
                  _HomeworkSectionCard(
                    title: 'Выполненные',
                    homeworks: completed,
                    emptyMessage: 'Нет выполненных заданий.',
                    l10n: l10n,
                    isHappy: false,
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'homework_fab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeworkEditScreen(),
              ),
            );
          },
          tooltip: 'Добавить домашнее задание',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _HomeworkSectionCard extends StatelessWidget {
  final String title;
  final List<Homework> homeworks;
  final String emptyMessage;
  final AppLocalizations l10n;
  final bool isHappy;

  const _HomeworkSectionCard({
    required this.title,
    required this.homeworks,
    required this.emptyMessage,
    required this.l10n,
    required this.isHappy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        shape: RoundedRectangleBorder(side: BorderSide.none),
        initiallyExpanded: isHappy,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          if (homeworks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: [
                    Text(
                      isHappy ? getRandomEmoji(Happy) : getRandomEmoji(Sad),
                      style: TextStyle(fontSize: 42, color: Theme.of(context).colorScheme.onSurface.withAlpha(155)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(155)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: homeworks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = homeworks[index];
                final isCompleted = homeworkCompletionService.isCompleted(entry.id!);

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(0),
                    leading: Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: isCompleted,
                      onChanged: (bool? value) {
                        homeworkCompletionService.toggleCompletionStatus(entry.id!);
                      },
                    ),
                    title: Text(
                      entry.discipline,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.task.length > 100
                              ? '${entry.task.substring(0, 100)}...'
                              : entry.task,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: !isCompleted && _isDueDateYesterday(entry.due_date)
                                  ? Theme.of(context).colorScheme.error
                                  : !isCompleted && _isDueDateToday(entry.due_date)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd.MM.yyyy').format(entry.due_date),
                              style: TextStyle(
                                color: !isCompleted && _isDueDateYesterday(entry.due_date)
                                    ? Theme.of(context).colorScheme.error
                                    : !isCompleted && _isDueDateToday(entry.due_date)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                fontWeight: _isDueDateToday(entry.due_date) ||
                                        _isDueDateYesterday(entry.due_date)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
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
        ],
      ),
    );
  }
  bool _isDueDateToday(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueDatestart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDatestart.isAtSameMomentAs(todayStart);
  }

  bool _isDueDateYesterday(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueDatestart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDatestart.compareTo(todayStart) < 0;
  }
}
