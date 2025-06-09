// /lib/pages/ball_deck_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;
import '../providers/ball_deck_provider.dart';
import '../widgets/uld_chip.dart';
import '../models/aircraft.dart' as aircraftmodel; // For SizeEnum
import '../widgets/slot_layout_constants.dart';

class BallDeckPage extends ConsumerWidget {
  const BallDeckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ballDeck = ref.watch(ballDeckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ball Deck')),
      backgroundColor: Colors.black,
      body: Padding(
        padding: slotPadding,
        child: SingleChildScrollView(
          child: Column(
            children: List.generate(ballDeck.slots.length, (index) {
              final slotUld = ballDeck.slots[index];
              final overflowStartIndex = index * 2;

              final overflowUld1 =
                  overflowStartIndex < ballDeck.overflow.length
                      ? ballDeck.overflow[overflowStartIndex]
                      : null;
              final overflowUld2 =
                  overflowStartIndex + 1 < ballDeck.overflow.length
                      ? ballDeck.overflow[overflowStartIndex + 1]
                      : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: slotRunSpacing),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    buildSlot(ref, slotUld, index),
                    const SizedBox(width: slotSpacing),
                    buildOverflowSlot(ref, overflowUld1, overflowStartIndex),
                    const SizedBox(width: 8),
                    buildOverflowSlot(
                      ref,
                      overflowUld2,
                      overflowStartIndex + 1,
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddUldDialog());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildSlot(WidgetRef ref, model.StorageContainer? uld, int slotIdx) {
    return DragTarget<model.StorageContainer>(
      onAccept: (container) {
        ref.read(ballDeckProvider.notifier).placeContainer(slotIdx, container);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.yellow : Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child:
                uld == null
                    ? const SizedBox()
                    : LongPressDraggable<model.StorageContainer>(
                      data: uld,
                      feedback: Material(
                        color: Colors.transparent,
                        child: UldChip(uld),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: UldChip(uld),
                      ),
                      child: UldChip(uld),
                    ),
          ),
        );
      },
    );
  }

  Widget buildOverflowSlot(
    WidgetRef ref,
    model.StorageContainer? uld,
    int overflowIndex,
  ) {
    return DragTarget<model.StorageContainer>(
      onAccept: (container) {
        ref
            .read(ballDeckProvider.notifier)
            .placeIntoOverflowAt(container, overflowIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isPlaceholder =
            uld == null ||
            uld.type == aircraft_model.SizeEnum.Empty ||
            uld.uld.startsWith('EMPTY_SLOT');
        return DottedBorder(
          color: candidateData.isNotEmpty ? Colors.yellow : Colors.white,
          strokeWidth: 2,
          dashPattern: [4, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: Container(
            width: 80,
            height: 80,
            color: Colors.transparent,
            child: Center(
              child:
                  isPlaceholder
                      ? const SizedBox()
                      : LongPressDraggable<model.StorageContainer>(
                        data: uld,
                        feedback: Material(
                          color: Colors.transparent,
                          child: UldChip(uld),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.2,
                          child: UldChip(uld),
                        ),
                        child: UldChip(uld),
                      ),
            ),
          ),
        );
      },
    );
  }
}

class AddUldDialog extends ConsumerStatefulWidget {
  const AddUldDialog({super.key});

  @override
  ConsumerState<AddUldDialog> createState() => _AddUldDialogState();
}

class _AddUldDialogState extends ConsumerState<AddUldDialog> {
  final _idController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Add ULD', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _idController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'ULD ID',
          labelStyle: TextStyle(color: Colors.white54),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () {
            final label = _idController.text.trim();
            if (label.isNotEmpty) {
              ref
                  .read(ballDeckProvider.notifier)
                  .addUld(
                    model.StorageContainer(
                      id: UniqueKey().toString(),
                      uld: label,
                      type: 'Custom',
                      size: model.SizeEnum.PAG_88x125,
                      weightKg: 0,
                      hasDangerousGoods: false,
                      colorIndex: 0,
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Add', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}
