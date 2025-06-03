import 'aircraft.dart';

class UldType {
  final String code;
  final String label;
  final SizeEnum size;
  final bool isFlat;

  UldType({
    required this.code,
    required this.label,
    required this.size,
    this.isFlat = false,
  });
}
