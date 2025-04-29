import 'package:flutter/material.dart';
import '../models/homework.dart'; // Импортируем нашу модель Homework
// Возможно, понадобятся другие импорты позже (для DatePicker, выбора фото и т.д.)

class HomeworkEditScreen extends StatefulWidget {
  // Если будем использовать этот экран для РЕДАКТИРОВАНИЯ,
  // то здесь будет передаваться существующая запись о домашке
  final Homework? homeworkEntry;

  const HomeworkEditScreen({Key? key, this.homeworkEntry}) : super(key: key);

  @override
  _HomeworkEditScreenState createState() => _HomeworkEditScreenState();
}

class _HomeworkEditScreenState extends State<HomeworkEditScreen> {
  // --- Контроллеры для текстовых полей ---
  final _disciplineController = TextEditingController();
  final _groupController = TextEditingController();
  final _subgroupController = TextEditingController(); // Для подгруппы
  final _taskController = TextEditingController(); // Для текста ДЗ

  // --- Переменная для хранения выбранной даты сдачи ---
  DateTime _selectedDueDate = DateTime.now(); // По умолчанию - сегодня

  // --- Формовая ключ для валидации ---
  final _formKey = GlobalKey<FormState>(); // Помогает проверять корректность введенных данных

  // --- Инициализация состояния (если редактируем) ---
  @override
  void initState() {
    super.initState();
    // Если мы редактируем существующую запись, заполняем поля
    if (widget.homeworkEntry != null) {
      _disciplineController.text = widget.homeworkEntry!.discipline;
      _groupController.text = widget.homeworkEntry!.group;
      _subgroupController.text = widget.homeworkEntry!.subgroup ?? ''; // ?? '' - если subgroup null, ставим пустую строку
      _taskController.text = widget.homeworkEntry!.task;
      _selectedDueDate = widget.homeworkEntry!.dueDate;
      // TODO: Обработать фото, если они есть
    }
  }

  // --- Очистка контроллеров при удалении виджета ---
  @override
  void dispose() {
    _disciplineController.dispose();
    _subgroupController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  // --- Метод для выбора даты сдачи ---
  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate, // Начальная дата - текущая выбранная
      firstDate: DateTime.now(), // Нельзя выбрать дату в прошлом
      lastDate: DateTime(2101), // Достаточно далеко в будущем
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  // --- Метод для сохранения/обновления ДЗ ---
  void _saveHomework() {
    // Проверяем валидацию формы
    if (_formKey.currentState!.validate()) {
      // Если данные корректны, создаем объект Homework
      final newHomework = Homework(
        id: widget.homeworkEntry?.id, // Если редактируем, сохраняем старый ID
        discipline: _disciplineController.text,
        group: _groupController.text,
        subgroup: _subgroupController.text.isEmpty ? null : _subgroupController.text, // Если поле подгруппы пустое, сохраняем null
        task: _taskController.text,
        dueDate: _selectedDueDate,
        dateAdded: widget.homeworkEntry?.dateAdded ?? DateTime.now(), // Если редактируем, сохраняем старую дату добавления, иначе - текущую
        // TODO: Обработать photoUrls
      );

      // TODO: Здесь будем сохранять newHomework в Firebase!
      print('Сохраняем ДЗ: ${newHomework.toJson()}'); // Пока просто выводим в консоль
      Navigator.of(context).pop(); // Возвращаемся назад после сохранения
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homeworkEntry == null ? 'Добавить домашнее задание' : 'Редактировать домашнее задание'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form( // <-- Оборачиваем форму в виджет Form
          key: _formKey, // Присваиваем ключ формы
          child: ListView( // Используем ListView для прокрутки формы, если полей много
            children: [
              // --- Поле для ввода предмета ---
              TextFormField(
                controller: _disciplineController,
                decoration: const InputDecoration(labelText: 'Предмет'),
                validator: (value) { // Добавляем валидацию (обязательное поле)
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите предмет';
                  }
                  return null; // Если все хорошо, возвращаем null
                },
              ),
              const SizedBox(height: 12.0),

              // --- Поле для ввода подгруппы (опционально) ---
              TextFormField(
                controller: _subgroupController,
                decoration: const InputDecoration(labelText: 'Подгруппа (опционально)'),
                // Валидация не нужна, т.к. поле опциональное
              ),
              const SizedBox(height: 12.0),

              // --- Поле для ввода текста задания (TextArea) ---
              TextFormField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'Текст задания'),
                maxLines: null, // Позволяет тексту занимать несколько строк
                keyboardType: TextInputType.multiline, // Клавиатура для многострочного текста
                validator: (value) {
                   if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите текст задания';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),

              // --- Выбор срока сдачи ---
              ListTile(
                title: const Text('Срок сдачи'),
                subtitle: Text(
                  '${_selectedDueDate.day}.${_selectedDueDate.month}.${_selectedDueDate.year}', // Форматируем дату для отображения
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDueDate(context), // При нажатии открываем DatePicker
              ),
              const SizedBox(height: 20.0),

              // TODO: Добавить кнопку для выбора фото

              // --- Кнопка сохранения ---
              ElevatedButton(
                onPressed: _saveHomework, // При нажатии вызываем метод сохранения
                child: Text(widget.homeworkEntry == null ? 'Добавить' : 'Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}