import 'package:hive/hive.dart';

part 'tug.g.dart';

@HiveType(typeId: 1)
class Tug {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final int colorIndex;

  Tug({required this.id, required this.label, required this.colorIndex});

  Tug copyWith({String? id, String? label, int? colorIndex}) {
    return Tug(
      id: id ?? this.id,
      label: label ?? this.label,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
