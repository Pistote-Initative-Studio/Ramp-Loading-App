import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;
import '../models/aircraft.dart';
import '../providers/aircraft_provider.dart';
import '../providers/plane_provider.dart';
import '../widgets/uld_chip.dart';
import '../widgets/slot_layout_constants.dart'

class PlanePage extends ConsumerWidget {
  const PlanePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aircraft = ref.watch(aircraftProvider);
    final planeState = ref.watch(planeProvider);
    final sequence = planeState.selectedSequence;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Plane'), backgroundColor: Colors.black),
      body:
          aircraft == null || sequence == null
              ? const Center(
                child: Text(
                  'Please select an aircraft and configuration on the Config Page.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              padding: slotPadding,
              child: _buildLayout(ref, sequence),
                ),
              ),
    );
  }

 Widget _buildLayout(WidgetRef ref, LoadingSequence sequence) {
    final slots = ref.watch(planeProvider).slots;
    final columns = _columnCount(sequence);

    if (columns == 2) {
      return Wrap(
        direction: Axis.vertical,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: slotSpacing,
        runSpacing: slotRunSpacing,
        children: List.generate(slots.length,
            (i) => _buildSlot(ref, i, _slotLabel(i))),
      );
    } else if (columns == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(slots.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: i == slots.length - 1 ? 0 : slotRunSpacing),
            child: _buildSlot(ref, i, _slotLabel(i)),
          );
        }),
      );
    }

    // Fallback for future configurations.
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: List.generate(9, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: slotRunSpacing),
                    child: _buildSlot(ref, i * 2, '${i + 1}L'),
                  );
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: List.generate(9, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: slotRunSpacing),
                    child: _buildSlot(ref, i * 2 + 1, '${i + 1}R'),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSlot(ref, 18, 'A10'),
      ],
    );
  }

  int _columnCount(LoadingSequence sequence) {
    final count = sequence.order.length;
    if (count >= 18) return 2; // e.g. 767-200 config A
    if (count <= 10) return 1;
    return 0;
  }

  String _slotLabel(int index) {
    if (index == 18) return 'A10';
    final row = index ~/ 2 + 1;
    final side = index % 2 == 0 ? 'L' : 'R';
    return '$row$side';
  }

  Widget _buildSlot(WidgetRef ref, int index, String label) {
    final container = ref.watch(planeProvider).slots[index];

    return DragTarget<model.StorageContainer>(
        onAccept: (c) {
          ref.read(planeProvider.notifier).placeContainer(index, c);
        },
        builder: (context, candidateData, rejectedData) {
          final isActive = candidateData.isNotEmpty;
          return DottedBorder(
            color: isActive ? Colors.yellow : Colors.white,
            strokeWidth: 2,
            dashPattern: container == null ? [4, 4] : [1, 0],
            borderType: BorderType.RRect,
            radius: const Radius.circular(8),
            child: Container(
              width: 100, // Same as Ball Deck
              height: 100, // Same as Ball Deck
              alignment: Alignment.center,
              child:
                  container == null
                      ? Text(
                        label,
                        style: const TextStyle(color: Colors.white70),
                      )
                      : LongPressDraggable<model.StorageContainer>(
                        data: container,
                        feedback: Material(
                          color: Colors.transparent,
                          child: UldChip(container),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.2,
                          child: UldChip(container),
                        ),
                        child: UldChip(container),
                      ),
            ),
          );
        },
      ),
    );
  }
}
