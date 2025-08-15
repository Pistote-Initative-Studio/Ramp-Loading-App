// /lib/pages/ball_deck_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/container.dart' as model;
import '../providers/ball_deck_provider.dart';
import '../widgets/uld_chip.dart';
import '../models/aircraft.dart';
import '../widgets/slot_layout_constants.dart';
import '../widgets/transfer_menu.dart';
import '../utils/uld_mover.dart';
import '../utils/duplicate_checker.dart';

class BallDeckPage extends ConsumerWidget {
  const BallDeckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ballDeck = ref.watch(ballDeckProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ball Deck')),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Padding(
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
                    buildSlot(context, ref, slotUld, index),
                    const SizedBox(width: slotSpacing),
                    buildOverflowSlot(
                      context,
                      ref,
                      overflowUld1,
                      overflowStartIndex,
                    ),
                    const SizedBox(width: 8),
                    buildOverflowSlot(
                      context,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddUldDialog());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildSlot(
    BuildContext context,
    WidgetRef ref,
    model.StorageContainer? uld,
    int slotIdx,
  ) {
    return GestureDetector(
      onLongPressStart: uld == null
          ? (details) => showTransferMenu(
                context: context,
                ref: ref,
                position: details.globalPosition,
                onSelected: (c) {
                  ref
                      .read(ballDeckProvider.notifier)
                      .placeContainer(slotIdx, c);
                },
              )
          : null,
      child: DragTarget<model.StorageContainer>(
        onAcceptWithDetails: (details) {
          final container = details.data;
          removeFromAll(ref, container);
          ref
              .read(ballDeckProvider.notifier)
              .placeContainer(slotIdx, container);
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
    ),
    );
  }

  Widget buildOverflowSlot(
    BuildContext context,
    WidgetRef ref,
    model.StorageContainer? uld,
    int overflowIndex,
  ) {
    return GestureDetector(
      onLongPressStart: (uld == null || uld.type == SizeEnum.EMPTY)
          ? (details) => showTransferMenu(
                context: context,
                ref: ref,
                position: details.globalPosition,
                onSelected: (c) {
                  ref
                      .read(ballDeckProvider.notifier)
                      .placeIntoOverflowAt(c, overflowIndex);
                },
              )
          : null,
      child: DragTarget<model.StorageContainer>(
        onAcceptWithDetails: (details) {
          final container = details.data;
          removeFromAll(ref, container);
          ref
              .read(ballDeckProvider.notifier)
              .placeIntoOverflowAt(container, overflowIndex);
        },
        builder: (context, candidateData, rejectedData) {
          final isPlaceholder =
              uld == null ||
              uld.type == SizeEnum.EMPTY ||
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
                child: isPlaceholder
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
      ),
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
            if (label.isEmpty) return;

            final location = findUldLocation(ref, label);
            if (location != null) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.black,
                  content: Text(
                    'That ULD already exists at $location',
                    style: const TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ok'),
                    ),
                  ],
                ),
              );
              return;
            }

            ref.read(ballDeckProvider.notifier).addUld(
                  model.StorageContainer(
                    id: UniqueKey().toString(),
                    uld: label,
                    type: SizeEnum.Custom,
                    size: SizeEnum.PAG_88x125,
                    weightKg: 0,
                    dangerousGoods: false,
                    colorIndex: 0,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Add', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}
