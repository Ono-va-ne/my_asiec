class ScheduleEntry {
  final String discipline; // Название дисциплины
  final String teacher; // Имя преподавателя
  final String group; // Группа
  final String startTime; // Время начала
  final String endTime; // Время окончания
  final String room; // Аудитория/корпус
  final DateTime date;

  ScheduleEntry({
    required this.discipline,
    required this.teacher,
    required this.group,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'discipline': discipline,
        'teacher': teacher,
        'group': group,
        'startTime': startTime,
        'endTime': endTime,
        'room': room,
        'date': date.toIso8601String(),
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
        discipline: json['discipline'] as String? ?? '',
        teacher: json['teacher'] as String? ?? '',
        group: json['group'] as String? ?? '',
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        room: json['room'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
  // DateTime get date => DateTime.now();
}
