import 'package:hive/hive.dart';

import 'aircraft.dart';

class SizeEnumAdapter extends TypeAdapter<SizeEnum> {
  @override
  final int typeId = 5;

  @override
  SizeEnum read(BinaryReader reader) {
    final index = reader.read() as int;
    return SizeEnum.values[index];
  }

  @override
  void write(BinaryWriter writer, SizeEnum obj) {
    writer.write(obj.index);
  }
}
