// /lib/widgets/uld_chip.dart

import 'package:flutter/material.dart';
import '../models/container.dart' as model;

class UldChip extends StatelessWidget {
  final model.StorageContainer uld;
  const UldChip(this.uld, {super.key});

  @override
  Widget build(BuildContext context) {
    final outlineColor =
        uld.colorIndex != null
            ? Colors.primaries[uld.colorIndex! % Colors.primaries.length]
            : Colors.white54;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: outlineColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        uld.uld,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
