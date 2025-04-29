import 'package:flutter/material.dart';
import 'homework_edit_screen.dart'; // Импортируем экран добавления/редактирования ДЗ
// Позже здесь будут импорты Firebase и модели Homework

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  _HomeworkScreenState createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  // TODO: Здесь будет логика загрузки и отображения списка домашнего задания из Firebase

  @override
  void initState() {
    super.initState();
    // TODO: Запустить загрузку данных из Firebase при инициализации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center( // Пока что просто заглушка в центре экрана
        child: Text('Здесь будет список домашнего задания'),
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