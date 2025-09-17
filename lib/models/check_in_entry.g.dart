// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckInEntryAdapter extends TypeAdapter<CheckInEntry> {
  @override
  final int typeId = 2;

  @override
  CheckInEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckInEntry(
      userId: fields[0] as String,
      time: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CheckInEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.time);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
