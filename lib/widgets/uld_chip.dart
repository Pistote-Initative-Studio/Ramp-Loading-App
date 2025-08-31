// /lib/widgets/uld_chip.dart

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;

// Fixed size for a single ULD slot.
const double _kChipSize = 100.0;

class UldChip extends StatefulWidget {
  final model.StorageContainer uld;
  const UldChip(this.uld, {super.key});

  @override
  State<UldChip> createState() => _UldChipState();
}

class _UldChipState extends State<UldChip> {
  Future<void> _toggleDg(bool? value) async {
    if (value == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text('Confirm', style: TextStyle(color: Colors.white)),
            content: Text(
              value
                  ? 'Are you sure there are Dangerous Goods?'
                  : "Are you sure you've removed the Dangerous Goods?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() {
      widget.uld.dangerousGoods = value;
    });
    //persist change if object is backed by Hive
    try {
      widget.uld.save();
    } catch (_) {}
  }

  void _togglePallets(bool? value) {
    if (value == null) return;
    setState(() {
      widget.uld.hasPallets = value;
    });
    try {
      widget.uld.save();
    } catch (_) {}
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color activeColor,
  }) {
    return Transform.scale(
      scale: 0.8,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        checkColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDg = widget.uld.dangerousGoods;
    final hasPallets = widget.uld.hasPallets;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCheckbox(
              value: hasPallets,
              onChanged: _togglePallets,
              activeColor: Colors.blue,
            ),
            const SizedBox(width: 4),
            _buildCheckbox(
              value: hasDg,
              onChanged: _toggleDg,
              activeColor: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              widget.uld.uld,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    final inner = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 70,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
          child: content,
        ),
      ),
    );

    Widget decorated;

    if (hasDg && hasPallets) {
      decorated = DottedBorder(
        color: Colors.red,
        strokeWidth: 2,
        dashPattern: const [4, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: DottedBorder(
          color: Colors.blue,
          strokeWidth: 2,
          dashPattern: const [4, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: inner,
        ),
      );
    } else if (hasDg) {
      decorated = DottedBorder(
        color: Colors.red,
        strokeWidth: 2,
        dashPattern: const [4, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: inner,
      );
    } else if (hasPallets) {
      decorated = DottedBorder(
        color: Colors.blue,
        strokeWidth: 2,
        dashPattern: const [4, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: inner,
      );
    } else {
      decorated = DottedBorder(
        color: Colors.white,
        strokeWidth: 2,
        dashPattern: const [4, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        child: inner,
      );
    }

    return SizedBox(
      width: _kChipSize,
      height: _kChipSize,
      child: decorated,
    );
  }
}
