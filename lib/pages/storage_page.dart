import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;
import '../providers/storage_provider.dart';
import '../widgets/uld_chip.dart';

class StoragePage extends ConsumerWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(storageProvider);

    // Debug: log slot count
    print('🟡 STORAGE SLOT COUNT: ${slots.length}');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Storage'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(slots.length, (index) {
            final container = slots[index];

            return DragTarget<model.StorageContainer>(
              onAccept: (c) {
                ref.read(storageProvider.notifier).placeContainer(index, c);
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
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    child:
                        container == null
                            ? const Text(
                              'Empty',
                              style: TextStyle(color: Colors.white54),
                            )
                            : LongPressDraggable<model.StorageContainer>(
                              data: container,
                              feedback: Material(
                                color: Colors.transparent,
                                child: UldChip(container),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: UldChip(container),
                              ),
                              child: UldChip(container),
                            ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
