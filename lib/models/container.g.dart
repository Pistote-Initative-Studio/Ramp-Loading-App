// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'container.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StorageContainerAdapter extends TypeAdapter<StorageContainer> {
  @override
  final int typeId = 0;

  @override
  StorageContainer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StorageContainer(
      uld: fields[0] as String,
      type: fields[1] as String,
      size: fields[2] as SizeEnum,
      weightKg: fields[3] as int,
      hasDangerousGoods: fields[4] as bool,
      colorIndex: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StorageContainer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uld)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.weightKg)
      ..writeByte(4)
      ..write(obj.hasDangerousGoods)
      ..writeByte(5)
      ..write(obj.colorIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageContainerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
