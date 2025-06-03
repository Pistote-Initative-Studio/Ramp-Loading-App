import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final Function(Color) onColorPicked;
  const ColorPickerDialog({super.key, required this.onColorPicked});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.brown,
    ];

    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Pick Color', style: TextStyle(color: Colors.white)),
      content: Wrap(
        spacing: 8,
        children: colors.map((c) => GestureDetector(
          onTap: () {
            onColorPicked(c);
            Navigator.pop(context);
          },
          child: CircleAvatar(backgroundColor: c, radius: 20),
        )).toList(),
      ),
    );
  }
}
