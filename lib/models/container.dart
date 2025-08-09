import 'package:hive/hive.dart';
import 'aircraft.dart';

part 'container.g.dart';

/// Serializable ULD container stored in Hive.
@HiveType(typeId: 0)
class StorageContainer extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String uld;

  @HiveField(2)
  final SizeEnum type;

  @HiveField(3)
  final SizeEnum size;

  @HiveField(4)
  int weightKg;

  @HiveField(5)
  bool hasDangerousGoods;

  @HiveField(6)
  final int? colorIndex;

  StorageContainer({
    required this.id,
    required this.uld,
    required this.type,
    required this.size,
    this.weightKg = 0,
    this.hasDangerousGoods = false,
    this.colorIndex,
  });
}
