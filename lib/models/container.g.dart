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
      label: fields[1] as String,
      destination: fields[2] as String?,
      hasDangerousGoods: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StorageContainer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.destination)
      ..writeByte(3)
      ..write(obj.hasDangerousGoods);
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
