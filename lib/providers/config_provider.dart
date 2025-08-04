import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/aircraft.dart';
import '../models/train.dart';
import '../models/uld_type.dart';

class LoadConfig {
  final Aircraft aircraft;
  final List<UldType> allowedUlds;
  final List<Train> trains;

  LoadConfig({
    required this.aircraft,
    required this.allowedUlds,
    required this.trains,
  });
}

final configProvider = StateProvider<LoadConfig?>((ref) {
  // Default placeholder configuration to ensure provider is non-null.
  return LoadConfig(
    aircraft: const Aircraft('UNKNOWN', 'Unknown Aircraft', [], []),
    allowedUlds: const [],
    trains: const [],
  );
});
