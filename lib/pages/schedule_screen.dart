import 'dart:io';

import 'package:flutter/material.dart';
import '../models/schedule_card.dart';
// import '../models/schedule_entry.dart';
// import 'package:my_asiec_lite/models/schedule_entry.dart';
// import 'package:my_asiec_lite/models/parser_schedule.dart';
import '../models/daily_schedule.dart';

import '../data/groups.dart';
import '../data/rooms.dart';
import '../data/teachers.dart';
import '../models/group_info.dart';
import '../models/teacher_info.dart';
import '../models/room_info.dart';
import '../services/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


// Импортируй сюда классы ScheduleEntry и ScheduleCard, если они в других файлах

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // --- Состояние ---
  ScheduleType _rasType = ScheduleType.grup;
  List<DailySchedule> _dailySchedules = []; // Теперь храним список расписаний по дням
  DateTime _startDate = DateTime.now(); // Дата начала диапазона
  DateTime _endDate = DateTime.now();   // Дата конца диапазона
  String _scheduleDateDisplay = 'Загрузка...'; // Строка для отображения диапазона
  bool _isLoading = true;
  String? _errorMessage;

  List<GroupInfo> _availableGroups = []; // Список доступных групп
  List<TeacherInfo> _availableTeachers = []; // Список доступных групп
  List<RoomInfo> _availableRooms = []; // Список доступных групп
  GroupInfo? _selectedGroup; // Выбранная группа (может быть null сначала)
  TeacherInfo? _selectedTeacher;
  RoomInfo? _selectedRoom;

  // --- Константы для запроса (остаются как были) ---
  final String _scheduleApiUrl = 'https://asiec.ru/ras/ras.php'; // ЗАМЕНИ!
  // final String _groupId = '3afb102a-1ea1-11ed-abe0-00155d879809%0A'; // ЗАМЕНИ!
  final String _dostup = 'true';

  DailySchedule? dailyScheduleForCard(DateTime date) {
    try {
      return _dailySchedules.firstWhere((dailySchedule) =>
          dailySchedule.date.year == date.year &&
          dailySchedule.date.month == date.month &&
          dailySchedule.date.day == date.day);
    } catch (e) {
      return null; // Не нашли расписание для этой даты
    }
  }
  void _setScheduleType(ScheduleType newType) {
    dynamic defaultSelectedObject = null; // Переменная для объекта по умолчанию

    switch (newType) {
      case ScheduleType.grup:
        defaultSelectedObject = _selectedGroup; // Пытаемся использовать _selectedGroup по умолчанию
        if (defaultSelectedObject == null && _availableGroups.isNotEmpty) {
          defaultSelectedObject = _availableGroups.first; // Если нет сохраненной, берем первый из списка
        }
        break;
      case ScheduleType.prep:
        defaultSelectedObject = _selectedTeacher; // Пытаемся использовать _selectedTeacher по умолчанию
        if (defaultSelectedObject == null && _availableTeachers.isNotEmpty) {
          defaultSelectedObject = _availableTeachers.first; // Если нет сохраненного, берем первый из списка
        }
        break;
      case ScheduleType.aud:
        if (_availableRooms.isNotEmpty) {
          defaultSelectedObject = _availableRooms.first; // Для аудиторий всегда берем первый из списка, если есть
        }
        break;
    }

    setState(() {
      _rasType = newType; // Обновляем тип расписания
      _errorMessage = null; // Сбрасываем сообщение об ошибке
      _dailySchedules.clear(); // Очищаем текущее расписание

      // --- ВЫЗЫВАЕМ _loadScheduleData С ID ПО УМОЛЧАНИЮ (ИЛИ ПЕРВЫМ ИЗ СПИСКА)! ---
      if (defaultSelectedObject != null) {
        _loadScheduleData(_startDate, _endDate, newType, defaultSelectedObject); // <--- Загружаем данные, если есть объект по умолчанию
      }
    });
  }
  String _getRasTypeValue(ScheduleType type) {
    switch (type) {
      case ScheduleType.grup:
        return 'GRUP'; // <--- Значение для расписания группы (уточни, если другое!)
      case ScheduleType.prep:
        return 'PREP'; // <--- Значение для расписания преподавателя (уточни!)
      case ScheduleType.aud:
        return 'AUD';  // По умолчанию - группа, на всякий случай
    }
  }
 @override
 void initState() {
    super.initState();
    _initializeScheduleObjects(); // Инициализируем список И выбранную группу
    // Загружаем данные, если группа выбрана
    if (_selectedGroup != null) {
        _loadScheduleData(_startDate, _endDate, _rasType, _selectedGroup);
    } else {
        // Ошибка - не удалось определить группу по умолчанию
        setState(() {
            _isLoading = false;
            _errorMessage = "Группа по умолчанию не найдена или не выбрана в настройках.";
        });
    }
 }

 void _initializeScheduleObjects() {
    // Заполняем список доступных групп
    _availableGroups = availableGroupsData;
    _availableTeachers = availableTeachersData; // Заполняем список доступных преподавателей
    _availableRooms = availableRoomsData; // Заполняем список доступных аудиторий

    // --- ЛОГИКА ВЫБОРА ГРУППЫ ПО УМОЛЧАНИЮ ИЗ НАСТРОЕК ---
    final String? savedGroupId = settingsService.getDefaultGroupId(); // Получаем сохраненный ID
    _selectedGroup = null; // Сбрасываем на всякий случай

    if (savedGroupId != null) {
        // Ищем группу с сохраненным ID в нашем списке доступных групп
        try {
            _selectedGroup = _availableGroups.firstWhere((g) => g.id == savedGroupId);
        } catch (e) {
            print("Сохраненная группа $savedGroupId не найдена в списке доступных.");
            _selectedGroup = null; // Не нашли, сбрасываем
        }
    }

    // Если группа не была сохранена ИЛИ сохраненная не найдена,
    // выбираем первую доступную группу как запасной вариант
    if (_selectedGroup == null && _availableGroups.isNotEmpty) {
        _selectedGroup = _availableGroups.first;
        print("Группа по умолчанию не найдена в настройках, выбрана первая: ${_selectedGroup?.name}");
        // Опционально: можно сразу сохранить эту первую группу как дефолтную
        // settingsService.setDefaultGroupId(_selectedGroup?.id);
    } else if (_availableGroups.isEmpty) {
         print("Список доступных групп пуст!");
    }

    final String? savedTeacherId = settingsService.getDefaultTeacherId(); // <--- Получаем сохраненный ID преподавателя
    _selectedTeacher = null; // Сбрасываем на всякий случай

    if (savedTeacherId != null) {
      try {
        _selectedTeacher = _availableTeachers.firstWhere( // <--- Ищем преподавателя
          (t) => t.id == savedTeacherId,
          // orElse: () => null,
        );
      } catch (e) {
        print("Сохраненный преподаватель $savedTeacherId не найден в списке доступных.");
        _selectedTeacher = null; // Не нашли, сбрасываем
      }
    }

    if (_selectedTeacher == null && _availableTeachers.isNotEmpty) {
      _selectedTeacher = _availableTeachers.first; // <--- Выбираем первого преподавателя, если нет сохраненного
      print("Преподаватель по умолчанию не найден в настройках, выбран первый: ${_selectedTeacher?.name}");
    } else if (_availableTeachers.isEmpty) {
      print("Список доступных преподавателей пуст!");
    }

    print("Инициализация ScheduleScreen. Выбрана группа: $_selectedGroup");

    final String? savedRoomId = settingsService.getDefaultRoomId(); // <--- Получаем сохраненный ID аудитории
    _selectedRoom = null; // Сбрасываем на всякий случай

    if (savedRoomId != null) {
      try {
        _selectedRoom = _availableRooms.firstWhere( // <--- Ищем аудиторию
          (r) => r.id == savedRoomId,);
      } catch (e) {
        print("Сохраненная аудитория $savedRoomId не найдена в списке доступных.");
        _selectedRoom = null; // Не нашли, сбрасываем
      }
    }

    if (_selectedRoom == null && _availableRooms.isNotEmpty) {
      _selectedRoom = _availableRooms.first; // <--- Выбираем первую аудиторию, если нет сохраненной
      print("Аудитория по умолчанию не найдена в настройках, выбрана первая: ${_selectedRoom?.name}");
    } else if (_availableRooms.isEmpty) {
      print("Список доступных аудиторий пуст!");
    }


    print("Инициализация ScheduleScreen. Группа: $_selectedGroup, Преподаватель: $_selectedTeacher, Аудитория: $_selectedRoom");
 }



  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(_startDate.year - 1), // Год назад от текущей даты начала
      lastDate: DateTime(_endDate.year + 1),   // Год вперед от текущей даты конца
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
  
        return Theme(
          data: pickerThemeData,
          child: child!,
        );
      },
    );
  
    if (picked != null) {
      final newStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final newEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
  
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
  // --- Хелпер для показа SnackBar ---
  void _showSnackBar(BuildContext context, String message) {
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(message), duration: Duration(seconds: 2)),
     );
  }

  // --- Парсинг даты из HTML (остается) ---
  // ... _parseDateFromHtml ...

  // --- Обновленная функция загрузки данных ---
  // Теперь принимает выбранную группу как параметр
  Future<void> _loadScheduleData(DateTime startDate, DateTime endDate, ScheduleType scheduleType, dynamic selectedObject) async {
     // Проверяем mounted перед первым setState
     if (!mounted) return;
     setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Отображаем текущий диапазон и группу + "Загрузка..."
      _scheduleDateDisplay = '${_formatDateRangeForDisplay(_startDate, _endDate)} (Загрузка...)';
      _dailySchedules = [];
    });
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dailySchedules.clear();
    });
    String objectId = ''; // Переменная для ID объекта (группы, преподавателя, аудитории)
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
      rasParamName: objectId, // <-- Используем ID выбранной группы
      'calendar': startDateString,
      'calendar2': endDateString,
      'ras': _getRasTypeValue(_rasType), // Convert ScheduleType to String
    };


    try {
      final response = await http.post(
        Uri.parse(_scheduleApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ); // Запрос как раньше, но с ID группы

      if (!mounted) return;

      if (response.statusCode == 200) {
        // ... (парсинг HTML как раньше) ...
        final parsedData = parseScheduleHtmlMultiDay(response.body);

        if (!mounted) return;
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
          // _selectedGroup уже должен быть правильным, т.к. мы его передали
          _dailySchedules = parsedData;
          _scheduleDateDisplay = '${_formatDateRangeForDisplay(_startDate, _endDate)}'; // Обновляем отображение
          _isLoading = false;
        });
      } else { /* ... обработка ошибки сервера ... */ }
    } catch (e) { // Ловим исключение
      // ignore: unused_local_variable
      String errorMessageText = 'Не удалось загрузить расписание: $e'; // Стандартное сообщение

      // --- НОВАЯ ЛОГИКА ПРОВЕРКИ ИСКЛЮЧЕНИЯ ---
      if (e is http.ClientException) { // Проверяем, является ли ошибка ClientException
        if (e.innerException is SocketException) { // Проверяем, что innerException - SocketException
          final socketException = e.innerException as SocketException;
          if (socketException.osError != null && socketException.osError!.errno == 110 &&
              socketException.message.contains('Connection timed out')) {
            // --- Вот оно, наше исключение "Connection timed out" ---
            errorMessageText = 'Сервер не отвечает. Пожалуйста, попробуйте позже.'; // Меняем сообщение
          }
        }
      }
    }
  }

  // --- Форматирование дат (остаются или немного адаптируются) ---
  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Новая функция для форматирования диапазона для отображения
  String _formatDateRangeForDisplay(DateTime start, DateTime end) {
    final ruLocale = 'ru_RU';
    try {
      // Если даты совпадают, показываем одну дату
      if (start.year == end.year && start.month == end.month && start.day == end.day) {
        return DateFormat('d MMMM yyyy', ruLocale).format(start); // Добавим год для ясности
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Равномерное распределение кнопок по ширине
      children: [
        _buildScheduleTypeButton(
          type: ScheduleType.grup,
          text: 'Группа',
        ),
        _buildScheduleTypeButton(
          type: ScheduleType.prep,
          text: 'Преподаватель',
        ),
        _buildScheduleTypeButton(
          type: ScheduleType.aud,
          text: 'Аудитория',
        ),
      ],
    );
  }
  Widget _buildScheduleTypeButton({required ScheduleType type, required String text}) {
    final isSelected = _rasType == type; // Проверяем, является ли кнопка "выбранной"

    final textColor = isSelected
        ? Theme.of(context).colorScheme.onPrimaryContainer // Цвет текста для ElevatedButton (на залитом фоне)
        : Theme.of(context).colorScheme.onSurface; // Цвет текста для OutlinedButton (на "плоском" фоне)

    return isSelected
        ? ElevatedButton( // Если ВЫБРАНА - используем ElevatedButton
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer, // Цвет фона для выбранной кнопки
            ),
            onPressed: () {
              _setScheduleType(type);
            },
            child: Text(text, style: TextStyle(color: textColor),),
          )
        : OutlinedButton( // Если НЕ ВЫБРАНА - используем OutlinedButton
            onPressed: () {
              _setScheduleType(type);
            },
            child: Text(text),
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
        items = _availableGroups.map((group) { // Используем _groupList
          return DropdownMenuItem<GroupInfo>( // Тип элемента - GroupInfo
            value: group,
            child: Text(group.name),
          );
        }).toList();
        break;
      case ScheduleType.prep:
        rasParamName = 'prepod';
        hintText = 'Выберите преподавателя'; // Hint для преподавателей
        items = _availableTeachers.map((teacher) { // Используем _groupList
          return DropdownMenuItem<TeacherInfo>( // Тип элемента - GroupInfo
            value: teacher,
            child: Text(teacher.name),
          );
        }).toList();
        break;
      case ScheduleType.aud:
      rasParamName = 'auditoria';
        hintText = 'Выберите аудиторию'; // Hint для аудиторий
        items = _availableRooms.map((room) { // Используем _groupList
          return DropdownMenuItem<RoomInfo>( // Тип элемента - GroupInfo
            value: room,
            child: Text(room.name),
          );
        }).toList();
        break;
    }

    return  Padding( // <--- Оборачиваем Padding, как и раньше
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Уменьшаем вертикальный отступ
      child: DropdownButtonHideUnderline( // Убираем стандартное подчеркивание
          child: Container( // Оборачиваем в контейнер для фона и скругления
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              //  color: Colors.white, // Или цвет из темы
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade500) // Легкая граница
            ),
            child: DropdownButton<dynamic>( // Тип DropdownButton теперь dynamic (может быть GroupInfo, TeacherInfo, RoomInfo в будущем)
            value: _rasType == ScheduleType.grup
              ? _selectedGroup // Для групп - _selectedGroup
              : _rasType == ScheduleType.prep
                  ? _selectedTeacher // Для преподавателей - _selectedTeacher
                  : _rasType == ScheduleType.aud
                      ? _selectedRoom // Для аудиторий - _selectedRoom (нужно добавить _selectedRoom!)
                      : null, // <--- ИСПРАВЛЕНО! value для групп!
            hint: Text(hintText), // Динамический hintText
            isExpanded: true,      // Растягиваем на всю ширину
            icon: Icon(Icons.group_outlined, color: Theme.of(context).colorScheme.primary), // Иконка справа
            onChanged: (dynamic newValue) { // onChanged теперь принимает dynamic
                      setState(() {
                        _errorMessage = null;
                        _dailySchedules.clear();
                        if (newValue != null) {
                          if (_rasType == ScheduleType.grup) {
                            _selectedGroup = newValue as GroupInfo; // Обновляем _selectedGroup
                          } else if (_rasType == ScheduleType.prep) {
                            _selectedTeacher = newValue as TeacherInfo; // Обновляем _selectedTeacher
                          } else if (_rasType == ScheduleType.aud) { // Раскомментируй, когда добавим RoomInfo
                            _selectedRoom = newValue as RoomInfo; // Обновляем _selectedRoom
                           }
                          // --- ЯВНО ПЕРЕСТРАИВАЕМ _buildObjectSelector() ДЛЯ ОБНОВЛЕНИЯ UI! ---
                          _buildObjectSelector(); // <--- ВЫЗЫВАЕМ _buildObjectSelector() ЕЩЕ РАЗ! (после setState)
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
          crossAxisAlignment: CrossAxisAlignment.stretch, // Заголовки дней будут на всю ширину
          children: [
            // --- Кликабельный заголовок с диапазоном дат ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: InkWell( // Делаем область кликабельной
                onTap: _isLoading ? null : () => _selectDateRange(context), // Вызываем пикер по тапу (блокируем во время загрузки)
                borderRadius: BorderRadius.circular(8.0), // Скругление для эффекта при нажатии
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Внутренний отступ для красоты
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.center, // Центрируем текст и иконку
                     children: [
                       Icon(Icons.calendar_today_outlined, size: 20.0, color: Theme.of(context).colorScheme.primary), // Иконка календаря
                       SizedBox(width: 8.0),
                       Flexible( // Чтобы текст переносился, если диапазон длинный
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
                       Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
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
              child: _buildBody(),
            ),
          ],
        ),
        // backgroundColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }


    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  //_errorMessage!, // Используем сообщение об ошибке как есть
                  'Не удалось загрузить расписание для группы ${_selectedGroup?.name ?? "N/A"}.',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
                Text( // Показываем саму ошибку ниже
                  _errorMessage!, // Тут само исключение
                  style: TextStyle(color: Theme.of(context).colorScheme.errorContainer, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _selectedGroup == null ? null : () => _loadScheduleData(_startDate, _endDate, _rasType, null),
                  child: Text('Повторить попытку')
              )
            ],
          ),
        ),
      );
    }
     if (_dailySchedules.isEmpty) {
      return Center(
        child: Text(
          'Нет данных на выбранный период для группы ${_selectedGroup?.name ?? ""}', // Добавили группу
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }
    // Используем ListView для отображения дней и их пар
    return ListView.builder(
        padding: const EdgeInsets.only(bottom: 16.0), // Отступ снизу списка
        itemCount: _dailySchedules.length, // Количество дней = количество элементов в главном списке
        itemBuilder: (context, dayIndex) {
            final dailySchedule = _dailySchedules[dayIndex];

            // Создаем столбец для каждого дня: Заголовок + список пар (или сообщение "Пар нет")
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Заголовок дня ---
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
                  child: Text(
                    // Форматируем дату дня (например, "Понедельник, 15 Октября")
                    DateFormat('EEEE, d MMMM', 'ru_RU').format(dailySchedule.date),
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
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                      child: Text(
                        'Пар нет',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      ),
                    )
                else
                    // Используем Column, т.к. пар обычно не так много за день,
                    // и это проще чем вложенный ListView.
                    // Если пар может быть ОЧЕНЬ много, можно заменить на ListView(shrinkWrap: true, physics: NeverScrollableScrollPhysics())
                    Column(
                      children: dailySchedule.entries.map((entry) {
                          return ScheduleCard(entry: entry, allEntriesForDay: dailySchedule.entries);
                      }).toList(), // Преобразуем результат map в список виджетов
                    ),

                // Добавляем разделитель между днями, кроме последнего
                if (dayIndex < _dailySchedules.length - 1)
                    Divider(height: 24.0, thickness: 1.0, indent: 16.0, endIndent: 16.0),

              ],
            );
        },
    );
  }
}

extension on OSError {
  get errno => null;
}

extension on http.ClientException {
  get innerException => null;
}

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

enum ScheduleType {
  grup,
  prep,
  aud,
}