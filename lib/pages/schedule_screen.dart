import 'package:flutter/material.dart';
import 'package:my_asiec_lite/models/schedule_card.dart';
// import 'package:my_asiec_lite/models/schedule_entry.dart';
// import 'package:my_asiec_lite/models/parser_schedule.dart';
import 'package:my_asiec_lite/models/daily_schedule.dart';
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

  // --- Константы для запроса (остаются как были) ---
  final String _scheduleApiUrl = 'https://asiec.ru/ras/ras.php'; // ЗАМЕНИ!
  final String _groupId = '3afb102a-1ea1-11ed-abe0-00155d879809%0A'; // ЗАМЕНИ!
  final String _rasType = 'GRUP';
  final String _dostup = 'true';

  @override
  void initState() {
    super.initState();
    // Загружаем расписание для СЕГОДНЯШНЕЙ даты при первом запуске
    _loadScheduleData(_startDate, _endDate);
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

  // --- Функция вызова DateRangePicker ---
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

    // Если пользователь выбрал диапазон
    if (picked != null) {
      // Сбрасываем время на полночь для корректного сравнения и запросов
      final newStartDate = DateTime(picked.start.year, picked.start.month, picked.start.day);
      final newEndDate = DateTime(picked.end.year, picked.end.month, picked.end.day);

       // Проверяем, изменился ли диапазон перед загрузкой
       if (newStartDate != _startDate || newEndDate != _endDate) {
          print("Выбран новый диапазон: $newStartDate - $newEndDate");
          // Обновляем состояние и запускаем загрузку
          // setState тут не нужен, т.к. _loadScheduleData его вызовет
          _loadScheduleData(newStartDate, newEndDate);
       } else {
           print("Диапазон не изменился.");
       }
    }
  }

  // --- Функция парсинга даты из HTML (остается как есть) ---
  DateTime? _parseDateFromHtml(String? htmlDateString) {
      // ... (код как в предыдущем примере) ...
      if (htmlDateString == null || !htmlDateString.contains(',')) return null;
      try {
          final datePart = htmlDateString.split(',').last.trim(); // "15.10.2024"
          return DateFormat('dd.MM.yyyy').parseStrict(datePart);
      } catch (e) {
          print("Не удалось распознать дату из HTML: '$htmlDateString'. Ошибка: $e");
          return null;
      }
  }


  // --- Обновленная функция загрузки данных ---
  Future<void> _loadScheduleData(DateTime startDate, DateTime endDate) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Показываем предыдущий диапазон + "Загрузка..." пока не загрузится новый
      _scheduleDateDisplay = '${_formatDateRangeForDisplay(_startDate, _endDate)} (Загрузка...)';
      _dailySchedules = []; // Очищаем предыдущие данные
    });

    final String startDateString = _formatDateForApi(startDate);
    final String endDateString = _formatDateForApi(endDate);

    final Map<String, String> body = {
      'dostup': _dostup,
      'gruppa': _groupId,
      'calendar': startDateString,
      'calendar2': endDateString, // Используем endDate
      'ras': _rasType,
    };

    print("Отправка запроса на $_scheduleApiUrl с датами: $startDateString - $endDateString; полный запрос: $body");

    try {
      final response = await http.post(
        Uri.parse(_scheduleApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      print("Ответ получен. Статус: ${response.statusCode}");

      if (response.statusCode == 200) {
        final htmlContent = response.body;

        // --- ВАЖНО: Используем обновленный парсер ---
        final parsedData = parseScheduleHtmlMultiDay(htmlContent); // Имя новой функции парсера

        setState(() {
          _startDate = startDate; // Обновляем даты в состоянии
          _endDate = endDate;
          _dailySchedules = parsedData; // Сохраняем сгруппированные данные
          _scheduleDateDisplay = _formatDateRangeForDisplay(_startDate, _endDate); // Обновляем отображаемый диапазон
          _isLoading = false;
        });
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print("Ошибка при загрузке/парсинге расписания: $e");
      setState(() {
         // Сохраняем запрошенные даты, даже если ошибка
         _startDate = startDate;
         _endDate = endDate;
         _scheduleDateDisplay = _formatDateRangeForDisplay(_startDate, _endDate); // Показываем запрошенный диапазон
         _errorMessage = 'Не удалось загрузить расписание: $e';
         _isLoading = false;
      });
    }
  }

  // Вспомогательная функция для парсинга даты из строки HTML (например, "Вторник, 15.10.2024")
  // DateTime? _parseDateFromHtml(String? htmlDateString) {
  //     if (htmlDateString == null || !htmlDateString.contains(',')) return null;
  //     try {
  //         final datePart = htmlDateString.split(',').last.trim(); // "15.10.2024"
  //         // Используем DateFormat для парсинга строки в DateTime
  //         return DateFormat('dd.MM.yyyy').parseStrict(datePart);
  //     } catch (e) {
  //         print("Не удалось распознать дату из HTML: '$htmlDateString'. Ошибка: $e");
  //         return null;
  //     }
  // }

  // Функции для переключения дней (будут вызываться кнопками)
  // void _goToPreviousDay() {
  //     final previousDay = _currentDate.subtract(Duration(days: 1));
  //     _loadScheduleData(previousDay);
  // }

  // void _goToNextDay() {
  //     final nextDay = _currentDate.add(Duration(days: 1));
  //     _loadScheduleData(nextDay);
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание'),
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

          // --- Убрали стрелочки навигации ---

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
      return Center( /* ... код отображения ошибки с кнопкой Повторить ... */ );
    }

    if (_dailySchedules.isEmpty) {
      return Center(
        child: Text(
          'Нет данных на выбранный период',
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

// --- Точка входа main() и класс MyApp ---
// Не забудь добавить их, как в первом примере,
// а также определения ScheduleEntry, ScheduleCard и parseScheduleHtml
// Важно: Для использования DateFormat('d MMMM', 'ru_RU') может потребоваться
// инициализация локали. Добавь в начало функции main():

/*
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Для инициализации локали

void main() async { // main теперь async
  // Инициализируем данные локализации для русского языка перед запуском приложения
  // Это нужно для правильного отображения названий месяцев и дней недели
  WidgetsFlutterBinding.ensureInitialized(); // Обязательно перед асинхронными операциями до runApp
  await initializeDateFormatting('ru_RU', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // ... (как раньше)
    home: ScheduleScreen(),
  // ...
}
*/