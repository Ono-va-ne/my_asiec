import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';
import 'homework_edit_screen.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../services/local_homework_service.dart';
import '../services/settings_service.dart'; // Импортируем сервис настроек
import '../pages/homework_view_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _localHomeworkService = LocalHomeworkService();
  String? _userGroupId; // ID группы пользователя из настроек
  
  bool _isDueDateTodayOrFuture(DateTime dueDate) {
    final now = DateTime.now();
    // Создаем объекты DateTime, представляющие начало текущего дня и начало даты сдачи
    final todayStart = DateTime(now.year, now.month, now.day);
    final dueDateStart = DateTime(dueDate.year, dueDate.month, dueDate.day); // Игнорируем время в дате сдачи

    // Проверяем, является ли дата сдачи сегодня или позже сегодняшнего дня
    return dueDateStart.isAtSameMomentAs(todayStart) || dueDateStart.isAfter(todayStart);
  }

  @override
  void initState() {
    super.initState();
    _loadUserGroupId(); // Загружаем ID группы пользователя при инициализации
  }

  // Метод для загрузки ID группы пользователя из настроек
  Future<void> _loadUserGroupId() async {
    final groupId = settingsService.getDefaultGroupId();
    setState(() {
      _userGroupId = groupId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firebaseStream = _firestore.collection('homework').orderBy('dueDate').snapshots();
    final localStream = _localHomeworkService.getHomeworkStream();

    // --- Объединяем два потока в один! ---
    final combinedStream = Rx.combineLatest2<QuerySnapshot, List<Homework>, List<Homework>>( // <--- Используем combineLatest2!
      firebaseStream, // Первый поток (Firebase)
      localStream,    // Второй поток (Hive)
      (firebaseSnapshot, localHomeworks) { // Функция-комбинатор: принимает последние значения из обоих потоков
        // Преобразуем документы из Firebase в List<Homework>
        final firebaseHomeworks = firebaseSnapshot.docs.map((doc) {
          return Homework.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Объединяем списки: сначала локальные, потом из Firebase (или наоборот - как удобно)
        // Важно: нужно убедиться, что нет дубликатов, если одна и та же запись может быть и там, и там (в нашем случае такого быть не должно, т.к. isLocal флаг)
        final allHomeworks = [...localHomeworks, ...firebaseHomeworks]; // <--- Объединяем списки!

        // Возможно, сортируем объединенный список по дате сдачи
        allHomeworks.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // <--- Сортируем по дате сдачи

        return allHomeworks; // Возвращаем объединенный и отсортированный список
      },
    );
    return Scaffold(
      body: StreamBuilder<List<Homework>>(
        stream: combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
            return const Center(child: CircularProgressIndicator());
          }
          final homeworkEntries = snapshot.data ?? [];


          if (snapshot.hasError) {
            print("Ошибка при загрузке ДЗ: ${snapshot.error}");
            return Center(
                child: Text(
                    'Ошибка загрузки домашнего задания: ${snapshot.error}'));
          }

          if (homeworkEntries.isEmpty) {
            return const Center(child: Text('Домашних заданий пока нет.'));
          }

          // Фильтруем ДЗ по группе пользователя
          final filteredHomeworkEntries = homeworkEntries
              .where((entry) =>
                  (_userGroupId == null || (entry.groupId == _userGroupId)) &&
                  _isDueDateTodayOrFuture(entry.dueDate) 
              )
              .toList();

          if (filteredHomeworkEntries.isEmpty) {
            return const Center(
                child: Text(
                    'Домашних заданий для вашей группы пока нет.'));
          }

          return ListView.builder(
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
                            'Вы уверены, что хотите удалить это задание?'),
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
                   print('Начало onDismissed для ДЗ с ID: ${entry.id}, isLocal: ${entry.isLocal}'); // Отладка: начало Dismissed

                   if (entry.isLocal) {
                       // Удалить из Hive
                       print('  Вызываем удаление из Hive для ID: ${entry.id}'); // Отладка: вызываем Hive сервис
                       await _localHomeworkService.deleteHomework(entry.id!);
                       print('  Вызов удаления из Hive завершен.'); // Отладка: вызов завершен
                   } else {
                       // Удалить из Firebase
                       print('  Вызываем удаление из Firebase для ID: ${entry.id}'); // Отладка: вызываем Firebase
                        try {
                           await _firestore.collection('homework').doc(entry.id!).delete();
                           print('  Вызов удаления из Firebase завершен.'); // Отладка: вызов завершен
                        } catch (e) {
                           print("Ошибка при удалении УДАЛЕННОГО ДЗ из Firebase: $e");
                           // TODO: Обработать ошибку удаления
                        }
                   }
                   print('Конец onDismissed.'); // Отладка: конец Dismissed
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  elevation: 1.0,
                  child: ListTile(
                    title: Text(
                      entry.discipline,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.task.length > 100 // Проверяем длину строки
                            ? '${entry.task.substring(0, 100)}...' // Если больше 50, берем первые 50 и добавляем многоточие
                            : entry.task,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface)),
                        const SizedBox(height: 4.0),
                        Text(entry.group),
                        const SizedBox(height: 4.0),
                        Text(
                            'Срок сдачи: ${DateFormat('dd.MM.yyyy').format(entry.dueDate)}'),
                      ],
                    ),
                    trailing: Column( // Используем Column для вертикального расположения элементов
                      mainAxisSize: MainAxisSize.min, // Column занимает минимальную высоту
                      crossAxisAlignment: CrossAxisAlignment.end, 
                      children: [
                        // Отображаем подгруппу, если она есть
                        if (entry.subgroup != null)
                           Text(
                             'Подгр. ${entry.subgroup}',
                             style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline) // Уменьшаем шрифт для подгруппы
                           ),

                        // Если есть подгруппа И есть хотя бы одна иконка, добавляем небольшой вертикальный отступ
                        if (entry.subgroup != null && (entry.isLocal || (entry.photoUrls != null && entry.photoUrls!.isNotEmpty)))
                           const SizedBox(height: 4),

                        // Отображаем иконки (если они нужны) в горизонтальном ряду
                        if (entry.isLocal || (entry.photoUrls != null && entry.photoUrls!.isNotEmpty)) // Показываем Row с иконками только если хотя бы одна иконка нужна
                           Row(
                              mainAxisSize: MainAxisSize.min, // Row занимает минимальную ширину
                              children: [
                                 // Иконка для локального ДЗ
                                 if (entry.isLocal) // Показываем, если запись локальная
                                    Icon(
                                       Icons.phone_android, // Или Icons.sd_storage, Icons.smartphone - какая больше нравится
                                       size: 18, // Размер иконки
                                       color: Theme.of(context).colorScheme.primary, // Цвет иконки
                                    ),

                                 // Если есть иконка локального ДЗ И иконка фото, добавляем горизонтальный отступ
                                 if (entry.isLocal && (entry.photoUrls != null && entry.photoUrls!.isNotEmpty))
                                    const SizedBox(width: 4), // Небольшой горизонтальный отступ

                                 // Иконка для ДЗ с фотографиями
                                 if (entry.photoUrls != null && entry.photoUrls!.isNotEmpty) // Показываем, если есть фото
                                    Icon(
                                       Icons.image, // Или Icons.photo
                                       size: 18, // Размер иконки
                                       color: Theme.of(context).colorScheme.primary, // Цвет иконки
                                    ),
                              ],
                           ),
                      ],
                    ),
                    onTap: () {
                      print('Нажали на ДЗ: ${entry.discipline}, groupId: ${entry.groupId}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeworkViewScreen( // <--- ОТКРЫВАЕМ ЭКРАН ПРОСМОТРА!
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const HomeworkEditScreen()),
          );
        },
        tooltip: 'Добавить домашнее задание',
        child: const Icon(Icons.add),
      ),
    );
  }
}
