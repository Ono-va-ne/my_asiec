import 'schedule_entry.dart'; // Пример пути
// import 'parser_schedule.dart';
// import 'package:my_asiec_lite/pages/schedule_screen.dart';
// import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:intl/intl.dart';

// --- Новая структура для хранения расписания одного дня ---
class DailySchedule {
  final DateTime date;
  final List<ScheduleEntry> entries;

  DailySchedule({required this.date, required this.entries});
}

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

Map<String, String>? _parseTime(String timeString) {
  // Ищем совпадение с форматом "ЧИСЛО (ЧАС:МИН - ЧАС:МИН)"
  final RegExp timeRegex = RegExp(r'\((\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\)');
  final match = timeRegex.firstMatch(timeString);

  if (match != null && match.groupCount == 2) {
    // Если найдено совпадение, извлекаем группы
    // group(1) - время начала, group(2) - время конца
    return {
      'start': match.group(1)!,
      'end': match.group(2)!,
    };
  } else {
    // Если формат не совпал, возвращаем null
    print("Не удалось распознать время: $timeString");
    return null;
  }
}

// --- Обновленная функция парсинга для нескольких дней ---
List<DailySchedule> parseScheduleHtmlMultiDay(String htmlString) {
  final document = parse(htmlString);
  final table = document.querySelector('table.table-3');
  if (table == null) {
    print("Ошибка парсинга: Таблица 'table-3' не найдена.");
    return [];
  }
  final tbody = table.querySelector('tbody');
  if (tbody == null) {
    print("Ошибка парсинга: Тело таблицы 'tbody' не найдено.");
    return [];
  }

  final rows = tbody.querySelectorAll('tr');
  final List<DailySchedule> resultList = [];
  List<ScheduleEntry>? currentDayEntries; // Список пар для текущего обрабатываемого дня
  DateTime? currentDayDate; // Дата текущего обрабатываемого дня

  for (final row in rows) {
    final cells = row.querySelectorAll('td');

    // 1. Проверяем строку с датой
    if (cells.length == 1 && cells.first.attributes['colspan'] == '6') {
      final htmlDateString = cells.first.text.trim();
      final parsedDate = _parseDateFromHtml(htmlDateString); // Используем существующий хелпер

      if (parsedDate != null) {
        // Если мы уже обрабатывали какой-то день до этого,
        // сохраняем его результаты перед тем, как начать новый.
        if (currentDayDate != null && currentDayEntries != null) {
           // Добавляем предыдущий день (даже если пар не было)
           resultList.add(DailySchedule(
              date: currentDayDate,
              // Важно создать копию списка, чтобы будущие добавления не влияли на этот день
              entries: List.from(currentDayEntries)
           ));
           print("Сохранен день: $currentDayDate с ${currentDayEntries.length} парами.");
        }
         // Начинаем новый день
         currentDayDate = parsedDate;
         currentDayEntries = []; // Создаем новый пустой список для этого дня
         print("Найдена дата в HTML: $currentDayDate");
      } else {
         print("Не удалось распознать дату в строке: $htmlDateString");
         // Если не смогли распознать дату, то последующие пары не будут добавлены
         // Можно решить игнорировать пары до следующей валидной даты
         currentDayDate = null;
         currentDayEntries = null;
      }
      continue; // Переходим к следующей строке
    }

    // 2. Проверяем строку с парой (и есть ли текущий день для добавления)
    if (currentDayDate != null && currentDayEntries != null && cells.length >= 6) {
      try {
        final timeString = cells[0].text.trim();
        final discipline = cells[2].text.trim();
        final teacher = cells[3].text.trim();
        final building = cells[4].text.trim();
        final room = cells[5].text.trim();
        final timeParts = _parseTime(timeString); // Используем старый хелпер _parseTime

        final entry = ScheduleEntry(
          discipline: discipline,
          teacher: teacher,
          startTime: timeParts?['start'] ?? '',
          endTime: timeParts?['end'] ?? '',
          building: building,
          room: room,
        );
        currentDayEntries.add(entry); // Добавляем пару в список ТЕКУЩЕГО дня
      } catch (e) {
        print("Ошибка парсинга строки с парой: $e. Строка: ${row.innerHtml}");
      }
    } else if (cells.length >= 6 && currentDayDate == null) {
         print("Найдена строка с парой, но не определена текущая дата. Пропуск: ${row.innerHtml}");
    }
  }

  // Добавляем последний обрабатываемый день в результат, если он не пустой
  if (currentDayDate != null && currentDayEntries != null && currentDayEntries.isNotEmpty) {
    resultList.add(DailySchedule(date: currentDayDate, entries: currentDayEntries));
  } else if (currentDayDate != null && (currentDayEntries == null || currentDayEntries.isEmpty)) {
      // Если нашли дату, но для нее не было пар, все равно добавим ее с пустым списком
      resultList.add(DailySchedule(date: currentDayDate, entries: []));
  }

  // Сортируем результат по дате на всякий случай
  resultList.sort((a, b) => a.date.compareTo(b.date));

  print("Парсинг завершен. Найдено дней: ${resultList.length}");
  return resultList;
}

// Не забудь также оставить функции _parseDateFromHtml и _parseTime,
// которые используются внутри parseScheduleHtmlMultiDay!
// Они должны быть доступны в том же скоупе (например, внутри класса _ScheduleScreenState
// или как top-level функции в том же файле).