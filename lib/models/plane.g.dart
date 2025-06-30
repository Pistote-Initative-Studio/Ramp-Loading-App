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
      inboundSequenceLabel: fields[3] as String,
      inboundSequenceOrder: (fields[4] as List).cast<int>(),
      inboundSlots: (fields[5] as List).cast<StorageContainer?>(),
      outboundSequenceLabel: fields[6] as String,
      outboundSequenceOrder: (fields[7] as List).cast<int>(),
      outboundSlots: (fields[8] as List).cast<StorageContainer?>(),
      lowerInboundSlots: (fields[9] as List).cast<StorageContainer?>(),
      lowerOutboundSlots: (fields[10] as List).cast<StorageContainer?>(),
    );
  }

  @override
  void write(BinaryWriter writer, Plane obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.aircraftTypeCode)
      ..writeByte(3)
      ..write(obj.inboundSequenceLabel)
      ..writeByte(4)
      ..write(obj.inboundSequenceOrder)
      ..writeByte(5)
      ..write(obj.inboundSlots)
      ..writeByte(6)
      ..write(obj.outboundSequenceLabel)
      ..writeByte(7)
      ..write(obj.outboundSequenceOrder)
      ..writeByte(8)
      ..write(obj.outboundSlots)
      ..writeByte(9)
      ..write(obj.lowerInboundSlots)
      ..writeByte(10)
      ..write(obj.lowerOutboundSlots);
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
