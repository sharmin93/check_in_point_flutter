// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckInPointAdapter extends TypeAdapter<CheckInPoint> {
  @override
  final int typeId = 1;

  @override
  CheckInPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckInPoint(
      radiusMeters: fields[2] as double,
      createdBy: fields[3] as String,
      createdAt: fields[4] as DateTime?, location:  LatLng(
      fields[0] as double,
      fields[1] as double,
    ),
    );
  }

  @override
  void write(BinaryWriter writer, CheckInPoint obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.radiusMeters)
      ..writeByte(3)
      ..write(obj.createdBy)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
