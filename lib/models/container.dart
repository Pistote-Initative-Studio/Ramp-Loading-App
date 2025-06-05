import 'package:hive/hive.dart';
import 'aircraft.dart';

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
