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

  // Inbound main deck configuration
  @HiveField(3)
  String InboundSequenceLabel;

  @HiveField(4)
  List<int> InboundSequenceOrder;

  @HiveField(5)
  List<StorageContainer?> inboundSlots;

  // Outbound main deck configuration
  @HiveField(6)
  String outboundSequenceLabel;

  @HiveField(7)
  List<int> outboundSequenceOrder;

  @HiveField(8)
  List<StorageContainer?> outboundSlots;

  // Lower deck slots
  @HiveField(9)
  List<StorageContainer?> lowerInboundSlots;

  @HiveField(10)
  List<StorageContainer?> lowerOutboundSlots;

  Plane({
    required this.id,
    required this.name,
    required this.aircraftTypeCode,
    required this.inboundSequenceLabel,
    required this.inboundSequenceOrder,
    required this.inboundSlots,
    required this.outboundSequenceLabel,
    required this.outboundSequenceOrder,
    required this.outboundSlots,
    required this.lowerInboundSlots,
    required this.lowerOutboundSlots,
  });
}
