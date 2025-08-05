// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_deck_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BallDeckStateAdapter extends TypeAdapter<BallDeckState> {
  @override
  final int typeId = 6;

  @override
  BallDeckState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BallDeckState(
      slots: (fields[0] as List).cast<StorageContainer?>(),
      overflow: (fields[1] as List).cast<StorageContainer?>(),
    );
  }

  @override
  void write(BinaryWriter writer, BallDeckState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.slots)
      ..writeByte(1)
      ..write(obj.overflow);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BallDeckStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
