class RoomInfo {
  final String id;   // ID группы, как используется в API (e.g., '3afb102a-...')
  final String name; // Отображаемое имя (e.g., '9ОИБ231')

  const RoomInfo({required this.id, required this.name});

  // Переопределяем == и hashCode, чтобы DropdownButton корректно
  // сравнивал объекты RoomInfo при выборе.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() { // Для отладки
    return 'RoomInfo{id: $id, name: $name}';
  }
}