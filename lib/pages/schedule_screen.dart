import 'dart:io';
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_card.dart';
import '../models/break_card.dart';

import '../models/daily_schedule.dart';

import '../data/groups.dart';
import '../data/rooms.dart';
import '../data/teachers.dart';

import '../models/group_info.dart';
import '../models/teacher_info.dart';
import '../models/room_info.dart';

import '../services/settings_service.dart';
import '../services/groups_service.dart';

import '../services/local_homework_service.dart';
import '../services/schedule_service.dart';
// Используем Supabase для домашних заданий (импорт уже выше)
import '../models/homework.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // --- Состояние ---
  ScheduleType _rasType = ScheduleType.grup;
  List<DailySchedule> _dailySchedules = []; // Храним список расписаний по дням
  DateTime _startDate = DateTime.now(); // Дата начала диапазона
  DateTime _endDate = DateTime.now().add(
    Duration(days: 6),
  ); // Дата конца диапазона
  String _scheduleDateDisplay =
      'Загрузка...'; // Строка для отображения диапазона
  bool _isLoading = true;
  String? _errorMessage;

  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  final _groupsService = GroupsService();

  Stream<List<Homework>>? _homeworkStream;

  List<GroupInfo> _availableGroups = []; // Список доступных групп
  List<TeacherInfo> _availableTeachers = []; // Список доступных групп
  List<RoomInfo> _availableRooms = []; // Список доступных групп
  GroupInfo?
  _selectedGroup; // Выбранная группа (при null выбирается первая доступная)
  TeacherInfo? _selectedTeacher;
  RoomInfo? _selectedRoom;

  // Константы для запроса
  bool _showBreaks = true;

  final String _scheduleApiUrl = 'https://asiec.ru/ras/ras.php';
  final String _dostup = 'true';

  DailySchedule? dailyScheduleForCard(DateTime date) {
    try {
      return _dailySchedules.firstWhere(
        (dailySchedule) =>
            dailySchedule.date.year == date.year &&
            dailySchedule.date.month == date.month &&
            dailySchedule.date.day == date.day,
      );
    } catch (e) {
      return null; // Не нашли расписание для этой даты
    }
  }

  void _setScheduleType(ScheduleType newType) {
    // switching type
    dynamic defaultSelectedObject; // Переменная для объекта по умолчанию

    // Выбираем объект по умолчанию в зависимости от нового типа
    switch (newType) {
      case ScheduleType.grup:
        defaultSelectedObject = _selectedGroup;
        if (defaultSelectedObject == null && _availableGroups.isNotEmpty) {
          defaultSelectedObject = _availableGroups.first;
        }
        break;
      case ScheduleType.prep:
        defaultSelectedObject = _selectedTeacher;
        if (defaultSelectedObject == null && _availableTeachers.isNotEmpty) {
          defaultSelectedObject = _availableTeachers.first;
        }
        break;
      case ScheduleType.aud:
        // Сначала пробуем использовать уже выбранную аудиторию
        defaultSelectedObject = _selectedRoom;
        if (defaultSelectedObject == null && _availableRooms.isNotEmpty) {
          defaultSelectedObject = _availableRooms.first;
        }
        break;
    }

    // Обновляем состояние UI: тип расписания и очищаем список
    setState(() {
      _rasType = newType; // Обновляем тип расписания
      _errorMessage = null; // Сбрасываем сообщение об ошибке
      _dailySchedules = []; // Очищаем текущее расписание (новый список, не мутируем кэш)

      // Если у нас есть объект по умолчанию — присваиваем его соответствующему полю,
      // чтобы дропдаун сразу показал корректное значение.
      if (defaultSelectedObject != null) {
        if (newType == ScheduleType.grup) _selectedGroup = defaultSelectedObject as GroupInfo;
        if (newType == ScheduleType.prep) _selectedTeacher = defaultSelectedObject as TeacherInfo;
        if (newType == ScheduleType.aud) _selectedRoom = defaultSelectedObject as RoomInfo;
      }
    });

    // Вызов загрузки данных — вне setState чтобы не выполнять асинхронную операцию внутри.
    if (defaultSelectedObject != null) {
      _loadScheduleData(
        _startDate,
        _endDate,
        newType,
        defaultSelectedObject,
      ); // Загружаем данные
    }
  }

  String _getRasTypeValue(ScheduleType type) {
    switch (type) {
      case ScheduleType.grup:
        return 'GRUP'; // Значение для расписания группы
      case ScheduleType.prep:
        return 'PREP'; // Значение для расписания преподавателя
      case ScheduleType.aud:
        return 'AUD'; // Значение для расписания аудитории
    }
  }

  @override
  void initState() {
    super.initState();
    _showBreaks = settingsService.showBreaksInScheduleNotifier.value;
    settingsService.showBreaksInScheduleNotifier.addListener(() {
      if (mounted) setState(() => _showBreaks = settingsService.showBreaksInScheduleNotifier.value);
    });
    // _initializeScheduleObjects(); // Инициализируем список И выбранную группу
    _loadAvailableGroups();
    final firebaseStream = _client
      .from('homework')
      .stream(primaryKey: ['id'])
      .map((rows) => (rows as List)
        .map((row) => Homework.fromJson(row as Map<String, dynamic>, (row['id'] ?? '').toString()))
        .toList());
    final localStream = _localHomeworkService.getHomeworkStream();
    _homeworkStream =
        Rx.combineLatest2<List<Homework>, List<Homework>, List<Homework>>(
          localStream,
          firebaseStream,
          (local, remote) => [...local, ...remote],
        );
    // // Загружаем данные, если группа выбрана
    // if (_selectedGroup != null) {
    //     _loadScheduleData(_startDate, _endDate, _rasType, _selectedGroup);
    // } else {
    //     // Ошибка - не удалось определить группу по умолчанию
    //     setState(() {
    //         _isLoading = false;
    //         _errorMessage = "Группа по умолчанию не найдена или не выбрана в настройках.";
    //     });
    // }
  }

  // Загружает группы из Supabase (GroupsService) и затем инициализирует объекты
  Future<void> _loadAvailableGroups() async {
    try {
      final groups =
          await _groupsService.getGroups(); // GroupsService кеширует через Hive
      // Если вернулся пустой список — оставляем локальные данные как fallback
      if (groups.isEmpty) {
        print(
          'GroupsService вернул пустой список, используем локальные данные',
        );
        _availableGroups = availableGroupsData;
      } else {
        _availableGroups = groups;
      }
    } catch (e) {
      print(
        'Не удалось загрузить группы из Supabase: $e — используем локальные данные',
      );
      _availableGroups = availableGroupsData;
    }

    // После загрузки групп инициализируем выбор и (при наличии) загружаем расписание
    _initializeScheduleObjects();
    if (_selectedGroup != null) {
      _loadScheduleData(_startDate, _endDate, _rasType, _selectedGroup);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            "Группа по умолчанию не найдена или не выбрана в настройках.";
      });
    }
  }

  void _initializeScheduleObjects() {
    // Заполняем список доступных групп
    // _availableGroups = availableGroupsData;
    _availableTeachers =
        availableTeachersData; // Заполняем список доступных преподавателей
    _availableRooms =
        availableRoomsData; // Заполняем список доступных аудиторий

    // --- ЛОГИКА ВЫБОРА ГРУППЫ ПО УМОЛЧАНИЮ ИЗ НАСТРОЕК ---
    final String? savedGroupId =
        settingsService.getDefaultGroupId(); // Получаем сохраненный ID
    _selectedGroup = null; // Сбрасываем на всякий случай

    if (savedGroupId != null) {
      // Ищем группу с сохраненным ID в нашем списке доступных групп
      try {
        _selectedGroup = _availableGroups.firstWhere(
          (g) => g.id == savedGroupId,
        );
      } catch (e) {
        print(
          "Сохраненная группа $savedGroupId не найдена в списке доступных.",
        );
        _selectedGroup = null; // Не нашли, сбрасываем
      }
    }

    // Если группа не была сохранена ИЛИ сохраненная не найдена,
    // выбираем первую доступную группу как запасной вариант
    if (_selectedGroup == null && _availableGroups.isNotEmpty) {
      _selectedGroup = _availableGroups.first;
      print(
        "Группа по умолчанию не найдена в настройках, выбрана первая: ${_selectedGroup?.name}",
      );
      // Опционально: можно сразу сохранить эту первую группу как дефолтную
      // settingsService.setDefaultGroupId(_selectedGroup?.id);
    } else if (_availableGroups.isEmpty) {
      print("Список доступных групп пуст!");
    }

    final String? savedTeacherId =
        settingsService
            .getDefaultTeacherId(); // <--- Получаем сохраненный ID преподавателя
    _selectedTeacher = null; // Сбрасываем на всякий случай

    if (savedTeacherId != null) {
      try {
        _selectedTeacher = _availableTeachers.firstWhere(
          // <--- Ищем преподавателя
          (t) => t.id == savedTeacherId,
          // orElse: () => null,
        );
      } catch (e) {
        print(
          "Сохраненный преподаватель $savedTeacherId не найден в списке доступных.",
        );
        _selectedTeacher = null; // Не нашли, сбрасываем
      }
    }

    if (_selectedTeacher == null && _availableTeachers.isNotEmpty) {
      _selectedTeacher =
          _availableTeachers
              .first; // <--- Выбираем первого преподавателя, если нет сохраненного
      print(
        "Преподаватель по умолчанию не найден в настройках, выбран первый: ${_selectedTeacher?.name}",
      );
    } else if (_availableTeachers.isEmpty) {
      print("Список доступных преподавателей пуст!");
    }

    print("Инициализация ScheduleScreen. Выбрана группа: $_selectedGroup");

    final String? savedRoomId =
        settingsService
            .getDefaultRoomId(); // <--- Получаем сохраненный ID аудитории
    _selectedRoom = null; // Сбрасываем на всякий случай

    if (savedRoomId != null) {
      try {
        _selectedRoom = _availableRooms.firstWhere(
          // <--- Ищем аудиторию
          (r) => r.id == savedRoomId,
        );
      } catch (e) {
        print(
          "Сохраненная аудитория $savedRoomId не найдена в списке доступных.",
        );
        _selectedRoom = null; // Не нашли, сбрасываем
      }
    }

    if (_selectedRoom == null && _availableRooms.isNotEmpty) {
      _selectedRoom =
          _availableRooms
              .first; // <--- Выбираем первую аудиторию, если нет сохраненной
      print(
        "Аудитория по умолчанию не найдена в настройках, выбрана первая: ${_selectedRoom?.name}",
      );
    } else if (_availableRooms.isEmpty) {
      print("Список доступных аудиторий пуст!");
    }

    print(
      "Инициализация ScheduleScreen. Группа: $_selectedGroup, Преподаватель: $_selectedTeacher, Аудитория: $_selectedRoom",
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(
        _startDate.year - 2,
      ), // ГПервая доступная дата (-2 года от текущего)
      lastDate: DateTime(
        _endDate.year + 2,
      ), // Последняя доступная дата (+2 года от текущего)
      locale: const Locale('ru', 'RU'), // Локализация для пикера
      helpText: 'Выберите диапазон дат',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
      saveText: 'Выбрать',
      builder: (context, child) {
        final currentTheme = Theme.of(context);

        final pickerThemeData = currentTheme.copyWith(
          colorScheme: currentTheme.colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.onPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        );

        return Theme(data: pickerThemeData, child: child!);
      },
    );

    if (picked != null) {
      final newStartDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      final newEndDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
      );

      if (newStartDate != _startDate || newEndDate != _endDate) {
        dynamic selectedObject;
        switch (_rasType) {
          case ScheduleType.grup:
            selectedObject = _selectedGroup;
            break;
          case ScheduleType.prep:
            selectedObject = _selectedTeacher;
            break;
          case ScheduleType.aud:
            selectedObject = _selectedRoom;
            break;
        }

        if (selectedObject != null) {
          _loadScheduleData(newStartDate, newEndDate, _rasType, selectedObject);
        } else {
          print("Невозможно загрузить расписание: объект не выбран");
          _showSnackBar(context, "Сначала выберите объект");
        }
      }
    }
  }

  // Pull-to-refresh: invalidate current cache and reload from network
  Future<void> _refreshSchedule() async {
    dynamic selected;
    switch (_rasType) {
      case ScheduleType.grup:
        selected = _selectedGroup;
        break;
      case ScheduleType.prep:
        selected = _selectedTeacher;
        break;
      case ScheduleType.aud:
        selected = _selectedRoom;
        break;
    }

    if (selected == null) {
      _showSnackBar(context, "Сначала выберите объект");
      return;
    }

    String objectId = '';
    if (selected is GroupInfo) objectId = selected.id;
    if (selected is TeacherInfo) objectId = selected.id;
    if (selected is RoomInfo) objectId = selected.id;

    final startDateString = _formatDateForApi(_startDate);
    final endDateString = _formatDateForApi(_endDate);
    final cacheKey = ScheduleService.instance.makeKey(
      _getRasTypeValue(_rasType),
      objectId,
      startDateString,
      endDateString,
    );

    ScheduleService.instance.removeCached(cacheKey);

    await _loadScheduleData(_startDate, _endDate, _rasType, selected);
  }

  // --- Хелпер для показа SnackBar ---
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 2)),
    );
  }

  // Функция загрузки данных
  Future<void> _loadScheduleData(
    DateTime startDate,
    DateTime endDate,
    ScheduleType scheduleType,
    dynamic selectedObject,
  ) async {
    // _loadScheduleData called
    // Проверяем mounted перед первом setState
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Отображаем текущий диапазон и группу + "Загрузка..."
      _scheduleDateDisplay =
          '${_formatDateRangeForDisplay(_startDate, _endDate)} (Загрузка...)';
      _dailySchedules = [];
    });
    String objectId =
        ''; // Переменная для ID объекта (группы, преподавателя, аудитории)
    String rasParamName = '';
    final String startDateString = _formatDateForApi(startDate);
    final String endDateString = _formatDateForApi(endDate);

    switch (scheduleType) {
      case ScheduleType.grup:
        rasParamName = 'gruppa'; // Имя параметра для групп
        if (selectedObject is GroupInfo) {
          objectId = selectedObject.id; // Получаем ID группы
        }
        break;
      case ScheduleType.prep:
        rasParamName = 'prepod';
        if (selectedObject is TeacherInfo) {
          objectId = selectedObject.id; // Получаем ID преподавателя
        }
        break;
      case ScheduleType.aud:
        rasParamName = 'auditoria';
        if (selectedObject is RoomInfo) {
          objectId = selectedObject.id; // Получаем ID аудитории
        }
        break;
    }

    final body = {
      'dostup': _dostup,
      rasParamName: objectId, // Используем ID выбранной группы
      'calendar': startDateString,
      'calendar2': endDateString,
      'ras': _getRasTypeValue(scheduleType), // Конвертим ScheduleType в String (use parameter)
    };

    // --- Попытка взять из кеша перед выполнением сетевого запроса ---
    final cacheKey = ScheduleService.instance.makeKey(
      _getRasTypeValue(_rasType),
      objectId,
      startDateString,
      endDateString,
    );
    final cached = ScheduleService.instance.getCached(cacheKey);
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _startDate = startDate;
        _endDate = endDate;
        _dailySchedules = cached;
        _scheduleDateDisplay =
            _formatDateRangeForDisplay(_startDate, _endDate);
        _isLoading = false;
        _errorMessage = null;
      });
      // loaded from cache
      return; // Данные из кеша, не делаем запрос
    }

    try {

      // about to POST
      http.Response response;
      try {
        response = await http
            .post(
          Uri.parse(_scheduleApiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
            .timeout(const Duration(seconds: 15));

        // HTTP response received
      } on TimeoutException catch (e) {
        print('ScheduleScreen: HTTP request timed out: $e');
        rethrow;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final parsedData = parseScheduleHtmlMultiDay(response.body);

        // Сохраняем в кеш
        try {
          ScheduleService.instance.setCached(cacheKey, parsedData);
        } catch (e) {
          // ignore cache errors
        }

        if (!mounted) return;
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
          _dailySchedules = parsedData;
          _scheduleDateDisplay =
              _formatDateRangeForDisplay(_startDate, _endDate); // Обновляем отображение
          _isLoading = false;
          _errorMessage = null;
        });
        // loaded from network
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Сервер вернул код ${response.statusCode}';
        });
      }
    } catch (e) {
      // Ловим исключение
      String errorMessageText =
          'Не удалось загрузить расписание: ${e.toString()}'; // Стандартное сообщение

      // Попытка дать более понятный текст при сетевых ошибках
      if (e is SocketException) {
        errorMessageText =
            'Проблемы с сетью. Проверьте подключение и попробуйте снова.';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessageText;
      });
      print(errorMessageText);
    }
  }

  // Форматирование дат
  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Функция для форматирования диапазона для отображения
  String _formatDateRangeForDisplay(DateTime start, DateTime end) {
    final ruLocale = 'ru_RU';
    try {
      // Если даты совпадают, показываем одну дату
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return DateFormat(
          'd MMMM yyyy',
          ruLocale,
        ).format(start); // Добавим год для ясности
      }
      // Если даты в одном месяце и году
      else if (start.year == end.year && start.month == end.month) {
        return '${DateFormat('d', ruLocale).format(start)} - ${DateFormat('d MMMM yyyy', ruLocale).format(end)}';
      }
      // Если даты в одном году, но разных месяцах
      else if (start.year == end.year) {
        return '${DateFormat('d MMMM', ruLocale).format(start)} - ${DateFormat('d MMMM yyyy', ruLocale).format(end)}';
      }
      // Иначе показываем полный диапазон
      else {
        return '${DateFormat('d MMMM yyyy', ruLocale).format(start)} - ${DateFormat('d MMMM yyyy', ruLocale).format(end)}';
      }
    } catch (e) {
      print("Ошибка форматирования диапазона дат: $e");
      return '${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}';
    }
  }

  Widget _buildScheduleTypeButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
      child: SegmentedButton<ScheduleType>(
        segments: const [
          ButtonSegment(
            value: ScheduleType.grup,
            label: Text('Группа'),
            icon: Icon(Icons.group),
          ),
          ButtonSegment(
            value: ScheduleType.prep,
            label: Text('Преподаватель'),
            icon: Icon(Icons.person),
          ),
          ButtonSegment(
            value: ScheduleType.aud,
            label: Text('Аудитория'),
            icon: Icon(Icons.meeting_room),
          ),
        ],
        selected: <ScheduleType>{_rasType},
        onSelectionChanged: (Set<ScheduleType> newSelection) {
          if (newSelection.isNotEmpty) {
            _setScheduleType(newSelection.first);
          }
        },
      ),
    );
  }

  Widget _buildObjectSelector() {
    String hintText;
    List<DropdownMenuItem<dynamic>>? items = [];
    // ignore: unused_local_variable
    String rasParamName = ''; // Имя параметра для передачи в запросе
    switch (_rasType) {
      case ScheduleType.grup:
        rasParamName = 'gruppa'; // Имя параметра для групп
        hintText = 'Выберите группу';
        items =
            _availableGroups.map((group) {
              // Используем _groupList
              return DropdownMenuItem<GroupInfo>(
                // Тип элемента - GroupInfo
                value: group,
                child: Text(group.name),
              );
            }).toList();
        break;
      case ScheduleType.prep:
        rasParamName = 'prepod';
        hintText = 'Выберите преподавателя'; // Hint для преподавателей
        items =
            _availableTeachers.map((teacher) {
              // Используем _groupList
              return DropdownMenuItem<TeacherInfo>(
                // Тип элемента - GroupInfo
                value: teacher,
                child: Text(teacher.name),
              );
            }).toList();
        break;
      case ScheduleType.aud:
        rasParamName = 'auditoria';
        hintText = 'Выберите аудиторию'; // Hint для аудиторий
        items =
            _availableRooms.map((room) {
              // Используем _groupList
              return DropdownMenuItem<RoomInfo>(
                // Тип элемента - GroupInfo
                value: room,
                child: Text(room.name),
              );
            }).toList();
        break;
    }

    return Padding(
      // Оборачиваем Padding
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 0.0,
      ), // Уменьшаем вертикальный отступ
      child: DropdownButtonHideUnderline(
        // Убираем стандартное подчеркивание
        child: Container(
          // Оборачиваем в контейнер для фона и скругления
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade500), // Легкая граница
          ),
          child: DropdownButton<dynamic>(
            value:
                _rasType == ScheduleType.grup
                    ? _selectedGroup // Для групп - _selectedGroup
                    : _rasType == ScheduleType.prep
                    ? _selectedTeacher // Для преподавателей - _selectedTeacher
                    : _rasType == ScheduleType.aud
                    ? _selectedRoom // Для аудиторий - _selectedRoom
                    : null,
            hint: Text(hintText), // Динамический hintText
            isExpanded: true, // Растягиваем на всю ширину
            icon: Icon(
              Icons.group_outlined,
              color: Theme.of(context).colorScheme.primary,
            ), // Иконка справа
            onChanged: (dynamic newValue) {
              // onChanged теперь принимает dynamic
              setState(() {
                _errorMessage = null;
                _dailySchedules = [];
                if (newValue != null) {
                  if (_rasType == ScheduleType.grup) {
                    _selectedGroup =
                        newValue as GroupInfo; // Обновляем _selectedGroup
                  } else if (_rasType == ScheduleType.prep) {
                    _selectedTeacher =
                        newValue as TeacherInfo; // Обновляем _selectedTeacher
                  } else if (_rasType == ScheduleType.aud) {
                    // Раскомментируй, когда добавим RoomInfo
                    _selectedRoom =
                        newValue as RoomInfo; // Обновляем _selectedRoom
                  }
                  _loadScheduleData(_startDate, _endDate, _rasType, newValue);
                }
              });
            },
            items: items, // Динамический список items
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Заголовки дней будут на всю ширину
          children: [
            // Кликабельный заголовок с диапазоном дат
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: InkWell(
                // Делаем область кликабельной
                onTap:
                    _isLoading
                        ? null
                        : () => _selectDateRange(
                          context,
                        ), // Вызываем пикер по тапу (блокируем во время загрузки)
                borderRadius: BorderRadius.circular(
                  8.0,
                ), // Скругление для эффекта при нажатии
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                  ), // Внутренний отступ для красоты
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Центрируем текст и иконку
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20.0,
                        color: Theme.of(context).colorScheme.primary,
                      ), // Иконка календаря
                      SizedBox(width: 8.0),
                      Flexible(
                        // Чтобы текст переносился, если диапазон длинный
                        child: Text(
                          _scheduleDateDisplay, // Отображаем диапазон или статус загрузки
                          style: TextStyle(
                            fontSize: 18.0, // Можно настроить размер
                            fontWeight: FontWeight.w500, // Средняя жирность
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      // Можно добавить иконку выпадающего списка для большей очевидности
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildObjectSelector(), // <--- ВСТАВЬ СЮДА ВЫЗОВ _buildObjectSelector()!

            SizedBox(height: 8.0), // Небольшой отступ после дропдауна
            _buildScheduleTypeButtons(),

            // Тело экрана: загрузка, ошибка или список
            Expanded(
              child: StreamBuilder<List<Homework>>(
                stream: _homeworkStream,
                builder: (context, homeworkSnapshot) {
                  final allHomeworks = homeworkSnapshot.data ?? [];
                  return _buildBody(allHomeworks); // Передаем список ДЗ
                },
              ),
            ),
          ],
        ),
        // backgroundColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildBody(List<Homework> allHomeworks) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      // Оборачиваем ошибочный экран в RefreshIndicator, чтобы можно было обновить
      return RefreshIndicator(
        onRefresh: _refreshSchedule,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16.0),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Не удалось загрузить расписание для ${_rasType == ScheduleType.grup
                          ? "группы"
                          : _rasType == ScheduleType.prep
                              ? "преподавателя"
                              : "аудитории"} ${_selectedGroup?.name ?? _selectedTeacher?.name ?? _selectedRoom?.name ?? "N/A"}.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.errorContainer,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        dynamic selected;
                        switch (_rasType) {
                          case ScheduleType.grup:
                            selected = _selectedGroup;
                            break;
                          case ScheduleType.prep:
                            selected = _selectedTeacher;
                            break;
                          case ScheduleType.aud:
                            selected = _selectedRoom;
                            break;
                        }
                        if (selected != null) {
                          _loadScheduleData(_startDate, _endDate, _rasType, selected);
                        } else {
                          _showSnackBar(context, "Сначала выберите объект");
                        }
                      },
                      child: Text('Повторить попытку'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Если расписание пустое — показываем текст внутри ListView, чтобы сработал pull-to-refresh
    if (_dailySchedules.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshSchedule,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16.0),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 120.0),
                child: Text(
                  'Пусто ¯\\_(ツ)_/¯',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Используем ListView для отображения дней и их пар
    return RefreshIndicator(
      onRefresh: _refreshSchedule,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16.0), // Отступ снизу списка
        itemCount:
            _dailySchedules
                .length, // Количество дней = количество элементов в главном списке
        itemBuilder: (context, dayIndex) {
          final dailySchedule = _dailySchedules[dayIndex];

          // Создаем столбец для каждого дня: Заголовок + список пар (или сообщение "Пар нет")
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Заголовок дня ---
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 4.0,
                ),
                child: Text(
                  // Форматируем дату дня (например, "Понедельник, 15 Октября")
                  DateFormat(
                    'EEEE, d MMMM',
                    'ru_RU',
                  ).format(dailySchedule.date),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              // --- Список пар для этого дня ---
              if (dailySchedule.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    bottom: 8.0,
                  ),
                  child: Text(
                    'Пар нет',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                  ),
                )
              else
                Builder(builder: (context) {
                  // Сортируем пары по времени начала
                  dailySchedule.entries.sort((a, b) {
                    try {
                      final timeA = TimeOfDay(
                          hour: int.parse(a.startTime.split(':')[0]),
                          minute: int.parse(a.startTime.split(':')[1]));
                      final timeB = TimeOfDay(
                          hour: int.parse(b.startTime.split(':')[0]),
                          minute: int.parse(b.startTime.split(':')[1]));
                      final minutesA = timeA.hour * 60 + timeA.minute;
                      final minutesB = timeB.hour * 60 + timeB.minute;
                      return minutesA.compareTo(minutesB);
                    } catch (e) {
                      return 0;
                    }
                  });

                  List<Widget> scheduleWidgets = [];
                  for (int i = 0; i < dailySchedule.entries.length; i++) {
                    final entry = dailySchedule.entries[i];
                    scheduleWidgets.add(ScheduleCard(
                      entry: entry,
                      allEntriesForDay: dailySchedule.entries,
                      homeworks: allHomeworks,
                    ));

                    // Если включено отображение перемен и это не последняя пара
                    if (_showBreaks && i < dailySchedule.entries.length - 1) {
                      final nextEntry = dailySchedule.entries[i + 1];
                      try {
                        final endCurrent = TimeOfDay(
                            hour: int.parse(entry.endTime.split(':')[0]),
                            minute: int.parse(entry.endTime.split(':')[1]));
                        final startNext = TimeOfDay(
                            hour: int.parse(nextEntry.startTime.split(':')[0]),
                            minute:
                                int.parse(nextEntry.startTime.split(':')[1]));

                        final endMinutes = endCurrent.hour * 60 + endCurrent.minute;
                        final startMinutes = startNext.hour * 60 + startNext.minute;

                        if (startMinutes > endMinutes) {
                          scheduleWidgets.add(BreakCard(
                            duration: Duration(minutes: startMinutes - endMinutes),
                            startTime: entry.endTime,
                            endTime: nextEntry.startTime,
                            date: dailySchedule.date, // Передаем дату
                          ));
                        }
                      } catch (e) {
                        // Игнорируем ошибки парсинга времени для перемен
                      }
                    }
                  }

                  return Column(children: scheduleWidgets);
                }),

              // Добавляем разделитель между днями, кроме последнего
              if (dayIndex < _dailySchedules.length - 1)
                Divider(
                  height: 24.0,
                  thickness: 1.0,
                  indent: 16.0,
                  endIndent: 16.0,
                ),
            ],
          );
        },
      ),
    );
  }
}

enum ScheduleType { grup, prep, aud }
