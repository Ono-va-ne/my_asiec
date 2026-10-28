import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../models/daily_schedule.dart';

/// Mirrors the cached schedule into Android's widget SharedPreferences.
class ScheduleWidgetService {
  static Future<void> updateToday({
    required String selectionName,
    required String selectionType,
    required List<DailySchedule> schedules,
  }) async {
    final today = DateTime.now();
    final todaySchedule = schedules.where((schedule) =>
        schedule.date.year == today.year &&
        schedule.date.month == today.month &&
        schedule.date.day == today.day);
    final entries = todaySchedule.isEmpty ? const [] : todaySchedule.first.entries;

    await HomeWidget.saveWidgetData<String>('schedule_widget_date', DateFormat('yyyy-MM-dd').format(today));
    await HomeWidget.saveWidgetData<String>('schedule_widget_title', selectionName);
    await HomeWidget.saveWidgetData<String>('schedule_widget_type', selectionType);
    await HomeWidget.saveWidgetData<String>(
      'schedule_widget_entries',
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.onovane.my_asiec.ScheduleWidgetProvider',
      androidName: 'ScheduleWidgetProvider',
      name: 'ScheduleWidgetProvider',
    );
  }
}
