import 'package:flutter/material.dart';
import 'color_palette.dart';

class ColorPickerDialog extends StatelessWidget {
  final Function(Color) onColorPicked;
  const ColorPickerDialog({super.key, required this.onColorPicked});

  @override
  Widget build(BuildContext context) {
    final colors = rampColors;

    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Pick Color', style: TextStyle(color: Colors.white)),
      content: Wrap(
        spacing: 8,
        children:
            colors
                .map(
                  (c) => GestureDetector(
                    onTap: () {
                      onColorPicked(c);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(backgroundColor: c, radius: 20),
                  ),
                )
                .toList(),
      ),
    );
  }
}
