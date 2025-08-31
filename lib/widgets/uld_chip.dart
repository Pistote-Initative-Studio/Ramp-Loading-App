// /lib/widgets/uld_chip.dart

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;

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

  @override
  Widget build(BuildContext context) {
    final hasDg = widget.uld.dangerousGoods;
    final hasPallets = widget.uld.hasPallets;

    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        widget.uld.uld,
        style: const TextStyle(fontSize: 12, color: Colors.white),
        textAlign: TextAlign.center,
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

    return Stack(
      children: [
        decorated,
        Positioned(
          top: -4,
          left: -4,
          child: Column(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: hasPallets,
                  onChanged: _togglePallets,
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                ),
              ),
              const Text('P',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Column(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Checkbox(
                  value: hasDg,
                  onChanged: _toggleDg,
                  activeColor: Colors.red,
                  checkColor: Colors.white,
                ),
              ),
              const Text('DG',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}
