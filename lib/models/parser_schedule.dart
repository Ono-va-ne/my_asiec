import 'package:html/parser.dart' show parse; // Импортируем функцию parse
// import 'package:html/dom.dart' as dom; // Импортируем типы данных из библиотеки html
// Не забудь импортировать твой класс ScheduleEntry
import 'schedule_entry.dart'; // Пример пути

// Структура для возврата результата парсинга
class ParsedSchedule {
  final String? date; // Дата расписания (может отсутствовать)
  final List<ScheduleEntry> entries; // Список пар

  ParsedSchedule({this.date, required this.entries});
}

// Функция парсинга
ParsedSchedule parseScheduleHtml(String htmlString) {
  // 1. Парсим HTML строку в документ
  final document = parse(htmlString);

  // 2. Находим таблицу по классу 'table-3'
  final table = document.querySelector('table.table-3');
  if (table == null) {
    print("Ошибка: Таблица с классом 'table-3' не найдена.");
    return ParsedSchedule(entries: []); // Возвращаем пустой результат
  }

  // 3. Находим тело таблицы 'tbody'
  final tbody = table.querySelector('tbody');
  if (tbody == null) {
    print("Ошибка: Тело таблицы 'tbody' не найдено.");
    return ParsedSchedule(entries: []);
  }

  // 4. Получаем все строки 'tr' из тела таблицы
  final rows = tbody.querySelectorAll('tr');

  String? scheduleDate; // Переменная для хранения даты
  final List<ScheduleEntry> scheduleEntries = []; // Список для хранения пар

  // 5. Проходим по каждой строке
  for (final row in rows) {
    // 6. Получаем все ячейки 'td' в строке
    final cells = row.querySelectorAll('td');

    // 7. Проверяем, это строка с датой? (Одна ячейка с colspan='6')
    if (cells.length == 1 && cells.first.attributes['colspan'] == '6') {
      scheduleDate = cells.first.text.trim(); // Извлекаем и сохраняем дату
      // Пример: "Вторник, 15.10.2024"
      // Ты можешь обработать эту строку дальше, если нужно только "15 Октября"
      // Например, можно использовать регулярные выражения или split
      continue; // Переходим к следующей строке
    }

    // 8. Проверяем, достаточно ли ячеек для данных о паре (минимум 6)
    if (cells.length >= 6) {
      try {
        // 9. Извлекаем данные из ячеек по их порядку
        // Важно: trim() удаляет лишние пробелы и переносы строк по краям
        final timeString = cells[0].text.trim(); // "1 (8:00 - 9:20)"
        final group = cells[1].text.trim();
        final discipline = cells[2].text.trim();
        final teacher = cells[3].text.trim();
        final building = cells[4].text.trim(); // 'Корпус 1' из ter_pc
        final room = cells[5].text.trim(); // '114' из aud_pc

        // 10. Парсим время начала и конца из timeString
        final timeParts = _parseTime(timeString); // Используем хелпер

        // 11. Создаем объект ScheduleEntry
        final entry = ScheduleEntry(
          discipline: discipline,
          teacher: teacher,
          startTime: timeParts?['start'] ?? '', // Безопасно извлекаем время
          endTime:
              timeParts?['end'] ??
              '', // или оставляем пустым, если не распарсилось
          group: group,
          building: building,
          room: room,
          date: DateTime.parse(scheduleDate ?? DateTime.now().toString()),
        );
        scheduleEntries.add(entry); // Добавляем в список
      } catch (e) {
        // Ловим возможные ошибки (например, если структура строки неожиданно изменится)
        print("Ошибка парсинга строки: $e. Строка: ${row.innerHtml}");
      }
    }
  }

  // 12. Возвращаем результат
  return ParsedSchedule(date: scheduleDate, entries: scheduleEntries);
}

// Вспомогательная функция для извлечения времени начала и конца
Map<String, String>? _parseTime(String timeString) {
  // Ищем совпадение с форматом "ЧИСЛО (ЧАС:МИН - ЧАС:МИН)"
  final RegExp timeRegex = RegExp(r'\((\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})\)');
  final match = timeRegex.firstMatch(timeString);

  if (match != null && match.groupCount == 2) {
    // Если найдено совпадение, извлекаем группы
    // group(1) - время начала, group(2) - время конца
    return {'start': match.group(1)!, 'end': match.group(2)!};
  } else {
    // Если формат не совпал, возвращаем null
    print("Не удалось распознать время: $timeString");
    return null;
  }
}
