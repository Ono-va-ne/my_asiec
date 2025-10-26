class GroupInfo {
  final String id;   // ID группы, как используется в API (e.g., '3afb102a-...')
  final String name; // Отображаемое имя (e.g., '9ОИБ231')

  const GroupInfo({required this.id, required this.name});

  /// Создаёт объект из JSON/Map, учитывает разные возможные имена полей
  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['group_id'] ?? json['gid'] ?? '';
    final nameValue = json['name'] ?? json['title'] ?? json['group_name'] ?? json['label'] ?? '';
    return GroupInfo(
      id: idValue.toString(),
      name: nameValue.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  // Переопределяем == и hashCode, чтобы DropdownButton корректно
  // сравнивал объекты GroupInfo при выборе.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() { // Для отладки
    return 'GroupInfo{id: $id, name: $name}';
  }
}