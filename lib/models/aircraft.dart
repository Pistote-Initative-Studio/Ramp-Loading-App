enum SizeEnum { PAG_88x125, PRA_96x125, PLA_96x196, EMPTY, Custom }

class UldPosition {
  final int idx;
  final String row;
  final SizeEnum nominal;

  const UldPosition(this.idx, this.row, this.nominal);
}

class LoadingSequence {
  final String id;
  final String label;
  final List<int> order;

  const LoadingSequence(this.id, this.label, this.order);
}

class Aircraft {
  final String typeCode;
  final String name;
  final List<UldPosition> deck;
  final List<LoadingSequence> configs;

  const Aircraft(this.typeCode, this.name, this.deck, this.configs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Aircraft &&
          runtimeType == other.runtimeType &&
          typeCode == other.typeCode;

  @override
  int get hashCode => typeCode.hashCode;

  @override
  String toString() => name;
}
