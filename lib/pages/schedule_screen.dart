import 'package:flutter/material.dart';
import '../models/schedule_card.dart';
// import 'package:my_asiec_lite/models/schedule_entry.dart';
// import 'package:my_asiec_lite/models/parser_schedule.dart';
import '../models/daily_schedule.dart';
import '../data/groups.dart';
import '../models/group_info.dart';
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
  List<DailySchedule> _dailySchedules = []; // Теперь храним список расписаний по дням
  DateTime _startDate = DateTime.now(); // Дата начала диапазона
  DateTime _endDate = DateTime.now();   // Дата конца диапазона
  String _scheduleDateDisplay = 'Загрузка...'; // Строка для отображения диапазона
  bool _isLoading = true;
  String? _errorMessage;

  List<GroupInfo> _availableGroups = []; // Список доступных групп
  GroupInfo? _selectedGroup; // Выбранная группа (может быть null сначала)

  // --- Константы для запроса (остаются как были) ---
  final String _scheduleApiUrl = 'https://asiec.ru/ras/ras.php'; // ЗАМЕНИ!
  // final String _groupId = '3afb102a-1ea1-11ed-abe0-00155d879809%0A'; // ЗАМЕНИ!
  final String _rasType = 'GRUP';
  final String _dostup = 'true';

 @override
  void initState() {
    super.initState();
    _initializeGroups(); // Вызываем инициализацию
    if (_selectedGroup != null) {
        _loadScheduleData(_startDate, _endDate, _selectedGroup!);
    } else {
        // ... (обработка ошибки, если нет групп) ...
    }
  }

  // --- Обновленный метод инициализации ---
  void _initializeGroups() {
    // Просто присваиваем импортированную константу нашей переменной состояния
    _availableGroups = availableGroupsData;

    // Логика выбора группы по умолчанию остается той же,
    // но теперь использует константу defaultGroupId из нового файла
    if (_availableGroups.isNotEmpty) {
      _selectedGroup = _availableGroups.firstWhere(
           (g) => g.id == defaultGroupId, // Используем ID по умолчанию
           orElse: () => _availableGroups.first, // Если не нашли, берем первую
      );
    } else {
        _selectedGroup = null;
    }
    print("Доступные группы инициализированы из файла. Выбрана: $_selectedGroup");
  }

  // --- Форматирование дат (остаются как были) ---
  // ... _formatDateForApi, _formatDateRangeForDisplay ...

  // --- Функция вызова DateRangePicker (остается как была) ---
  // ... _selectDateRange ...
  // Важно: внутри _selectDateRange, вызов _loadScheduleData теперь должен передавать _selectedGroup!
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
      builder: (context, child) { // Опционально: кастомизация темы пикера
          return Theme(
            data: ThemeData.light().copyWith( // Или ThemeData.dark()
              colorScheme: ColorScheme.light( // Или ColorScheme.dark()
                 primary: Colors.blue, // Основной цвет
                 onPrimary: Colors.white, // Цвет текста на основном цвете
              )
            ),
            child: child!,
          );
      }
    );
    if (picked != null) {
      final newStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final newEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
       if (newStartDate != _startDate || newEndDate != _endDate) {
           if (_selectedGroup != null) { // Проверяем, выбрана ли группа
             _loadScheduleData(newStartDate, newEndDate, _selectedGroup!);
           } else {
               // Можно показать ошибку или ничего не делать
               print("Невозможно загрузить расписание: группа не выбрана");
               _showSnackBar(context, "Сначала выберите группу");
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
  Future<void> _loadScheduleData(DateTime startDate, DateTime endDate, GroupInfo group) async {
     // Проверяем mounted перед первым setState
     if (!mounted) return;
     setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Отображаем текущий диапазон и группу + "Загрузка..."
      _scheduleDateDisplay = '${_formatDateRangeForDisplay(_startDate, _endDate)} (Загрузка...)';
      _dailySchedules = [];
    });

    final String startDateString = _formatDateForApi(startDate);
    final String endDateString = _formatDateForApi(endDate);

    final Map<String, String> body = {
      'dostup': _dostup,
      'gruppa': group.id, // <-- Используем ID выбранной группы
      'calendar': startDateString,
      'calendar2': endDateString,
      'ras': _rasType,
    };

    print("Отправка запроса для группы ${group.name} ($startDateString - $endDateString)");

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
    } catch (e) {
       if (!mounted) return;
       setState(() {
         // Сохраняем даты и группу
         _startDate = startDate;
         _endDate = endDate;
         // _selectedGroup не меняем при ошибке
         _scheduleDateDisplay = '${_formatDateRangeForDisplay(_startDate, _endDate)}';
         _errorMessage = 'Не удалось загрузить расписание для группы ${group.name}: $e';
         _isLoading = false;
       });
       print("Ошибка при загрузке расписания для группы ${group.id}: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание ${_selectedGroup?.name ?? ""}'),
        // ... (настройки AppBar)
      ),
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
                     Icon(Icons.calendar_today_outlined, size: 20.0, color: Colors.black54), // Иконка календаря
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
                     Icon(Icons.arrow_drop_down, color: Colors.black54),
                   ],
                ),
              ),
            ),
          ),

           if (_availableGroups.isNotEmpty) // Показываем, только если есть группы
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Уменьшаем вертикальный отступ
              child: DropdownButtonHideUnderline( // Убираем стандартное подчеркивание
                 child: Container( // Оборачиваем в контейнер для фона и скругления
                   padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                   decoration: BoxDecoration(
                       color: Colors.white, // Или цвет из темы
                       borderRadius: BorderRadius.circular(8.0),
                       border: Border.all(color: Colors.grey.shade300) // Легкая граница
                   ),
                   child: DropdownButton<GroupInfo>(
                    value: _selectedGroup, // Текущее выбранное значение
                    isExpanded: true,      // Растягиваем на всю ширину
                    icon: Icon(Icons.group_outlined, color: Colors.black54), // Иконка справа
                    hint: Text('Выберите группу'), // Подсказка, если _selectedGroup == null
                    onChanged: _isLoading ? null : (GroupInfo? newValue) { // Блокируем во время загрузки
                      if (newValue != null && newValue != _selectedGroup) {
                        print("Выбрана новая группа: ${newValue.name}");
                        setState(() {
                          _selectedGroup = newValue; // Обновляем выбранную группу
                        });
                        // Загружаем данные для новой группы и текущего диапазона дат
                        _loadScheduleData(_startDate, _endDate, newValue);
                      }
                    },
                    items: _availableGroups
                        .map<DropdownMenuItem<GroupInfo>>((GroupInfo group) {
                      return DropdownMenuItem<GroupInfo>(
                        value: group, // Значение элемента - сам объект GroupInfo
                        child: Text(
                           group.name, // Отображаемый текст - имя группы
                           overflow: TextOverflow.ellipsis, // Многоточие для длинных названий
                        ),
                      );
                    }).toList(), // Преобразуем итератор в список
                  ),
                 ),
              ),
            )
          else // Если список групп пуст (например, не загрузился)
             Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: Text('Список групп недоступен', style: TextStyle(color: Colors.red))
             ),

           SizedBox(height: 8.0), // Небольшой отступ после дропдауна

          // Тело экрана: загрузка, ошибка или список
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  // Метод _buildBody() остается таким же, как в предыдущем примере
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
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                 Text( // Показываем саму ошибку ниже
                   _errorMessage!, // Тут само исключение
                   style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                   textAlign: TextAlign.center,
                 ),
                SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _selectedGroup == null ? null : () => _loadScheduleData(_startDate, _endDate, _selectedGroup!),
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
                        color: Colors.black87,
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
                          return ScheduleCard(entry: entry);
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

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }