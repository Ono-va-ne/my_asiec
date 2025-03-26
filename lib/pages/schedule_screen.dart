import 'package:flutter/material.dart';
import 'package:my_asiec_lite/models/schedule_card.dart';
import 'package:my_asiec_lite/models/schedule_entry.dart';
import 'package:my_asiec_lite/models/parser_schedule.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


// Импортируй сюда классы ScheduleEntry и ScheduleCard, если они в других файлах

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleEntry> _scheduleItems = [];
  String _scheduleDateDisplay = 'Загрузка...'; // Дата для отображения
  DateTime _currentDate = DateTime.now(); // Текущая выбранная дата
  bool _isLoading = true;
  String? _errorMessage;

  // --- Константы для запроса ---
  // ВАЖНО: Замени 'YOUR_SCHEDULE_API_URL' на реальный URL сервера
  final String _scheduleApiUrl = 'https://www.asiec.ru/ras/ras.php';
  // ВАЖНО: Замени 'YOUR_GROUP_ID' на реальный ID группы
  final String _groupId = '71d4f045-3cc0-11ee-9626-00155d879809'; // Твой пример ID
  final String _rasType = 'GRUP';
  final String _dostup = 'true';
  // --- ---

  @override
  void initState() {
    super.initState();
    // Загружаем расписание для СЕГОДНЯШНЕЙ даты при первом запуске
    _loadScheduleData(_currentDate);
  }

  // Функция для форматирования даты в YYYY-MM-DD
  String _formatDateForApi(DateTime date) {
    // Используем пакет intl для надежного форматирования
    return DateFormat('yyyy-MM-dd').format(date);
    // Альтернатива без intl (менее надежна для разных локалей):
    // return date.toIso8601String().substring(0, 10);
  }

  // Функция для форматирования даты для отображения (например, "15 Октября")
  String _formatDateForDisplay(DateTime date) {
    // Убедись, что локаль настроена для русского языка
    // Это можно сделать глобально в main.dart: initializeDateFormatting('ru_RU', null);
    // Или явно указать локаль здесь:
    // final russianLocale = await initializeDateFormatting('ru_RU', null); // может потребоваться async
    try {
      // Пробуем использовать DateFormat для красивого вывода
       return DateFormat('d MMMM', 'ru_RU').format(date); // 'ru_RU' для русских названий месяцев
    } catch (e) {
       // Если форматирование не сработало (например, локаль не найдена),
       // возвращаем простой формат
       print("Ошибка форматирования даты для отображения: $e. Используем резервный формат.");
       return DateFormat('dd.MM.yyyy').format(date);
    }
  }


  // Асинхронная функция для загрузки и парсинга
  Future<void> _loadScheduleData(DateTime dateToLoad) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scheduleDateDisplay = 'Загрузка...'; // Показываем загрузку даты
    });

    // Форматируем дату для API
    final String dateString = _formatDateForApi(dateToLoad);

    // Готовим тело POST-запроса
    final Map<String, String> body = {
      'dostup': _dostup,
      'gruppa': _groupId,
      'calendar': dateString,
      'calendar2': dateString, // Так как нужен только один день
      'ras': _rasType,
    };

    print("Отправка запроса на $_scheduleApiUrl с телом: $body"); // Для отладки

    try {
      // Отправляем POST-запрос
      final response = await http.post(
        Uri.parse(_scheduleApiUrl),
        headers: {
          // Сервер ожидает данные в формате формы
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      print("Ответ получен. Статус: ${response.statusCode}"); // Для отладки

      // Проверяем статус ответа
      if (response.statusCode == 200) {
        // Успех! Получаем HTML как строку
        final htmlContent = response.body;

        // Парсим HTML (твоя функция parseScheduleHtml)
        final parsedData = parseScheduleHtml(htmlContent);

        // Обновляем состояние экрана
        setState(() {
          _currentDate = dateToLoad; // Сохраняем дату, для которой загрузили
          _scheduleItems = parsedData.entries;
          // Пытаемся взять дату из HTML, если она там есть и в ожидаемом формате
          // Иначе используем запрошенную дату
          final parsedHtmlDate = _parseDateFromHtml(parsedData.date); // Новая функция ниже
          _scheduleDateDisplay = _formatDateForDisplay(parsedHtmlDate ?? dateToLoad);

          _isLoading = false;
        });
      } else {
        // Ошибка сервера
        print("Ошибка сервера: ${response.statusCode}, Тело: ${response.body}"); // Для отладки
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      // Ошибка сети или парсинга
      print("Ошибка при загрузке/парсинге расписания: $e"); // Для отладки
      setState(() {
        _errorMessage = 'Не удалось загрузить расписание: $e';
        _isLoading = false;
         // Отображаем запрошенную дату, даже если загрузка не удалась
        _scheduleDateDisplay = _formatDateForDisplay(dateToLoad);
      });
    }
  }

  // Вспомогательная функция для парсинга даты из строки HTML (например, "Вторник, 15.10.2024")
  DateTime? _parseDateFromHtml(String? htmlDateString) {
      if (htmlDateString == null || !htmlDateString.contains(',')) return null;
      try {
          final datePart = htmlDateString.split(',').last.trim(); // "15.10.2024"
          // Используем DateFormat для парсинга строки в DateTime
          return DateFormat('dd.MM.yyyy').parseStrict(datePart);
      } catch (e) {
          print("Не удалось распознать дату из HTML: '$htmlDateString'. Ошибка: $e");
          return null;
      }
  }

  // Функции для переключения дней (будут вызываться кнопками)
  void _goToPreviousDay() {
      final previousDay = _currentDate.subtract(Duration(days: 1));
      _loadScheduleData(previousDay);
  }

  void _goToNextDay() {
      final nextDay = _currentDate.add(Duration(days: 1));
      _loadScheduleData(nextDay);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Расписание'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с датой и стрелками
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 4.0, top: 16.0, bottom: 8.0), // Уменьшен отступ справа для кнопок
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Используем Flexible, чтобы текст мог переноситься, если очень длинный
                Flexible(
                  child: Text(
                     // Отображаем _scheduleDateDisplay (либо дату, либо "Загрузка...")
                    _scheduleDateDisplay,
                    style: TextStyle(
                      fontSize: 22.0, // Чуть меньше, чтобы лучше помещалось
                      fontWeight: FontWeight.bold,
                    ),
                     overflow: TextOverflow.ellipsis, // Многоточие, если не влезает
                  ),
                ),
                // Кнопки навигации по дням
                Row(
                  children: [
                    // Делаем кнопки менее заметными, если идет загрузка
                    IconButton(
                      onPressed: _isLoading ? null : _goToPreviousDay, // Выключаем кнопку при загрузке
                      icon: Icon(Icons.chevron_left, color: _isLoading ? Colors.grey : Colors.black54),
                      tooltip: 'Предыдущий день', // Подсказка при наведении
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _goToNextDay, // Выключаем кнопку при загрузке
                      icon: Icon(Icons.chevron_right, color: _isLoading ? Colors.grey : Colors.black54),
                      tooltip: 'Следующий день', // Подсказка при наведении
                    ),
                  ],
                )
              ],
            ),
          ),

          // Тело экрана: загрузка, ошибка или список
          Expanded(
            child: _buildBody(), // Используем тот же метод, что и раньше
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  // Метод _buildBody() остается таким же, как в предыдущем примере
  Widget _buildBody() {
    if (_isLoading) {
      // Можно оставить CircularProgressIndicator или добавить Shimmer эффект
      return Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      // Отображение ошибки
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Добавляем кнопку для повторной попытки
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => _loadScheduleData(_currentDate), // Повторить загрузку для текущей даты
                  child: Text('Повторить попытку')
              )
            ],
          ),
        ),
      );
    } else if (_scheduleItems.isEmpty) {
      // Сообщение, если пар нет
       return Center(
        child: Text(
          'На этот день пар нет',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    } else {
      // Список карточек
      return ListView.builder(
        itemCount: _scheduleItems.length,
        itemBuilder: (context, index) {
          final item = _scheduleItems[index];
          return ScheduleCard(entry: item);
        },
      );
    }
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