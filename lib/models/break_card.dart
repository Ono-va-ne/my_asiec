import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class BreakCard extends StatefulWidget {
  final Duration duration;
  final String startTime;
  final String endTime;
  final DateTime date; // Добавляем дату, чтобы точно определять прогресс

  const BreakCard({
    super.key,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.date,
  });

  @override
  State<BreakCard> createState() => _BreakCardState();
}

class _BreakCardState extends State<BreakCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Обновляем виджет каждые 15 секунд для плавного движения прогресс-бара
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Вспомогательная функция для парсинга времени
  TimeOfDay? _parseTime(String timeString) {
    try {
      final format = DateFormat("HH:mm");
      final dateTime = format.parse(timeString);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakMinutes = widget.duration.inMinutes;
    final now = DateTime.now();

    bool isCurrentBreak = false;
    double progress = 0.0;

    final breakStart = _parseTime(widget.startTime);
    final breakEnd = _parseTime(widget.endTime);

    if (breakStart != null && breakEnd != null) {
      // Создаем полные DateTime для начала и конца перемены, используя дату из виджета
      final breakStartDateTime = DateTime(widget.date.year, widget.date.month,
          widget.date.day, breakStart.hour, breakStart.minute);
      final breakEndDateTime = DateTime(widget.date.year, widget.date.month,
          widget.date.day, breakEnd.hour, breakEnd.minute);

      // Проверяем, что текущее время находится внутри интервала перемены
      if (now.isAfter(breakStartDateTime) && now.isBefore(breakEndDateTime)) {
        isCurrentBreak = true;
        // Считаем прогресс в секундах для плавности
        final totalDuration =
            breakEndDateTime.difference(breakStartDateTime).inSeconds;
        final elapsedDuration = now.difference(breakStartDateTime).inSeconds;

        if (totalDuration > 0) {
          progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      clipBehavior: Clip.antiAlias, // Важно для правильного отображения фона
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Слой с прогрессом (отображается только если перемена текущая)
          if (isCurrentBreak)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: theme.colorScheme.primaryContainer),
              ),
            ),
          // Основной контент карточки
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Перемена: $breakMinutes мин.',
                  style: TextStyle(
                    fontSize: 13.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${widget.startTime} - ${widget.endTime}',
                  style: TextStyle(
                      fontSize: 13.0, color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}