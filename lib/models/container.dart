import 'package:hive/hive.dart';

part 'container.g.dart';

@HiveType(typeId: 0)
class StorageContainer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final String? destination;

  @HiveField(3)
  final bool hasDangerousGoods;

  StorageContainer({
    required this.id,
    required this.label,
    this.destination,
    this.hasDangerousGoods = false,
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
