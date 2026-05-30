import 'dart:convert';

class ScheduleFilter {
  final String id;
  final String keyword;
  final bool isBuiltIn;
  bool isEnabled;

  ScheduleFilter({
    required this.id,
    required this.keyword,
    this.isBuiltIn = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyword': keyword,
      'isBuiltIn': isBuiltIn,
      'isEnabled': isEnabled,
    };
  }

  factory ScheduleFilter.fromMap(Map<String, dynamic> map) {
    return ScheduleFilter(
      id: map['id'] ?? '',
      keyword: map['keyword'] ?? '',
      isBuiltIn: map['isBuiltIn'] ?? false,
      isEnabled: map['isEnabled'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleFilter.fromJson(String source) =>
      ScheduleFilter.fromMap(json.decode(source));
}
