// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homework.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomeworkAdapter extends TypeAdapter<Homework> {
  @override
  final int typeId = 0;

  @override
  Homework read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Homework(
      id: fields[0] as String?,
      discipline: fields[1] as String,
      group: fields[2] as String,
      group_id: fields[3] as String,
      subgroup: fields[4] as String?,
      task: fields[5] as String,
      due_date: fields[6] as DateTime,
      photo_urls: (fields[7] as List?)?.cast<String>(),
      date_added: fields[8] as DateTime,
      isLocal: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Homework obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.discipline)
      ..writeByte(2)
      ..write(obj.group)
      ..writeByte(3)
      ..write(obj.group_id)
      ..writeByte(4)
      ..write(obj.subgroup)
      ..writeByte(5)
      ..write(obj.task)
      ..writeByte(6)
      ..write(obj.due_date)
      ..writeByte(7)
      ..write(obj.photo_urls)
      ..writeByte(8)
      ..write(obj.date_added)
      ..writeByte(9)
      ..write(obj.isLocal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
