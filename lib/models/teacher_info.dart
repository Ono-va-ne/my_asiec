class TeacherInfo {
  final String id; // ID группы, как используется в API (e.g., '3afb102a-...')
  final String name; // Отображаемое имя (e.g., '9ОИБ231')

  const TeacherInfo({required this.id, required this.name});

  // Переопределяем == и hashCode, чтобы DropdownButton корректно
  // сравнивал объекты TeacherInfo при выборе.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    // Для отладки
    return 'TeacherInfo{id: $id, name: $name}';
  }

  /// Создаёт объект из JSON/Map, учитывает разные возможные имена полей
  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['teacher_id'] ?? '';
    final nameValue =
        json['name'] ??
        json['fio'] ??
        json['teacher_name'] ??
        '';
    return TeacherInfo(id: idValue.toString(), name: nameValue.toString());
}
}