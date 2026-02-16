import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/homework.dart';
import '../homework_edit_screen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../services/local_homework_service.dart';
import '../../services/settings_service.dart'; // Импортируем сервис настроек
import '../homework_view_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  String? _userGroupId; // ID группы пользователя из настроек
  Stream<List<Homework>>? _combinedStream;

  bool _isdue_dateTodayOrFuture(DateTime dueDate) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueDatestart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDatestart.isAtSameMomentAs(todayStart) || dueDatestart.isAfter(todayStart);
  }

  @override
  void initState() {
    super.initState();
    _setupAndLoadData();
  }

  void _setupAndLoadData() {
    _loadUserGroupId();
    final firebaseStream = _client
        .from('homework')
        .stream(primaryKey: ['id'])
        .order('due_date')
        .map((rows) => (rows as List)
            .map((row) => Homework.fromJson(
                row as Map<String, dynamic>, (row['id'] ?? '').toString()))
            .toList());
    final localStream = _localHomeworkService.getHomeworkStream();

    _combinedStream = Rx.combineLatest2<List<Homework>, List<Homework>,
        List<Homework>>(firebaseStream, localStream,
        (firebaseHomeworks, localHomeworks) {
      final allHomeworks = [...localHomeworks, ...firebaseHomeworks];
      allHomeworks.sort((a, b) => a.due_date.compareTo(b.due_date));
      return allHomeworks;
    });
    if (mounted) setState(() {});
  }

  // Метод для загрузки ID группы пользователя из настроек
  Future<void> _loadUserGroupId() async {
    final groupId = settingsService.getDefaultGroupId();
    setState(() {
      _userGroupId = groupId;
    });
  }

  Future<void> _refreshHomework() async {
    // В данном случае потоки обновляются автоматически.
    // Мы можем просто подождать немного для имитации загрузки
    // и чтобы дать время потокам синхронизироваться, если есть задержки.
    _loadUserGroupId();
    final firebaseStream = _client
        .from('homework')
        .stream(primaryKey: ['id'])
        .order('due_date')
        .map((rows) => (rows as List)
            .map((row) => Homework.fromJson(
                row as Map<String, dynamic>, (row['id'] ?? '').toString()))
            .toList());
    final localStream = _localHomeworkService.getHomeworkStream();

    _combinedStream = Rx.combineLatest2<List<Homework>, List<Homework>,
        List<Homework>>(firebaseStream, localStream,
        (firebaseHomeworks, localHomeworks) {
      final allHomeworks = [...localHomeworks, ...firebaseHomeworks];
      allHomeworks.sort((a, b) => a.due_date.compareTo(b.due_date));
      return allHomeworks;
    });
    if (mounted) setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Homework>>(
        stream: _combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.none) {
            return const Center(child: CircularProgressIndicator());
          }
          final homeworkEntries = snapshot.data ?? [];

          if (snapshot.hasError) {
            print("Ошибка при загрузке ДЗ: ${snapshot.error}");
            return Center(
              child: Text(
                'Ошибка загрузки домашнего задания: ${snapshot.error}',
              ),
            );
          }

          if (homeworkEntries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshHomework,
              // child:
              //     const Center(child: Text('Домашних заданий пока нет.')),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(child: Text('Домашних заданий пока нет.')),
                  ),
                );
              }),
            );
          }

          // Фильтруем ДЗ по группе пользователя
          final filteredHomeworkEntries =
              homeworkEntries
                  .where(
                    (entry) =>
                        (_userGroupId == null ||
                            (entry.group_id == _userGroupId)) &&
                        _isdue_dateTodayOrFuture(entry.due_date),
                  )
                  .toList();

          if (filteredHomeworkEntries.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshHomework,
              // child: const Center(
              //   child: Text('Домашних заданий для вашей группы пока нет.'),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Text('Домашних заданий для вашей группы пока нет.'),
                    ),
                  ),
                );
              }),
              // ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshHomework,
            child: ListView.builder(
            itemCount: filteredHomeworkEntries.length,
            itemBuilder: (context, index) {
              final entry = filteredHomeworkEntries[index];

              return Dismissible(
                key: Key(entry.id!),
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Подтверждение'),
                        content: const Text(
                          'Вы уверены, что хотите удалить это задание?',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Нет'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Да'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  print(
                    'Начало onDismissed для ДЗ с ID: ${entry.id}, isLocal: ${entry.isLocal}',
                  ); // Отладка: начало Dismissed

                  if (entry.isLocal) {
                    // Удалить из Hive
                    print(
                      '  Вызываем удаление из Hive для ID: ${entry.id}',
                    ); // Отладка: вызываем Hive сервис
                    await _localHomeworkService.deleteHomework(entry.id!);
                    print(
                      '  Вызов удаления из Hive завершен.',
                    ); // Отладка: вызов завершен
                  } else {
                    // Удалить из Supabase
                    print(
                      '  Вызываем удаление из Supabase для ID: ${entry.id}',
                    );
                    try {
                      await _client
                          .from('homework')
                          .delete()
                          .eq('id', entry.id!);
                      print('  Вызов удаления из Supabase завершен.');
                    } catch (e) {
                      print(
                        "Ошибка при удалении УДАЛЕННОГО ДЗ из Supabase: $e",
                      );
                    }
                  }
                  print('Конец onDismissed.'); // Отладка: конец Dismissed
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  elevation: 1.0,
                  child: ListTile(
                    title: Text(
                      entry.discipline,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.task.length >
                                  100 // Проверяем длину строки
                              ? '${entry.task.substring(0, 100)}...'
                              : entry.task,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(entry.group),
                        const SizedBox(height: 4.0),
                        Text(
                          'Срок сдачи: ${DateFormat('dd.MM.yyyy').format(entry.due_date)}',
                        ),
                      ],
                    ),
                    trailing: Column(
                      // Используем Column для вертикального расположения элементов
                      mainAxisSize:
                          MainAxisSize
                              .min, // Column занимает минимальную высоту
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Отображаем подгруппу, если она есть
                        if (entry.subgroup != null)
                          Text(
                            'Подгр. ${entry.subgroup}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ), // Уменьшаем шрифт для подгруппы
                          ),

                        // Если есть подгруппа И есть хотя бы одна иконка, добавляем небольшой вертикальный отступ
                        if (entry.subgroup != null &&
                            (entry.isLocal ||
                                (entry.photo_urls != null &&
                                    entry.photo_urls!.isNotEmpty)))
                          const SizedBox(height: 4),

                        // Отображаем иконки (если они нужны) в горизонтальном ряду
                        if (entry.isLocal ||
                            (entry.photo_urls != null &&
                                entry
                                    .photo_urls!
                                    .isNotEmpty)) // Показываем Row с иконками только если хотя бы одна иконка нужна
                          Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min, // Row занимает минимальную ширину
                            children: [
                              // Иконка для локального ДЗ
                              if (entry
                                  .isLocal) // Показываем, если запись локальная
                                Icon(
                                  Icons
                                      .phone_android, // Или Icons.sd_storage, Icons.smartphone - какая больше нравится
                                  size: 18, // Размер иконки
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary, // Цвет иконки
                                ),

                              // Если есть иконка локального ДЗ И иконка фото, добавляем горизонтальный отступ
                              if (entry.isLocal &&
                                  (entry.photo_urls != null &&
                                      entry.photo_urls!.isNotEmpty))
                                const SizedBox(
                                  width: 4,
                                ), // Небольшой горизонтальный отступ
                              // Иконка для ДЗ с фотографиями
                              if (entry.photo_urls != null &&
                                  entry
                                      .photo_urls!
                                      .isNotEmpty) // Показываем, если есть фото
                                Icon(
                                  Icons.image, // Или Icons.photo
                                  size: 18, // Размер иконки
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary, // Цвет иконки
                                ),
                            ],
                          ),
                      ],
                    ),
                    onTap: () {
                      print(
                        'Нажали на ДЗ: ${entry.discipline}, group_id: ${entry.group_id}',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => HomeworkViewScreen(
                                // <--- ОТКРЫВАЕМ ЭКРАН ПРОСМОТРА!
                                homeworkEntry: entry,
                              ),
                        ),
                      );
                      print('Нажали на ДЗ: ${entry.discipline}');
                    },
                  ),
                ),
              );
            },
          ));
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
    );
  }
}
