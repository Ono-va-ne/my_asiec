import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/homework.dart';
import '../services/local_homework_service.dart';
import '../data/groups.dart'; 
import '../services/settings_service.dart'; // Импортируем SettingsService

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
  final _localHomeworkService = LocalHomeworkService();
  final _disciplineController = TextEditingController();
  final _subgroupController = TextEditingController(); 
  final _taskController = TextEditingController(); 
  DateTime _selectedDueDate = DateTime.now();
  bool _saveLocally = false;
  final _formKey = GlobalKey<FormState>();
  List<XFile> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _groups = []; // Список групп (теперь храним Map)
  String? _selectedGroupId; // Выбранный ID группы
  String? _selectedGroupName; // Выбранное имя группы

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    if (widget.homeworkEntry != null) {
      _disciplineController.text = widget.homeworkEntry!.discipline;
      _selectedGroupId = widget.homeworkEntry!.groupId; 
      _subgroupController.text = widget.homeworkEntry!.subgroup ?? '';
      _taskController.text = widget.homeworkEntry!.task;
      _selectedDueDate = widget.homeworkEntry!.dueDate;
      // TODO: Обработать фото, если они есть
    } else {
      // Если это добавление новой домашки, проверяем настройки
      final defaultGroupId = settingsService.getDefaultGroupId();
      if (defaultGroupId != null) {
        _selectedGroupId = defaultGroupId;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_groups.isNotEmpty && _selectedGroupId != null && _selectedGroupName == null) {
      _selectedGroupName = _groups.firstWhere((group) => group['id'] == _selectedGroupId)['name'];
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

  Future<void> _pickImages() async {
    // Открываем диалог выбора нескольких изображений из галереи
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _selectedPhotos = pickedFiles; // Обновляем список выбранных фото
      });
    }
  }

  Future<List<String>> _savePhotosLocally(List<XFile> photos) async {
   List<String> localPaths = []; // Список для хранения путей к локальным файлам

   try {
     // Получаем каталог для хранения документов приложения
     final directory = await getApplicationDocumentsDirectory(); // <--- Используем path_provider!
     final homeworkPhotosDir = Directory('${directory.path}/homework_photos'); // Создаем подпапку для фото ДЗ

     // Убедимся, что папка существует
     if (!await homeworkPhotosDir.exists()) {
       await homeworkPhotosDir.create(recursive: true); // Создаем папку, если ее нет
     }

     for (final photoFile in photos) {
       // Генерируем уникальное имя файла (можно использовать ID ДЗ + уникальный ID фото)
       // Для простоты пока используем уникальный ID + расширение
       final String photoId = const Uuid().v4();
       final String fileExtension = photoFile.name.split('.').last;
       final String newFileName = '$photoId.$fileExtension';
       final String newFilePath = '${homeworkPhotosDir.path}/$newFileName'; // Полный путь к новому файлу

       // Копируем файл из временного пути (XFile) в нашу папку
       final File newFile = await File(photoFile.path).copy(newFilePath); // <--- Копируем файл!
       if (!mounted) return [];

       localPaths.add(newFile.path); // Добавляем путь к новому файлу в список

       print('Фото ${photoFile.name} успешно сохранено локально по пути: ${newFile.path}');
     }
   } catch (e) {
     print("Ошибка при сохранении фото локально: $e");
     // TODO: Обработать ошибку сохранения конкретного фото
   }

   return localPaths; // Возвращаем список путей к локальным файлам
}

  // --- Метод для сохранения/обновления ДЗ ---
  void _saveHomework() async {
    // Проверяем валидацию формы
    if (_formKey.currentState!.validate()) {
      List<String> processedPhotoUrlsOrPaths = [];
      // Проверяем, что группа выбрана
      if (_selectedGroupId == null || _selectedGroupName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, выберите группу')),
        );
        return;
      }
      final isAdding = widget.homeworkEntry == null;
      final bool shouldSaveLocally = isAdding ? _saveLocally : widget.homeworkEntry!.isLocal;

      if (_selectedPhotos.isNotEmpty) { // Если пользователь выбрал новые фото
         if (shouldSaveLocally) {
           // --- Сохраняем фото ЛОКАЛЬНО (для Hive) ---
           print('Сохраняем фото ЛОКАЛЬНО...');
           processedPhotoUrlsOrPaths = await _savePhotosLocally(_selectedPhotos); // <--- ВЫЗЫВАЕМ НАШ РЕАЛИЗОВАННЫЙ МЕТОД!
           print('Фото успешно сохранены локально.');
         } else {
           // --- ДЛЯ УДАЛЕННЫХ (Firebase): Фото сейчас не поддерживаются из-за Blaze плана ---
           print('Фото для удаленных записей временно не поддерживаются из-за ограничений Blaze плана.');
           //processedPhotoUrlsOrPaths = await _uploadPhotosToFirebaseStorage(_selectedPhotos); // ЭТОТ МЕТОД ВЫЗЫВАТЬ НЕ БУДЕМ!
         }
      }

      // Если мы редактируем запись, и у нее уже были фото, добавляем их к новым.
      // TODO: Обработать случай удаления фото при редактировании!
      // Объединяем старые и новые URLы/пути. Важно: сохраняем только те URLы/пути, которые были изначально (при редактировании)
      // ПЛЮС новые, которые мы только что обработали.
      // Если мы редактируем локальную запись, photoUrls - это пути. Если удаленную, это URLы.
      List<String> finalPhotoUrlsOrPaths = [];
      // Добавляем старые пути/URLы из существующей записи (если редактируем)
      if (widget.homeworkEntry?.photoUrls != null) {
         finalPhotoUrlsOrPaths.addAll(widget.homeworkEntry!.photoUrls!);
      }
      // Добавляем новые пути/URLы, которые мы только что обработали
      finalPhotoUrlsOrPaths.addAll(processedPhotoUrlsOrPaths);

      // Если данные корректны, создаем объект Homework
      final homeworkToProcess = Homework(
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
        photoUrls: finalPhotoUrlsOrPaths.isEmpty ? null : finalPhotoUrlsOrPaths,
        isLocal: widget.homeworkEntry?.isLocal ?? _saveLocally,
      );

      // --- ЛОГИКА СОХРАНЕНИЯ В FIREBASE ---
      try {
        if (homeworkToProcess.isLocal) {
          // --- Сохраняем/обновляем ЛОКАЛЬНО (в Hive) ---
          print('Сохраняем/обновляем ЛОКАЛЬНО: ${homeworkToProcess.toJson()}'); // Локально toJson не совсем нужен, но для лога можно
          if (homeworkToProcess.id == null) {
            // Добавляем новую локальную запись (ID будет сгенерирован в сервисе)
             await _localHomeworkService.addHomework(homeworkToProcess);
          } else {
            // Обновляем существующую локальную запись
             await _localHomeworkService.updateHomework(homeworkToProcess);
          }
           print('Локальное ДЗ успешно сохранено/обновлено!');

        } else {
          // --- Сохраняем/обновляем УДАЛЕННО (в Firebase) ---
          print('Сохраняем/обновляем УДАЛЕННО: ${homeworkToProcess.toJson()}');
          final homeworkMapForFirebase = Homework( // Создаем временный объект БЕЗ фото для сохранения в Firebase
            id: homeworkToProcess.id,
            discipline: homeworkToProcess.discipline,
            group: homeworkToProcess.group,
            groupId: homeworkToProcess.groupId,
            task: homeworkToProcess.task,
            dueDate: homeworkToProcess.dueDate,
            dateAdded: homeworkToProcess.dateAdded,
            photoUrls: null, // <--- Явно устанавливаем null для Firebase
            isLocal: homeworkToProcess.isLocal, // isLocal все равно false для Firebase
         ).toJson();
          if (homeworkToProcess.id == null) {
            // Добавляем новую удаленную запись
            await _firestore.collection('homework').add(homeworkMapForFirebase);
            } else {
              await _firestore.collection('homework').doc(homeworkMapForFirebase['id']).update(homeworkMapForFirebase);
            }
            print('УДАЛЕННОЕ ДЗ успешно сохранено/обновлено (без фото).');
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

Future<List<String>> _uploadPhotosToFirebaseStorage(List<XFile> photos) async {
   print('ВНИМАНИЕ: _uploadPhotosToFirebaseStorage вызван, но фото для удаленных записей сейчас НЕ загружаются!');
   // ... (код загрузки, но он не выполнится, если мы не вызываем этот метод)
   return []; // Возвращаем пустой список, т.к. загрузка не производится
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
        // Если _selectedGroupId уже установлен (например, из настроек или при редактировании),
        // пытаемся найти соответствующее имя группы.
        if (_selectedGroupId != null) {
          try {
            _selectedGroupName = _groups.firstWhere((group) => group['id'] == _selectedGroupId)['name'];
          } catch (e) {
            print("Группа с ID $_selectedGroupId не найдена в списке.");
            _selectedGroupId = null;
            _selectedGroupName = null;
          }
        }
        // Если _selectedGroupId все еще null (ничего не выбрано и нет в настройках),
        // и это добавление новой домашки, выбираем первую группу из списка.
        if (_selectedGroupId == null && widget.homeworkEntry == null && _groups.isNotEmpty) {
          _selectedGroupId = _groups.first['id'];
          _selectedGroupName = _groups.first['name'];
        }
        print("Selected Group ID: $_selectedGroupId, Name: $_selectedGroupName");
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
    final isAdding = widget.homeworkEntry == null;
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
                    _selectedGroupId = _groups.firstWhere((group) => group['name'] == newValue)['id']; // Обновляем ID
                    print("Selected Group ID: $_selectedGroupId, Name: $_selectedGroupName");
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Фото (опционально)'),
                  ElevatedButton.icon(
                    onPressed: _pickImages, // При нажатии вызываем метод выбора фото
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // --- НОВЫЙ ЭЛЕМЕНТ: Список выбранных фото (пока просто их названия) ---
              // Используем Expanded или SizedBox с высотой, если ListView не в Column напрямую
              // В данном случае ListView уже в body, так что можно использовать SizedBox
              if (_selectedPhotos.isNotEmpty) // Показываем список только если выбраны фото
                 SizedBox( // Ограничиваем высоту списка фото
                   height: _selectedPhotos.length * 40.0 > 200 ? 200 : _selectedPhotos.length * 40.0, // Максимальная высота 200, иначе по количеству элементов
                   child: ListView.builder(
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (context, index) {
                         final photo = _selectedPhotos[index];
                         // Пока просто отображаем название файла. Позже можно добавить миниатюру
                         return ListTile(
                            leading: const Icon(Icons.image), // Иконка фото
                            title: Text(photo.name), // Название файла
                            // TODO: Добавить кнопку удаления фото из списка
                         );
                      },
                   ),
                 ),
              const SizedBox(height: 20.0), // Отступ после списка фото

              if (isAdding)
                Row(
                  children: [
                    Text('Сохранить локально'),
                    Switch(
                      value: _saveLocally,
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _saveLocally = value; // Обновляем состояние чекбокса
                          });
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 20.0),

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
