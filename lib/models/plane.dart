import 'package:hive/hive.dart';
import 'container.dart';

part 'plane.g.dart';

@HiveType(typeId: 4)
class Plane extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String aircraftTypeCode;

  @HiveField(3)
  String sequenceLabel;

  @HiveField(4)
  List<int> sequenceOrder;

  @HiveField(5)
  List<StorageContainer?> slots;

  Plane({
    required this.id,
    required this.name,
    required this.aircraftTypeCode,
    required this.sequenceLabel,
    required this.sequenceOrder,
    required this.slots,
  });
}
