import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/homework.dart';
import '../services/local_homework_service.dart';
// groups data now comes from Supabase via GroupsService
import '../services/settings_service.dart'; // Импортируем SettingsService

class HomeworkEditScreen extends StatefulWidget {
  // Если будем использовать этот экран для РЕДАКТИРОВАНИЯ,
  // то здесь будет передаваться существующая запись о домашке
  final Homework? homeworkEntry;

  const HomeworkEditScreen({super.key, this.homeworkEntry});

  @override
  _HomeworkEditScreenState createState() => _HomeworkEditScreenState();
}

class _HomeworkEditScreenState extends State<HomeworkEditScreen> {
  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  final _disciplineController = TextEditingController();
  final _subgroupController = TextEditingController();
  final _taskController = TextEditingController();
  DateTime _selecteddue_date = DateTime.now();
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
      _selectedGroupId = widget.homeworkEntry!.group_id;
      _subgroupController.text = widget.homeworkEntry!.subgroup ?? '';
      _taskController.text = widget.homeworkEntry!.task;
      _selecteddue_date = widget.homeworkEntry!.due_date;
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
    if (_groups.isNotEmpty &&
        _selectedGroupId != null &&
        _selectedGroupName == null) {
      _selectedGroupName =
          _groups.firstWhere(
            (group) => group['id'] == _selectedGroupId,
          )['name'];
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
  Future<void> _selectdue_date(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selecteddue_date, // Начальная дата - текущая выбранная
      firstDate: DateTime.now(), // Нельзя выбрать дату в прошлом
      lastDate: DateTime(2101), // Достаточно далеко в будущем
    );
    if (picked != null && picked != _selecteddue_date) {
      setState(() {
        _selecteddue_date = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    // Открываем диалог выбора нескольких изображений из галереи
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedPhotos = pickedFiles; // Обновляем список выбранных фото
      });
    }
  }

  Future<List<String>> _savePhotosLocally(List<XFile> photos) async {
    List<String> localPaths =
        []; // Список для хранения путей к локальным файлам

    try {
      // Получаем каталог для хранения документов приложения
      final directory =
          await getApplicationDocumentsDirectory(); // <--- Используем path_provider!
      final homeworkPhotosDir = Directory(
        '${directory.path}/homework_photos',
      ); // Создаем подпапку для фото ДЗ

      // Убедимся, что папка существует
      if (!await homeworkPhotosDir.exists()) {
        await homeworkPhotosDir.create(
          recursive: true,
        ); // Создаем папку, если ее нет
      }

      for (final photoFile in photos) {
        // Генерируем уникальное имя файла (можно использовать ID ДЗ + уникальный ID фото)
        // Для простоты пока используем уникальный ID + расширение
        final String photoId = const Uuid().v4();
        final String fileExtension = photoFile.name.split('.').last;
        final String newFileName = '$photoId.$fileExtension';
        final String newFilePath =
            '${homeworkPhotosDir.path}/$newFileName'; // Полный путь к новому файлу

        // Копируем файл из временного пути (XFile) в нашу папку
        final File newFile = await File(
          photoFile.path,
        ).copy(newFilePath); // <--- Копируем файл!
        if (!mounted) return [];

        localPaths.add(newFile.path); // Добавляем путь к новому файлу в список

        print(
          'Фото ${photoFile.name} успешно сохранено локально по пути: ${newFile.path}',
        );
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
      List<String> processedphotoUrlsorpaths = [];
      // Проверяем, что группа выбрана
      if (_selectedGroupId == null || _selectedGroupName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пожалуйста, выберите группу')),
        );
        return;
      }
      final isAdding = widget.homeworkEntry == null;
      final bool shouldSaveLocally =
          isAdding ? _saveLocally : widget.homeworkEntry!.isLocal;

      if (_selectedPhotos.isNotEmpty) {
        // Если пользователь выбрал новые фото
        if (shouldSaveLocally) {
          // --- Сохраняем фото ЛОКАЛЬНО (для Hive) ---
          print('Сохраняем фото ЛОКАЛЬНО...');
          processedphotoUrlsorpaths = await _savePhotosLocally(
            _selectedPhotos,
          ); // <--- ВЫЗЫВАЕМ НАШ РЕАЛИЗОВАННЫЙ МЕТОД!
          print('Фото успешно сохранены локально.');
        } else {
          // --- Для удалённых записей: загружаем фото в Supabase Storage и получаем публичные URL ---
          print('Загружаем фото в Supabase Storage...');
          processedphotoUrlsorpaths = await _uploadPhotosToSupabaseStorage(_selectedPhotos);
          print('Фото загружены в Supabase: ${processedphotoUrlsorpaths.length}');
        }
      }

      // Если мы редактируем запись, и у нее уже были фото, добавляем их к новым.
      // TODO: Обработать случай удаления фото при редактировании!
      // Объединяем старые и новые URLы/пути. Важно: сохраняем только те URLы/пути, которые были изначально (при редактировании)
      // ПЛЮС новые, которые мы только что обработали.
      // Если мы редактируем локальную запись, photo_urls - это пути. Если удаленную, это URLы.
      List<String> finalphotoUrlsorpaths = [];
      // Добавляем старые пути/URLы из существующей записи (если редактируем)
      if (widget.homeworkEntry?.photo_urls != null) {
        finalphotoUrlsorpaths.addAll(widget.homeworkEntry!.photo_urls!);
      }
      // Добавляем новые пути/URLы, которые мы только что обработали
      finalphotoUrlsorpaths.addAll(processedphotoUrlsorpaths);

      // Если данные корректны, создаем объект Homework
      final homeworkToProcess = Homework(
        id: widget.homeworkEntry?.id, // Если редактируем, сохраняем старый ID
        discipline: _disciplineController.text.trim(),
        group: _selectedGroupName!, // Используем выбранное имя группы
        group_id: _selectedGroupId!, // Используем выбранный ID группы
        subgroup:
            _subgroupController.text.trim().isEmpty
                ? null
                : _subgroupController.text
                    .trim(), // Если поле подгруппы пустое, сохраняем null
        task: _taskController.text.trim(),
        due_date: _selecteddue_date,
        date_added:
          widget.homeworkEntry?.date_added ??
          DateTime.now(), // Если редактируем, сохраняем старую дату добавления, иначе - текущую
        photo_urls: finalphotoUrlsorpaths.isEmpty ? null : finalphotoUrlsorpaths,
        isLocal: widget.homeworkEntry?.isLocal ?? _saveLocally,
      );

      // --- ЛОГИКА СОХРАНЕНИЯ ---
      try {
        if (homeworkToProcess.isLocal) {
          // --- Сохраняем/обновляем ЛОКАЛЬНО (в Hive) ---
          print(
            'Сохраняем/обновляем ЛОКАЛЬНО: ${homeworkToProcess.toJson()}',
          );
          if (homeworkToProcess.id == null) {
            await _localHomeworkService.addHomework(homeworkToProcess);
          } else {
            await _localHomeworkService.updateHomework(homeworkToProcess);
          }
          print('Локальное ДЗ успешно сохранено/обновлено!');
        } else {
          // --- Сохраняем/обновляем УДАЛЕННО (в Supabase) ---
          print('Сохраняем/обновляем УДАЛЕННО: ${homeworkToProcess.toJson()}');
          // Метод toJson() теперь возвращает все необходимые поля, кроме id
          final homeworkMapForSupabase = homeworkToProcess.toJson();

          if (homeworkToProcess.id == null) {
            // При создании новой записи удаляем id из карты,
            // чтобы база данных сгенерировала его автоматически.
            homeworkMapForSupabase.remove('id');
            await _client.from('homework').insert(homeworkMapForSupabase);
          } else {
            await _client.from('homework').update(homeworkMapForSupabase).eq('id', homeworkToProcess.id!);
          }

          print('УДАЛЕННОЕ ДЗ успешно сохранено/обновлено.');
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        print("Ошибка при сохранении ДЗ: $e");
      }
    }
  }

  Future<List<String>> _uploadPhotosToSupabaseStorage(
    List<XFile> photos,
  ) async {
    // Задайте имя вашего bucket'а здесь
    const String bucket = 'files';
    final List<String> uploadedUrls = [];
    try {
      for (final photo in photos) {
        // final bytes = await File(photo.path).readAsBytes(); // not used with upload(File)
        final String ext = photo.name.contains('.') ? photo.name.split('.').last : 'jpg';
        final String filename = '${const Uuid().v4()}.$ext';
        // Сохраняем в подпапке homework для удобства
        final filePath = 'homework/$filename';

        try {
          // Попытка загрузить файл (основной путь)
          final res = await _client.storage.from(bucket).upload(filePath, File(photo.path));
          // Некоторые версии SDK возвращают ответ; логируем его
          print('Supabase upload result for $filePath: $res');

          // Попробуем получить публичный URL (работает для публичного bucket'а)
          final publicUrl = _client.storage.from(bucket).getPublicUrl(filePath);
          uploadedUrls.add(publicUrl.toString());
          print('Uploaded $filePath -> $publicUrl');
        } catch (e) {
          print('Ошибка при загрузке $filePath в Supabase Storage: $e');
        }
      }
    } catch (e) {
      print('Ошибка при загрузке фото в Supabase Storage: $e');
    }
    return uploadedUrls;
  }

  // --- Метод для загрузки списка групп из Supabase ---
  Future<void> _fetchGroups() async {
    try {
      final data = await _client.from('groups').select();
      final List rows = (data as dynamic) as List? ?? [];
      final List<Map<String, dynamic>> fetched = rows.map((r) {
        try {
          return {
            'id': r['id'].toString(),
            'name': r['name'].toString(),
          };
        } catch (_) {
          return {'id': '', 'name': ''};
        }
      }).where((m) => (m['id'] as String).isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _groups = fetched;
        if (_selectedGroupId != null) {
          try {
            _selectedGroupName =
                _groups.firstWhere(
                  (group) => group['id'] == _selectedGroupId,
                )['name'];
          } catch (e) {
            _selectedGroupId = null;
            _selectedGroupName = null;
          }
        }
        if (_selectedGroupId == null &&
            widget.homeworkEntry == null &&
            _groups.isNotEmpty) {
          _selectedGroupId = _groups.first['id'];
          _selectedGroupName = _groups.first['name'];
        }
      });
    } catch (e) {
      print("Ошибка при загрузке групп: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки групп: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdding = widget.homeworkEntry == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homeworkEntry == null
              ? 'Добавить домашнее задание'
              : 'Редактировать домашнее задание',
        ),
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
                initialValue: _selectedGroupName,
                decoration: const InputDecoration(labelText: 'Группа'),
                items:
                    _groups.map((Map<String, dynamic> group) {
                      return DropdownMenuItem<String>(
                        value: group['name'],
                        child: Text(group['name']),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGroupName = newValue;
                    _selectedGroupId =
                        _groups.firstWhere(
                          (group) => group['name'] == newValue,
                        )['id']; // Обновляем ID
                    print(
                      "Selected Group ID: $_selectedGroupId, Name: $_selectedGroupName",
                    );
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
                decoration: const InputDecoration(
                  labelText: 'Подгруппа (опционально)',
                ),
                // Валидация не нужна, т.к. поле опциональное
              ),
              const SizedBox(height: 12.0),

              // --- Поле для ввода текста задания (TextArea) ---
              TextFormField(
                controller: _taskController,
                decoration: const InputDecoration(labelText: 'Текст задания'),
                maxLines: null, // Позволяет тексту занимать несколько строк
                keyboardType:
                    TextInputType
                        .multiline, // Клавиатура для многострочного текста
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
                  '${_selecteddue_date.day}.${_selecteddue_date.month}.${_selecteddue_date.year}', // Форматируем дату для отображения
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap:
                    () => _selectdue_date(
                      context,
                    ), // При нажатии открываем DatePicker
              ),
              const SizedBox(height: 20.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Фото (опционально)'),
                  ElevatedButton.icon(
                    onPressed:
                        _pickImages, // При нажатии вызываем метод выбора фото
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // --- НОВЫЙ ЭЛЕМЕНТ: Список выбранных фото (пока просто их названия) ---
              // Используем Expanded или SizedBox с высотой, если ListView не в Column напрямую
              // В данном случае ListView уже в body, так что можно использовать SizedBox
              if (_selectedPhotos
                  .isNotEmpty) // Показываем список только если выбраны фото
                SizedBox(
                  // Ограничиваем высоту списка фото
                  height:
                      _selectedPhotos.length * 40.0 > 200
                          ? 200
                          : _selectedPhotos.length *
                              40.0, // Максимальная высота 200, иначе по количеству элементов
                  child: ListView.builder(
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = _selectedPhotos[index];
                      // Пока просто отображаем название файла. Позже можно добавить миниатюру
                      return ListTile(
                        leading: const Icon(Icons.image), // Иконка фото
                        title: Text(photo.name), // Название файла
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _selectedPhotos.removeAt(index);
                            });
                          },
                          tooltip: 'Удалить фото',
                        ),
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
                            _saveLocally =
                                value; // Обновляем состояние чекбокса
                          });
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 20.0),

              // --- Кнопка сохранения ---
              ElevatedButton(
                onPressed:
                    _saveHomework, // При нажатии вызываем метод сохранения
                child: Text(
                  widget.homeworkEntry == null
                      ? 'Добавить'
                      : 'Сохранить изменения',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
