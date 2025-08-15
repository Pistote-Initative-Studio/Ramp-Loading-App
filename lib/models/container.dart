import 'package:hive/hive.dart';

import 'aircraft.dart';

/// Type id used to register the [StorageContainerAdapter].
const int kStorageContainerTypeId = 12;

/// Serializable ULD container stored in Hive.
class StorageContainer extends HiveObject {
  final String id;

  /// Display label for the container. When constructed with [uld], this
  /// value mirrors that parameter so existing code can continue to use
  /// `container.uld`.
  final String label;

  final SizeEnum type;
  final SizeEnum size;
  int weightKg;
  bool dangerousGoods;
  final int? colorIndex;

  StorageContainer({
    required this.id,
    String? label,
    String? uld,
    required this.type,
    required this.size,
    this.weightKg = 0,
    this.dangerousGoods = false,
    this.colorIndex,
  }) : label = label ?? uld ?? '';

  /// Backwards‑compatibility getter for older code that referenced `uld`.
  String get uld => label;
}

/// Manual Hive adapter for [StorageContainer].
class StorageContainerAdapter extends TypeAdapter<StorageContainer> {
  @override
  final int typeId = kStorageContainerTypeId;

  @override
  StorageContainer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StorageContainer(
      id: fields[0] as String,
      label: fields[1] as String,
      type: fields[2] as SizeEnum,
      size: fields[3] as SizeEnum,
      weightKg: fields[4] as int,
      dangerousGoods: fields[5] as bool,
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
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.weightKg)
      ..writeByte(5)
      ..write(obj.dangerousGoods)
      ..writeByte(6)
      ..write(obj.colorIndex);
  }
}

