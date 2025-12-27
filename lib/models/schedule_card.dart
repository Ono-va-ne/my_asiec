import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'schedule_entry.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import '../models/homework.dart'; // Импорт модели Homework
import 'package:collection/collection.dart';

// import '../models/daily_schedule.dart';
// import '../pages/schedule_screen.dart';
extension Material3Palette on Color {
  Color tone(int tone) {
    assert(tone >= 0 && tone <= 100);
    final color = Hct.fromInt(value);
    final tonalPalette = TonalPalette.of(color.hue, color.chroma);
    return Color(tonalPalette.get(tone));
  }
}
// Не забудь добавить класс ScheduleEntry из шага 1 сюда или импортировать его

class ScheduleCard extends StatefulWidget {
  final ScheduleEntry entry; // Данные для этой карточки
  final List<ScheduleEntry> allEntriesForDay;
  final List<Homework> homeworks;
  const ScheduleCard({
    super.key,
    required this.entry,
    required this.allEntriesForDay,
    required this.homeworks,
  });

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Обновляем прогресс каждые 15 секунд чтобы индикатор плавно шёл
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- НОВЫЙ МЕТОД: Определение статуса пары ---
  // Возвращает enum для статуса: current, next, normal
  ScheduleEntryStatus _getEntryStatus(
    DateTime currentTime,
    List<ScheduleEntry> allEntriesForDay,
  ) {
    final entry = widget.entry;
    print(
      "--- _getEntryStatus для занятия: ${entry.discipline} ${entry.startTime}-${entry.endTime} ---",
    ); // Отладочный вывод в начале

    if (!isSameDay(entry.date, currentTime)) {
      // <--- НОВАЯ ПРОВЕРКА ДАТЫ!
      print(
        "  Дата занятия не сегодня, статус: normal",
      ); // Отладка: проверка даты
      return ScheduleEntryStatus
          .normal; // Если дата занятия НЕ сегодня, то это обычная пара
    }

    // 1. Парсим время начала и конца занятия из entry.startTime и entry.endTime
    final startTime = _parseTime(entry.startTime);
    final endTime = _parseTime(entry.endTime);

    if (startTime == null || endTime == null) {
      print(
        "  Ошибка парсинга времени, статус: normal",
      ); // Отладка: ошибка парсинга
      return ScheduleEntryStatus
          .normal; // Не удалось распарсить время - считаем обычной
    }

    // 2. Получаем текущее время без даты (только часы и минуты)
    final nowTime = TimeOfDay.fromDateTime(currentTime);

    // 3. Преобразуем время занятия в TimeOfDay для сравнения
    final entryStartTimeOfDay = TimeOfDay(
      hour: startTime.hour,
      minute: startTime.minute,
    );
    final entryEndTimeOfDay = TimeOfDay(
      hour: endTime.hour,
      minute: endTime.minute,
    );

    print(
      "  Текущее время: $nowTime, Время начала занятия: $entryStartTimeOfDay, Время конца занятия: $entryEndTimeOfDay",
    ); // Отладка: значения времени

    if (isCurrentTimeInEntry(nowTime, entryStartTimeOfDay, entryEndTimeOfDay)) {
      print(
        "  Текущее время попадает в интервал занятия, статус: current",
      ); // Отладка: текущая пара
      return ScheduleEntryStatus.current;
    } else if (isTimeBeforeEntry(
      nowTime,
      entryStartTimeOfDay,
      entryEndTimeOfDay,
    )) {
      print(
        "  Текущее время позже начала занятия, статус: next",
      ); // Отладка: ближайшая пара
      return ScheduleEntryStatus.next;
    } else {
      print("  Текущее время не попадает в интервал занятия, статус: normal");
    }

    // --- НОВАЯ ЛОГИКА для "ближайшей пары" ---
    // 3. Ищем ближайшую следующую пару ТОЛЬКО если текущая пара НЕ найдена
    ScheduleEntry? nextEntry;
    List<ScheduleEntry> futureEntries = [];
    // Проверяем, что есть список всех пар на день
    for (final otherEntry in allEntriesForDay) {
      if (otherEntry == entry) continue; // Пропускаем текущую пару

      final otherEntryStartTime = _parseTime(otherEntry.startTime);
      if (otherEntryStartTime != null) {
        final otherEntryStartTimeOfDay = TimeOfDay(
          hour: otherEntryStartTime.hour,
          minute: otherEntryStartTime.minute,
        );

        if (isTimeBeforeEntry(
          nowTime,
          otherEntryStartTimeOfDay,
          entryEndTimeOfDay,
        )) {
          nextEntry = otherEntry;
          break;
        }
        if (isTimeAfterNow(otherEntryStartTimeOfDay, nowTime)) {
          nextEntry = otherEntry;
          break;
        }
      }

      futureEntries.sort((a, b) {
        final startTimeA = _parseTime(a.startTime);
        final startTimeB = _parseTime(b.startTime);
        if (startTimeA == null || startTimeB == null)
          return 0; // Если время не распарсилось, не меняем порядок
        return startTimeA.hour.compareTo(startTimeB.hour) != 0
            ? startTimeA.hour.compareTo(startTimeB.hour)
            : startTimeA.minute.compareTo(startTimeB.minute);
      });

      if (futureEntries.isNotEmpty) {
        nextEntry = futureEntries.first; // Начинаем с первой пары из списка
        for (final otherNextEntry in futureEntries.skip(1)) {
          // Перебираем остальные, начиная со второй
          final otherNextEntryStartTime = _parseTime(otherNextEntry.startTime);
          final currentNextEntryStartTime = _parseTime(
            nextEntry!.startTime,
          ); // nextEntry точно не null, т.к. futureEntries не пустой

          if (otherNextEntryStartTime != null &&
              currentNextEntryStartTime != null) {
            // Строка 103 - Проверка на null
            // --- Упрощенное условное выражение (как и в прошлый раз) ---
            int otherEntryHour = otherNextEntryStartTime.hour;
            int currentNextEntryHour = currentNextEntryStartTime.hour;
            int otherEntryMinute = otherNextEntryStartTime.minute;
            int currentNextEntryMinute = currentNextEntryStartTime.minute;

            bool isHourEarlier = otherEntryHour < currentNextEntryHour;
            bool isHourEqual = otherEntryHour == currentNextEntryHour;
            bool isMinuteEarlier = otherEntryMinute < currentNextEntryMinute;

            if (isHourEarlier || (isHourEqual && isMinuteEarlier)) {
              // Строка 105 - УПРОЩЕННОЕ УСЛОВИЕ!
              // Если время начала ТЕКУЩЕЙ пары из futureEntries РАНЬШЕ, чем время начала уже найденной "ближайшей" (nextEntry),
              // то ТЕКУЩАЯ пара становится новой "ближайшей" (nextEntry = otherNextEntry)
              nextEntry = otherNextEntry;
            }
          }
        }
      }
      if (nextEntry == entry) {
        return ScheduleEntryStatus.next;
      }
    }
    // Пока просто возвращаем normal для всех остальных
    return ScheduleEntryStatus.normal;
  }

  bool isSameDay(DateTime entryDate, DateTime nowTime) {
    print("--- isSameDay: сравниваем даты ---");
    print("  Дата занятия: $entryDate, Дата сейчас: $nowTime");
    bool result =
        entryDate.year == nowTime.year &&
        entryDate.month == nowTime.month &&
        entryDate.day == nowTime.day;
    print("  Результат: $result");
    return result;
  }

  // --- НОВЫЙ МЕТОД: Проверка, является ли время timeOfDay позже, чем nowTime ---
  bool isTimeAfterNow(TimeOfDay timeOfDay, TimeOfDay nowTime) {
    if (timeOfDay.hour > nowTime.hour) {
      return true;
    } else if (timeOfDay.hour == nowTime.hour &&
        timeOfDay.minute > nowTime.minute) {
      return true;
    }
    return false;
  }

  // --- Обновленный метод: Проверка, попадает ли текущее время в интервал пары ---
  bool isCurrentTimeInEntry(
    TimeOfDay nowTime,
    TimeOfDay startTimeOfDay,
    TimeOfDay endTimeOfDay,
  ) {
    return isSameTime(nowTime, startTimeOfDay) ||
        (nowTime.hour > startTimeOfDay.hour &&
            nowTime.hour < endTimeOfDay.hour) ||
        (nowTime.hour == startTimeOfDay.hour &&
            nowTime.minute >= startTimeOfDay.minute &&
            nowTime.hour < endTimeOfDay.hour) ||
        (nowTime.hour == endTimeOfDay.hour &&
            nowTime.minute <= endTimeOfDay.minute &&
            nowTime.hour > startTimeOfDay.hour) ||
        (nowTime.hour == startTimeOfDay.hour &&
            nowTime.minute >= startTimeOfDay.minute &&
            nowTime.hour == endTimeOfDay.hour &&
            nowTime.minute <= endTimeOfDay.minute);
  }

  bool isTimeBeforeEntry(
    TimeOfDay nowTime,
    TimeOfDay startTimeOfDay,
    TimeOfDay endTimeOfDay,
  ) {
    print("--- isTimeBeforeEntry: Сравнение времени ---"); // Начало метода

    print(
      "  Текущее время (nowTime): $nowTime, Время начала занятия (startTimeOfDay): $startTimeOfDay",
    ); // Значения времени

    if (nowTime.hour < startTimeOfDay.hour) {
      print(
        "  Условие: $nowTime.hour < $startTimeOfDay.hour  => TRUE (Часы текущего времени МЕНЬШЕ часов начала занятия)",
      ); // Условие 1 и результат TRUE
      return true;
    } else {
      print(
        "  Условие: $nowTime.hour < $startTimeOfDay.hour  => FALSE (Часы текущего времени НЕ МЕНЬШЕ часов начала занятия)",
      ); // Условие 1 и результат FALSE
    }

    if (nowTime.hour == startTimeOfDay.hour &&
        nowTime.minute < startTimeOfDay.minute) {
      print(
        "  Условие: nowTime.hour == startTimeOfDay.hour && nowTime.minute < startTimeOfDay.minute  => TRUE (Часы равны, минуты текущего времени МЕНЬШЕ минут начала занятия)",
      ); // Условие 2 и результат TRUE
      return true;
    } else {
      print(
        "  Условие: nowTime.hour == startTimeOfDay.hour && nowTime.minute < startTimeOfDay.minute  => FALSE (Условие 2 не выполнено)",
      ); // Условие 2 и результат FALSE
    }

    print(
      "  Ни одно из условий не выполнено, возвращаем FALSE",
    ); // Если дошли до сюда, значит, ни одно условие не выполнилось
    return false;
  }

  // Вспомогательная функция для парсинга времени в TimeOfDay
  TimeOfDay? _parseTime(String timeString) {
    try {
      final format = DateFormat("HH:mm"); // Формат времени в твоих строках
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      print("Ошибка парсинга времени: $timeString");
      return null;
    }
  }

  // Вспомогательная функция для сравнения времени (без учета даты)
  bool isSameTime(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour == time2.hour && time1.minute == time2.minute;
  }

  String? extractSubgroup(String discipline) {
    final regex = RegExp(r'/\s*(\d+)\s*подгруппа', caseSensitive: false);
    final match = regex.firstMatch(discipline);
    if (match != null && match.groupCount >= 1) {
      return match.group(1); // Вернет "2" для "подгруппа 2"
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final scheduleSubgroup = extractSubgroup(widget.entry.discipline);
    final Homework? foundHomework = widget.homeworks.firstWhereOrNull((hw) {
      final entryDisciplineMain =
          widget.entry.discipline.split('/')[0].trim().toLowerCase();
      final hwDisciplineMain = hw.discipline.split('/')[0].trim().toLowerCase();
      final hwSubgroup = hw.subgroup?.trim();
      final subgroupMatch =
          (scheduleSubgroup == null &&
              (hwSubgroup == null || hwSubgroup.isEmpty)) ||
          (scheduleSubgroup != null &&
              hwSubgroup != null &&
              scheduleSubgroup == hwSubgroup);
      final disciplineMatch =
          entryDisciplineMain.contains(hwDisciplineMain) ||
          hwDisciplineMain.contains(entryDisciplineMain);
      return disciplineMatch &&
          hw.group == widget.entry.group &&
          hw.dueDate.year == widget.entry.date.year &&
          hw.dueDate.month == widget.entry.date.month &&
          hw.dueDate.day == widget.entry.date.day &&
          subgroupMatch;
    });

    final hasHomework = foundHomework != null;
    //  final dailySchedule =
    //     _ScheduleScreenState.of(context)?.dailyScheduleForCard(entry.date); // <---  Нужно реализовать получение списка!
    final List<ScheduleEntry> allEntriesForDay = widget.allEntriesForDay;
    final entryStatus = _getEntryStatus(now, allEntriesForDay);

    // Вычисляем прогресс для текущей пары (0..1)
    double progress = 0.0;
    if (entryStatus == ScheduleEntryStatus.current) {
      final startT = _parseTime(widget.entry.startTime);
      final endT = _parseTime(widget.entry.endTime);
      if (startT != null && endT != null) {
        final startDt = DateTime(
          widget.entry.date.year,
          widget.entry.date.month,
          widget.entry.date.day,
          startT.hour,
          startT.minute,
        );
        final endDt = DateTime(
          widget.entry.date.year,
          widget.entry.date.month,
          widget.entry.date.day,
          endT.hour,
          endT.minute,
        );
        final total = endDt.difference(startDt).inSeconds;
        final elapsed = now.difference(startDt).inSeconds;
        if (total > 0) {
          progress = (elapsed / total).clamp(0.0, 1.0);
        }
      }
    }

    return InkWell(
      onTap:
          hasHomework
              ? () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Домашнее задание'),
                        content: Text(foundHomework!.task),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Закрыть'),
                          ),
                        ],
                      ),
                );
              }
              : null,
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side:
                  entryStatus == ScheduleEntryStatus.next
                      ? BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      )
                      : BorderSide.none,
            ),
            // color: entryStatus == ScheduleEntryStatus.current
            //     ? Theme.of(context).colorScheme.primaryContainer
            //     : null,
            elevation: 2.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                children: [
                  if (entryStatus == ScheduleEntryStatus.current)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.entry.discipline,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                widget.entry.teacher,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.entry.startTime} - ${widget.entry.endTime}',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              widget.entry.group,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              '${widget.entry.building}\n${widget.entry.room}',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(height: 8.0),
                            if (hasHomework)
                              Icon(
                                Icons.assignment,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum ScheduleEntryStatus {
  normal, // Обычная пара
  current, // Текущая пара (идёт сейчас)
  next, // Ближайшая следующая пара (пока не реализовано)
}
