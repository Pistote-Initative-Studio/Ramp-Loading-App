// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plane.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaneAdapter extends TypeAdapter<Plane> {
  @override
  final int typeId = 4;

  @override
  Plane read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Plane(
      id: fields[0] as String,
      name: fields[1] as String,
      aircraftTypeCode: fields[2] as String,
      sequenceLabel: fields[3] as String,
      sequenceOrder: (fields[4] as List).cast<int>(),
      slots: (fields[5] as List).cast<StorageContainer?>(),
    );
  }

  @override
  void write(BinaryWriter writer, Plane obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.aircraftTypeCode)
      ..writeByte(3)
      ..write(obj.sequenceLabel)
      ..writeByte(4)
      ..write(obj.sequenceOrder)
      ..writeByte(5)
      ..write(obj.slots);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
