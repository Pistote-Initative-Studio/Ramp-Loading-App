import 'package:hive/hive.dart';

part 'container.g.dart';

@HiveType(typeId: 0)
class StorageContainer extends HiveObject {
  @HiveField(0)
  final String uld;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final SizeEnum size;

  @HiveField(3)
  int weightKg;

  @HiveField(4)
  bool hasDangerousGoods;

  @HiveField(5)
  final int? colorIndex;

  StorageContainer({
    required this.uld,
    required this.type,
    required this.size,
    this.weightKg = 0,
    this.hasDangerousGoods = false,
    this.colorIndex,
  });
}

class StorageContainerAdapter extends TypeAdapter<StorageContainer> {
  @override
  final int typeId = 0;

  @override
  StorageContainer read(BinaryReader reader) {
    return StorageContainer(
      id: reader.readString(),
      label: reader.readString(),
      destination: reader.read(),
      hasDangerousGoods: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, StorageContainer obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.label);
    writer.write(obj.destination);
    writer.writeBool(obj.hasDangerousGoods);
  }
}
