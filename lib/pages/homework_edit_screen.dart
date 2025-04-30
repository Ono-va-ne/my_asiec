import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework.dart';
import '../data/groups.dart'; // Импортируем файл с данными групп
// Импортируем нашу модель Homework
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
  final _firestore = FirebaseFirestore.instance;
  // --- Контроллеры для текстовых полей ---
  final _disciplineController = TextEditingController();
  //final _groupController = TextEditingController(); // Убираем контроллер для группы
  final _subgroupController = TextEditingController(); // Для подгруппы
  final _taskController = TextEditingController(); // Для текста ДЗ

  // --- Переменная для хранения выбранной даты сдачи ---
  DateTime _selectedDueDate = DateTime.now(); // По умолчанию - сегодня

  // --- Формовая ключ для валидации ---
  final _formKey = GlobalKey<FormState>(); // Помогает проверять корректность введенных данных

  // --- Переменные для работы с группами ---
  List<Map<String, dynamic>> _groups = []; // Список групп (теперь храним Map)
  String? _selectedGroupId; // Выбранный ID группы
  String? _selectedGroupName; // Выбранное имя группы

  // --- Инициализация состояния (если редактируем) ---
  @override
  void initState() {
    super.initState();
    _fetchGroups(); // Загружаем список групп при инициализации
    // Если мы редактируем существующую запись, заполняем поля
    if (widget.homeworkEntry != null) {
      _disciplineController.text = widget.homeworkEntry!.discipline;
      //_groupController.text = widget.homeworkEntry!.group; // Больше не используем контроллер
      _selectedGroupId = widget.homeworkEntry!.groupId; // Устанавливаем выбранный ID группы
      _selectedGroupName = widget.homeworkEntry!.group; // Устанавливаем имя группы
      _subgroupController.text = widget.homeworkEntry!.subgroup ??
          ''; // ?? '' - если subgroup null, ставим пустую строку
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
  void _saveHomework() async {
    // Проверяем валидацию формы
    if (_formKey.currentState!.validate()) {
      // Проверяем, что группа выбрана
      if (_selectedGroupId == null || _selectedGroupName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, выберите группу')),
        );
        return;
      }

      // Если данные корректны, создаем объект Homework
      final homeworkToSave = Homework(
        id: widget.homeworkEntry?.id, // Если редактируем, сохраняем старый ID
        discipline: _disciplineController.text.trim(),
        group: _selectedGroupName!, // Используем выбранное имя группы
        groupId: _selectedGroupId!, // Используем выбранный ID группы
        subgroup: _subgroupController.text.trim().isEmpty
            ? null
            : _subgroupController.text.trim(), // Если поле подгруппы пустое, сохраняем null
        task: _taskController.text.trim(),
        dueDate: _selectedDueDate,
        dateAdded: widget.homeworkEntry?.dateAdded ??
            DateTime.now(), // Если редактируем, сохраняем старую дату добавления, иначе - текущую
        photoUrls: widget.homeworkEntry?.photoUrls,
        // TODO: Обработать photoUrls
      );

      // --- ЛОГИКА СОХРАНЕНИЯ В FIREBASE ---
      try {
        if (homeworkToSave.id == null) {
          // --- Добавляем новое задание ---
          print(
              'Добавляем новое ДЗ в Firebase: ${homeworkToSave.toJson()}'); // Отладочный вывод
          await _firestore
              .collection('homework')
              .add(homeworkToSave.toJson()); // <--- КЛЮЧЕВАЯ СТРОКА для добавления!
          print('Новое ДЗ успешно добавлено!');
        } else {
          // --- Редактируем существующее задание ---
          print('Редактируем ДЗ с ID: ${homeworkToSave.id}'); // Отладочный вывод
          await _firestore
              .collection('homework')
              .doc(homeworkToSave.id)
              .update(homeworkToSave.toJson()); // <--- КЛЮЧЕВАЯ СТРОКА для обновления!
          print('ДЗ успешно обновлено!');
        }

        // TODO: Возможно, показать SnackBar или другое сообщение об успехе
        if (mounted) {
          // Проверяем, что виджет все еще "жив"
          Navigator.of(context).pop();
        }
      } catch (e) {
        print("Ошибка при сохранении ДЗ в Firebase: $e"); // Логгируем ошибку
        // TODO: Показать пользователю сообщение об ошибке
        if (mounted) {
          // Возможно, показать AlertDialog или SnackBar с ошибкой
        }
      }
    }
  }

  // --- Метод для загрузки списка групп из Firebase ---
Future<void> _fetchGroups() async {
    try {
      final querySnapshot = await _firestore.collection('groups').get();
      final groupsMap = <String, String>{};
      for (final doc in querySnapshot.docs) {
        groupsMap[doc.id] = doc.get('name');
      }

      final sortedGroups = availableGroupsData.map((groupInfo) {
        return {
          'id': groupInfo.id,
          'name': groupInfo.name,
        };
      }).toList();

      final filteredAndSortedGroups = sortedGroups.where((group) => groupsMap.containsKey(group['id'])).toList();

      if (!mounted) return; // Проверка на mounted
      setState(() {
        _groups = filteredAndSortedGroups;
        print("_groups: $_groups");
        if (_groups.isNotEmpty && _selectedGroupId == null && widget.homeworkEntry == null) {
          _selectedGroupId = _groups[0]['id'];
          _selectedGroupName = _groups[0]['name'];
        } else if (widget.homeworkEntry != null && _groups.isNotEmpty) {
          final selectedGroup = _groups.firstWhere(
                  (group) => group['id'] == widget.homeworkEntry!.groupId,
              orElse: () => {'id': null, 'name': null});

          _selectedGroupName = selectedGroup['name'];
          _selectedGroupId = selectedGroup['id'];
                }
      });
    } catch (e) {
      print("Ошибка при загрузке групп: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки групп: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.homeworkEntry == null
            ? 'Добавить домашнее задание'
            : 'Редактировать домашнее задание'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          // <-- Оборачиваем форму в виджет Form
          key: _formKey, // Присваиваем ключ формы
          child: ListView(
            // Используем ListView для прокрутки формы, если полей много
            children: [
              // --- Поле для ввода предмета ---
              TextFormField(
                controller: _disciplineController,
                decoration: const InputDecoration(labelText: 'Предмет'),
                validator: (value) {
                  // Добавляем валидацию (обязательное поле)
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите предмет';
                  }
                  return null; // Если все хорошо, возвращаем null
                },
              ),
              const SizedBox(height: 12.0),
              // --- Выпадающий список для выбора группы ---
              DropdownButtonFormField<String>(
                value: _selectedGroupName,
                decoration: const InputDecoration(labelText: 'Группа'),
                items: _groups.map((Map<String, dynamic> group) {
                  return DropdownMenuItem<String>(
                    value: group['name'],
                    child: Text(group['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGroupName = newValue;
                    _selectedGroupId = _groups.firstWhere((group) => group['name'] == newValue)['id'];
                    print("_selectedGroupId: $_selectedGroupId"); // <--- Добавили вывод
                    print("_selectedGroupName: $_selectedGroupName"); // <--- Добавили вывод
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, выберите группу';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),

              // --- Поле для ввода подгруппы (опционально) ---
              TextFormField(
                controller: _subgroupController,
                decoration:
                    const InputDecoration(labelText: 'Подгруппа (опционально)'),
                // Валидация не нужна, т.к. поле опциональное
              ),
              const SizedBox(height: 12.0),

              // --- Поле для ввода текста задания (TextArea) ---
              TextFormField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'Текст задания'),
                maxLines: null, // Позволяет тексту занимать несколько строк
                keyboardType:
                    TextInputType.multiline, // Клавиатура для многострочного текста
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
                child: Text(widget.homeworkEntry == null
                    ? 'Добавить'
                    : 'Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
