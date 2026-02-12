import 'package:hive/hive.dart';

part 'homework.g.dart';

@HiveType(typeId: 0)
class Homework {
  @HiveField(0)
  String? id;
  @HiveField(1)
  final String discipline;
  @HiveField(2)
  final String group;
  @HiveField(3)
  final String group_id;
  @HiveField(4)
  final String? subgroup;
  @HiveField(5)
  final String task;
  @HiveField(6)
  final DateTime due_date;
  @HiveField(7)
  final List<String>? photo_urls;
  @HiveField(8)
  final DateTime date_added;
  @HiveField(9)
  final bool isLocal;

  Homework({
    this.id,
    required this.discipline,
    required this.group,
    required this.group_id,
    this.subgroup,
    required this.task,
    required this.due_date,
    this.photo_urls,
    required this.date_added,
    this.isLocal = false,
  });
  Map<String, dynamic> toJson() {
    return {
      'discipline': discipline,
      'group': group,
      'group_id': group_id,
      'subgroup': subgroup,
      'task': task,
      'due_date': due_date.toIso8601String(),
      'photo_urls': photo_urls,
      'date_added': date_added.toIso8601String(),
    };
  }

  factory Homework.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTimestamp(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Map) {
        final seconds = v['seconds'] ?? v['_seconds'];
        if (seconds != null) return DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);
      }
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return Homework(
      id: id,
      discipline: json['discipline'] as String,
      group: json['group'] as String,
      group_id: json['group_id'] as String,
      subgroup: json['subgroup'] as String?,
      task: json['task'] as String,
      due_date: parseTimestamp(json['due_date'] ?? json['due_date']),
      photo_urls:
          (json['photo_urls'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList(),
      date_added: parseTimestamp(json['date_added']),
      isLocal: false,
    );
  }
}
