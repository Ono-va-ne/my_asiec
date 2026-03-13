import 'dart:io';
import 'dart:async';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/schedule_card.dart';
import '../../models/break_card.dart';
import '../../models/daily_schedule.dart';
import '../../data/groups.dart';
import '../../data/rooms.dart';
import '../../data/teachers.dart';
import '../../models/group_info.dart';
import '../../models/teacher_info.dart';
import '../../models/room_info.dart';
import '../../services/settings_service.dart';
import '../../services/groups_service.dart';
import '../../services/teachers_service.dart';
import '../../services/local_homework_service.dart';
import '../../services/schedule_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/homework.dart';
import '../../data/text_emojis.dart';

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
  String _filterText = '';
  String? _errorMessage;

  final _client = Supabase.instance.client;
  final _localHomeworkService = LocalHomeworkService();
  final _groupsService = GroupsService();
  final _teachersService = TeachersService();

  final _filterController = TextEditingController();
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
    _loadInitialData();
    final serverStream = _client
      .from('homework')
      .stream(primaryKey: ['id'])
      .map((rows) => (rows as List)
        .map((row) => Homework.fromJson(row as Map<String, dynamic>, (row['id'] ?? '').toString()))
        .toList());
    final localStream = _localHomeworkService.getHomeworkStream();
    _homeworkStream =
        Rx.combineLatest2<List<Homework>, List<Homework>, List<Homework>>(
          localStream,
          serverStream,
          (local, remote) => [...local, ...remote],
        );
    _filterController.addListener(() {
      if (mounted) {
        setState(() => _filterText = _filterController.text);
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Параллельно загружаем группы и преподавателей
    await Future.wait([
      _loadAvailableGroups(),
      _loadAvailableTeachers(),
    ]);

    // Инициализация выбора и загрузка расписания после загрузки данных
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

  Future<void> _loadAvailableGroups() async {
    try {
      final groups =
          await _groupsService.getGroups(); // GroupsService кеширует через Hive
      if (groups.isEmpty) {
        print('GroupsService вернул пустой список, используем локальные данные');
        _availableGroups = availableGroupsData;
      } else {
        _availableGroups = groups;
      }
    } catch (e) {
      print('Не удалось загрузить группы из Supabase: $e — используем локальные данные');
      _availableGroups = availableGroupsData;
    }
  }

  Future<void> _loadAvailableTeachers() async {
    try {
      final teachers = await _teachersService.getTeachers();
      if (teachers.isNotEmpty) {
        _availableTeachers = teachers;
      }
    } catch (e) {
      print('Не удалось загрузить преподавателей из Supabase: $e — используем локальные данные');
      _availableTeachers = availableTeachersData;
    }
  }

  void _initializeScheduleObjects() {
    // Заполняем список доступных групп
    // _availableGroups = availableGroupsData;
    // _availableTeachers =
    //     availableTeachersData; // Заполняем список доступных преподавателей
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
        _selectedGroup = null;
      }
    }

    // Если группа не была сохранена ИЛИ сохраненная не найдена, выбираем первую доступную группу
    if (_selectedGroup == null && _availableGroups.isNotEmpty) {
      _selectedGroup = _availableGroups.first;
      print(
        "Группа по умолчанию не найдена в настройках, выбрана первая: ${_selectedGroup?.name}",
      );
    } else if (_availableGroups.isEmpty) {
      print("Список доступных групп пуст!");
    }

    final String? savedTeacherId =
        settingsService
            .getDefaultTeacherId();
    _selectedTeacher = null;

    if (savedTeacherId != null) {
      try {
        _selectedTeacher = _availableTeachers.firstWhere(
          (t) => t.id == savedTeacherId,
        );
      } catch (e) {
        print(
          "Сохраненный преподаватель $savedTeacherId не найден в списке доступных.",
        );
        _selectedTeacher = null;
      }
    }

    if (_selectedTeacher == null && _availableTeachers.isNotEmpty) {
      _selectedTeacher =
          _availableTeachers
              .first; // Выбираем первого преподавателя, если нет сохраненного
      print(
        "Преподаватель по умолчанию не найден в настройках, выбран первый: ${_selectedTeacher?.name}",
      );
    } else if (_availableTeachers.isEmpty) {
      print("Список доступных преподавателей пуст!");
    }

    print("Инициализация ScheduleScreen. Выбрана группа: $_selectedGroup");

    final String? savedRoomId =
        settingsService
            .getDefaultRoomId();
    _selectedRoom = null;

    if (savedRoomId != null) {
      try {
        _selectedRoom = _availableRooms.firstWhere(
          (r) => r.id == savedRoomId,
        );
      } catch (e) {
        print(
          "Сохраненная аудитория $savedRoomId не найдена в списке доступных.",
        );
        _selectedRoom = null;
      }
    }

    if (_selectedRoom == null && _availableRooms.isNotEmpty) {
      _selectedRoom =
          _availableRooms
              .first; // Выбираем первую аудиторию, если нет сохраненной
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
      ), // Первая доступная дата (-2 года от текущего)
      lastDate: DateTime(
        _endDate.year + 2,
      ), // Последняя доступная дата (+2 года от текущего)
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

  // Pull-to-refresh: аннулирование текущего кэша и перезагрузка из сети
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

  // --- Хелпер SnackBar ---
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scheduleDateDisplay =
          '${_formatDateRangeForDisplay(_startDate, _endDate)} (Загрузка...)';
      _dailySchedules = [];
    });
    String objectId =
        ''; // Переменная для ID объекта
    String rasParamName = '';
    final String startDateString = _formatDateForApi(startDate);
    final String endDateString = _formatDateForApi(endDate);

    switch (scheduleType) {
      case ScheduleType.grup:
        rasParamName = 'gruppa';
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
      rasParamName: objectId, // Используем выбранный ID
      'calendar': startDateString,
      'calendar2': endDateString,
      'ras': _getRasTypeValue(scheduleType), // Конвертим ScheduleType в String
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
      return; // Данные из кеша, не делаем запрос
    }

    try {
      // POST запрос
      http.Response response;
      try {
        response = await http.post(
          Uri.parse(_scheduleApiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));
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
          // игноринуем ошибки
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
        // Загружено из сети
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
          'Не удалось загрузить расписание: ${e.toString()}';

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
    final locale = Localizations.localeOf(context).toString();
    try {
      // Если даты совпадают, показываем один день
      if (start.year == end.year &&
          start.month == end.month &&
          start.day == end.day) {
        return DateFormat(
          'd MMMM yyyy',
          locale,
        ).format(start);
      }
      // Если даты в одном месяце и году
      else if (start.year == end.year && start.month == end.month) {
        return '${DateFormat('d', locale).format(start)} - ${DateFormat('d MMMM yyyy', locale).format(end)}';
      }
      // Если даты в одном году, но разных месяцах
      else if (start.year == end.year) {
        return '${DateFormat('d MMMM', locale).format(start)} - ${DateFormat('d MMMM yyyy', locale).format(end)}';
      }
      // Иначе показываем полный диапазон
      else {
        return '${DateFormat('d MMMM yyyy', locale).format(start)} - ${DateFormat('d MMMM yyyy', locale).format(end)}';
      }
    } catch (e) {
      print("Ошибка форматирования диапазона дат: $e");
      return '${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}';
    }
  }

  Widget _buildScheduleTypeButtons(Orientation orientation) {
    final isLandscape = orientation == Orientation.landscape;

    return Row(
      children: [
        Expanded(
          child: SegmentedButton<ScheduleType>(
            segments: [
              ButtonSegment(
                value: ScheduleType.grup,
                label: isLandscape ? null : Text(AppLocalizations.of(context)!.group),
                icon: const Icon(Icons.group),
              ),
              ButtonSegment(
                value: ScheduleType.prep,
                label: isLandscape ? null : Text(AppLocalizations.of(context)!.teacher),
                icon: const Icon(Icons.person),
              ),
              ButtonSegment(
                value: ScheduleType.aud,
                label: isLandscape ? null : Text(AppLocalizations.of(context)!.room),
                icon: const Icon(Icons.meeting_room),
              ),
            ],
            selected: <ScheduleType>{_rasType},
            onSelectionChanged: (Set<ScheduleType> newSelection) {
              if (newSelection.isNotEmpty) {
                _setScheduleType(newSelection.first);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObjectSelector() {
    String hintText;
    List<DropdownMenuItem<dynamic>>? items = [];
    switch (_rasType) {
      case ScheduleType.grup:
        hintText = AppLocalizations.of(context)!.group;
        items =
            _availableGroups.map((group) {
              return DropdownMenuItem<GroupInfo>(
                value: group,
                child: Text(group.name),
              );
            }).toList();
        break;
      case ScheduleType.prep:
        hintText = AppLocalizations.of(context)!.teacher;
        items =
            _availableTeachers.map((teacher) {
              return DropdownMenuItem<TeacherInfo>(
                value: teacher,
                child: Text(teacher.name),
              );
            }).toList();
        break;
      case ScheduleType.aud:
        hintText = AppLocalizations.of(context)!.room;
        items =
            _availableRooms.map((room) {
              return DropdownMenuItem<RoomInfo>(
                value: room,
                child: Text(room.name),
              );
            }).toList();
        break;
    }

    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade500),
        ),
        child: DropdownButton<dynamic>(
          value: _rasType == ScheduleType.grup
              ? _selectedGroup
              : _rasType == ScheduleType.prep
                  ? _selectedTeacher
                  : _rasType == ScheduleType.aud
                      ? _selectedRoom
                      : null,
          hint: Text(hintText),
          isExpanded: true,
          icon: Icon(
            Icons.group_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          onChanged: (dynamic newValue) {
            setState(() {
              _errorMessage = null;
              _dailySchedules = [];
              if (newValue != null) {
                if (_rasType == ScheduleType.grup) {
                  _selectedGroup = newValue as GroupInfo;
                } else if (_rasType == ScheduleType.prep) {
                  _selectedTeacher = newValue as TeacherInfo;
                } else if (_rasType == ScheduleType.aud) {
                  _selectedRoom = newValue as RoomInfo;
                }
                _loadScheduleData(_startDate, _endDate, _rasType, newValue);
              }
            });
          },
          items: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Кликабельный заголовок с диапазоном дат
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: InkWell(
                      onTap: _isLoading
                          ? null
                          : () => _selectDateRange(
                                context,
                              ),
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20.0,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8.0),
                            Flexible(
                              child: Text(
                                _scheduleDateDisplay,
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 8.0),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Делает разделитель прозрачным
                    child: ExpansionTile(
                      title: Text(AppLocalizations.of(context)!.filters),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0
                          ),
                          child: _buildObjectSelector(),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                          child: _buildScheduleTypeButtons(orientation),
                        ),
                        SizedBox(height: 4.0),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                          child: TextField(
                            controller: _filterController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.search,
                              // prefixIcon: Icon(Icons.filter_list),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              suffixIcon: _filterText.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () => _filterController.clear(),
                                )
                              : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
                              ),
                              suffixIconConstraints: BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Homework>>(
                      stream: _homeworkStream,
                      builder: (context, homeworkSnapshot) {
                        final allHomeworks = homeworkSnapshot.data ?? [];
                        return _buildBody(allHomeworks);
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Ландшафтная (горизонтальная) ориентация

              // TODO: добавить фильтр в горизонтальную ориентацию и исправить исключение при повороте экрана
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => _selectDateRange(context),
                              borderRadius: BorderRadius.circular(8.0),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 1.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 20.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    SizedBox(width: 4.0),
                                    Flexible(
                                      child: Text(
                                        _scheduleDateDisplay,
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(width: 4.0),
                                    Icon(Icons.arrow_drop_down,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildObjectSelector(),
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _buildScheduleTypeButtons(orientation),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Homework>>(
                      stream: _homeworkStream,
                      builder: (context, homeworkSnapshot) {
                        final allHomeworks = homeworkSnapshot.data ?? [];
                        return _buildBody(allHomeworks);
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody(List<Homework> allHomeworks) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(getRandomEmoji(), style: TextStyle(fontSize: 72, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.nothingFound,
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  ],
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
                child: Builder(builder: (context) {
                  final locale = Localizations.localeOf(context).toString();
                  String formattedDate = DateFormat(
                    'EEEE, d MMMM', locale,
                  ).format(dailySchedule.date);
                  if (formattedDate.isNotEmpty) {
                    formattedDate = formattedDate[0].toUpperCase() + formattedDate.substring(1);
                  }
                  return Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontVariations: [
                      const FontVariation('wdth', 150)
                    ],
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  );
                }),
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
                      filterText: _filterText,
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

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}

enum ScheduleType { grup, prep, aud }
