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
      id: fields[0] as String,
      uld: fields[1] as String,
      type: fields[2] as SizeEnum,
      size: fields[3] as SizeEnum,
      weightKg: fields[4] as int,
      hasDangerousGoods: fields[5] as bool,
      colorIndex: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StorageContainer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.uld)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.weightKg)
      ..writeByte(5)
      ..write(obj.hasDangerousGoods)
      ..writeByte(6)
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
