import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;
import '../models/aircraft.dart';
import '../providers/aircraft_provider.dart';
import '../providers/plane_provider.dart';
import '../widgets/uld_chip.dart';

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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (1L to 9L)
                        Expanded(
                          child: Column(
                            children: List.generate(9, (i) {
                              return _buildSlot(ref, i * 2, '${i + 1}L');
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column (1R to 9R)
                        Expanded(
                          child: Column(
                            children: List.generate(9, (i) {
                              return _buildSlot(ref, i * 2 + 1, '${i + 1}R');
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSlot(ref, 18, 'A10'), // Center slot
                  ],
                ),
              ),
    );
  }

  Widget _buildSlot(WidgetRef ref, int index, String label) {
    final container = ref.watch(planeProvider).slots[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DragTarget<model.StorageContainer>(
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
