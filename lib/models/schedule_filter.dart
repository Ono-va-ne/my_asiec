import 'dart:convert';

/// Перечисление для типов фильтров.
/// lesson - по названию дисциплины
/// teacher - по имени преподавателя
/// room - по названию аудитории
enum ScheduleFilterType { lesson, teacher, room }


class ScheduleFilter {
  final String id;
  final String type;
  final String keyword;
  final bool isBuiltIn;
  bool isEnabled;

  ScheduleFilter({
    required this.id,
    required this.keyword,
    required this.type, // 'lesson', 'teacher', 'room'
    this.isBuiltIn = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword,
      'type': type,
      'isBuiltIn': isBuiltIn,
      'isEnabled': isEnabled,
    };
  }

  factory ScheduleFilter.fromMap(Map<String, dynamic> map) {
    return ScheduleFilter(
      id: map['id'] ?? '',
      keyword: map['keyword'] ?? '',
      type: map['type'] ?? '',
      isBuiltIn: map['isBuiltIn'] ?? false,
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleFilter.fromJson(String source) =>
      ScheduleFilter.fromMap(json.decode(source));
}

class ScheduleFilterPreset {
  final String name;
  final List<String> keywords;

  ScheduleFilterPreset({
    required this.name,
    required this.keywords,
  });
}