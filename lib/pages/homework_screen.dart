import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart'; // Импортируем нашу модель Homework
import 'homework_edit_screen.dart'; // Импортируем экран добавления/редактирования ДЗ
import 'package:intl/intl.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _firestore = FirebaseFirestore.instance;
  // TODO: добавить отображение только своей группы
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
// --- Используем StreamBuilder для отслеживания изменений в коллекции ---
          StreamBuilder<QuerySnapshot>( // <--- StreamBuilder ожидает QuerySnapshot из Firestore
        stream: _firestore.collection('homework').orderBy('dueDate').snapshots(), // <--- ПОТОК ДАННЫХ: получаем snapshot коллекции 'homework', сортируем по dueDate
        builder: (context, snapshot) {
          // --- Проверяем состояние соединения ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Показываем индикатор загрузки, пока данные грузятся
          }

          // --- Проверяем наличие ошибок ---
          if (snapshot.hasError) {
            print("Ошибка при загрузке ДЗ: ${snapshot.error}"); // Логгируем ошибку
            return Center(child: Text('Ошибка загрузки домашнего задания: ${snapshot.error}')); // Показываем сообщение об ошибке пользователю
          }

          // --- Проверяем наличие данных ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Домашних заданий пока нет.')); // Если данных нет или список пуст
          }

          // --- Если данные есть, преобразуем их и отображаем в списке ---
          final homeworkEntries = snapshot.data!.docs.map((doc) {
            // Для каждого документа (doc) в QuerySnapshot:
            // 1. Получаем данные документа (doc.data())
            // 2. Создаем объект Homework из этих данных, передавая сам документ (doc) для получения ID
            return Homework.fromJson(doc.data() as Map<String, dynamic>, doc.id); // <--- Используем наш fromJson!
          }).toList(); // Преобразуем результат в List<Homework>

          // --- Отображаем список домашнего задания ---
          return ListView.builder(
            itemCount: homeworkEntries.length,
            itemBuilder: (context, index) {
              final entry = homeworkEntries[index]; // Получаем объект Homework для текущего элемента списка

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
                        content: const Text('Вы уверены, что хотите удалить это задание?'),
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
                  print('Удаляем ДЗ с ID: ${entry.id}'); // Отладочный вывод
                  try {
                    await _firestore.collection('homework').doc(entry.id).delete();
                    print('ДЗ успешно удалено!');
                  } catch (e) {
                    print("Ошибка при удалении ДЗ из Firebase: $e"); // Логгируем ошибку
                  }
                },
                child: Card( // Оборачиваем в Card для лучшего вида
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Уменьшаем вертикальный отступ
                  elevation: 1.0, // Небольшая тень
                  child: ListTile( // Используем ListTile для элемента списка
                    title: Text(entry.task, style: TextStyle(fontWeight: FontWeight.bold),), // Заголовок - Предмет
                    subtitle: Column( // Подзаголовок - Срок сдачи и текст задания
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.discipline, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), // Текст задания
                        const SizedBox(height: 4.0),
                        Text(entry.group),
                        const SizedBox(height: 4.0),
                        Text('Срок сдачи: ${DateFormat('dd.MM.yyyy').format(entry.dueDate)}'), // Форматируем и отображаем срок сдачи
                      ],
                    ),
                    trailing: entry.subgroup != null ? Text('Подгр. ${entry.subgroup}') : null, // Отображаем подгруппу, если есть
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeworkEditScreen(homeworkEntry: entry),
                        )
                      );
                      // TODO: Реализовать переход на экран редактирования при нажатии
                       print('Нажали на ДЗ: ${entry.discipline}');
                    },
                    // TODO: Возможно, добавить GestureDetector или Dismissible для удаления по свайпу
                  ),
                ),
              );
            },
          );
        },
      ),
      // --- Вот наш FAB для добавления ДЗ! ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // При нажатии на FAB, открываем экран добавления/редактирования ДЗ
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