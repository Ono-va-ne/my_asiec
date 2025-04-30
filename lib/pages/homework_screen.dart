import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';
import 'homework_edit_screen.dart';
import 'package:intl/intl.dart';
import '../services/settings_service.dart'; // Импортируем сервис настроек

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _firestore = FirebaseFirestore.instance;
  String? _userGroupId; // ID группы пользователя из настроек

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
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('homework').orderBy('dueDate').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Ошибка при загрузке ДЗ: ${snapshot.error}");
            return Center(
                child: Text(
                    'Ошибка загрузки домашнего задания: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Домашних заданий пока нет.'));
          }

          // Фильтруем ДЗ по группе пользователя
          final filteredHomeworkEntries = snapshot.data!.docs
              .map((doc) => Homework.fromJson(
                  doc.data() as Map<String, dynamic>, doc.id))
              .where((entry) =>
                  _userGroupId == null || entry.groupId == _userGroupId)
              .toList();

          // Если после фильтрации нет ДЗ, показываем сообщение
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
                  print('Удаляем ДЗ с ID: ${entry.id}');
                  try {
                    await _firestore
                        .collection('homework')
                        .doc(entry.id)
                        .delete();
                    print('ДЗ успешно удалено!');
                  } catch (e) {
                    print("Ошибка при удалении ДЗ из Firebase: $e");
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  elevation: 1.0,
                  child: ListTile(
                    title: Text(
                      entry.task,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.discipline,
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
                    trailing: entry.subgroup != null
                        ? Text('Подгр. ${entry.subgroup}')
                        : null,
                    onTap: () {
                      print('Нажали на ДЗ: ${entry.discipline}, groupId: ${entry.groupId}');
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeworkEditScreen(homeworkEntry: entry),
                          ));
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
