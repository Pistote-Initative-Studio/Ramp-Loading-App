import 'package:hive/hive.dart';
import 'container.dart';

part 'train.g.dart';

@HiveType(typeId: 2)
class Dolly {
  @HiveField(0)
  final int idx;

  @HiveField(1)
  final StorageContainer? load;

  const Dolly(this.idx, {this.load});
}

@HiveType(typeId: 3)
class Train {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final int dollyCount;

  @HiveField(3)
  final List<Dolly> dollys;

  @HiveField(4)
  final int colorIndex;

  Train({
    required this.id,
    required this.label,
    required this.dollyCount,
    required this.dollys,
    required this.colorIndex,
  });

  factory Train.withAutoDolly({
    required String id,
    required String label,
    required int dollyCount,
    required int colorIndex,
  }) {
    return Train(
      id: id,
      label: label,
      dollyCount: dollyCount,
      dollys: List.generate(dollyCount, (i) => Dolly(i + 1)),
      colorIndex: colorIndex,
    );
  }

  Train copyWith({
    String? id,
    String? label,
    int? dollyCount,
    List<Dolly>? dollys,
    int? colorIndex,
  }) {
    return Train(
      id: id ?? this.id,
      label: label ?? this.label,
      dollyCount: dollyCount ?? this.dollyCount,
      dollys: dollys ?? this.dollys,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }
}
