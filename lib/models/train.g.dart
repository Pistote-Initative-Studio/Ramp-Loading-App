// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'train.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DollyAdapter extends TypeAdapter<Dolly> {
  @override
  final int typeId = 2;

  @override
  Dolly read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dolly(
      fields[0] as int,
      load: fields[1] as StorageContainer?,
    );
  }

  @override
  void write(BinaryWriter writer, Dolly obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.idx)
      ..writeByte(1)
      ..write(obj.load);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DollyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrainAdapter extends TypeAdapter<Train> {
  @override
  final int typeId = 3;

  @override
  Train read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Train(
      id: fields[0] as String,
      label: fields[1] as String,
      dollyCount: fields[2] as int,
      inboundDollys: (fields[3] as List).cast<Dolly>(),
      outboundDollys: (fields[4] as List).cast<Dolly>(),
      colorIndex: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Train obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.dollyCount)
      ..writeByte(3)
      ..write(obj.inboundDollys)
      ..writeByte(4)
      ..write(obj.outboundDollys)
      ..writeByte(5)
      ..write(obj.colorIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
