class ScheduleEntry {
  final String discipline; // Название дисциплины
  final String teacher;    // Имя преподавателя
  final String startTime;  // Время начала
  final String endTime;    // Время окончания
  final String building;   // Корпус
  final String room;       // Аудитория

  ScheduleEntry({
    required this.discipline,
    required this.teacher,
    required this.startTime,
    required this.endTime,
    required this.building,
    required this.room,
  });
}