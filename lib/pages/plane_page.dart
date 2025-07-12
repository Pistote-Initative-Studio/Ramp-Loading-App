import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hive/hive.dart';
import '../models/container.dart' as model;
import '../models/aircraft.dart';
import '../providers/aircraft_provider.dart';
import '../providers/plane_provider.dart'
    show planeProvider, isOutboundProvider;
import '../providers/planes_provider.dart';
import '../providers/lower_deck_provider.dart';
import '../models/plane.dart';
import '../widgets/uld_chip.dart';
import '../widgets/slot_layout_constants.dart';
import '../widgets/transfer_menu.dart';
import '../utils/uld_mover.dart';

final List<Aircraft> aircraftList = [
  Aircraft('B762', 'Boeinf 767-200 Freighter', [], [
    LoadingSequence('A', 'A', List.generate(19, (i) => i)),
    LoadingSequence('B', 'B', List.generate(21, (i) => i)),
    LoadingSequence('C', 'C', List.generate(10, (i) => i)),
    LoadingSequence('D', 'D', List.generate(13, (i) => i)),
    LoadingSequence('E', 'E', List.generate(12, (i) => i)),
  ]),
  Aircraft('B763', 'Boeing 767-300 Freighter', [], []),
  Aircraft('B752', 'Boeing 757-200 Freighter', [], []),
];

final lowerDeckviewProvider = StateProvider<bool>((ref) => false);

class PlanePage extends ConsumerWidget {
  const PlanePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Hive.isBoxOpen('planeBox')) {
      return _buildNoPlaneScaffold();
    }

    final planes = ref.watch(planesProvider);
    if (planes.isEmpty) {
      return _buildNoPlaneScaffold();
    }

    final selectedId = ref.watch(selectedPlaneIdProvider);
    final aircraft = ref.watch(aircraftProvider);
    final planeState = ref.watch(planeProvider);
    final isOutbound = ref.watch(isOutboundProvider);
    final isLowerDeck = ref.watch(lowerDeckviewProvider);
    final configs = planeState.configs;
    final sequence =
        isOutbound ? planeState.outboundSequence : planeState.inboundSequence;

    LoadingSequence? selectedConfig;
    if (sequence != null) {
      try {
        selectedConfig = configs.firstWhere((c) => c.label == sequence.label);
      } catch (_) {}
    }

    Plane? selectedPlane;
    if (selectedId != null) {
      try {
        selectedPlane = planes.firstWhere((p) => p.id == selectedId);
      } catch (_) {}
    }
    if (selectedPlane == null && planes.isNotEmpty) {
      selectedPlane = planes.first;
      ref.read(selectedPlaneIdProvider.notifier).state = selectedPlane.id;
      final intialAircraft =
          aircraft ??
          aircraftList.firstWhere(
            (a) => a.typeCode == selectedPlane?.aircraftTypeCode,
            orElse: () => aircraftList.first,
          );
      ref.read(aircraftProvider.notifier).state = intialAircraft;
      ref
          .read(planeProvider.notifier)
          .loadPlane(selectedPlane, intialAircraft.configs);
      ref.read(lowerDeckProvider.notifier).loadFromPlane(selectedPlane);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Plane'),
        backgroundColor: Colors.black,
        actions: [
          if (planes.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLowerDeck ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    ref.read(lowerDeckviewProvider.notifier).state =
                        !isLowerDeck;
                  },
                ),
                DropdownButton<String>(
                  value: selectedPlane?.id,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Colors.black,
                  items:
                      planes
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    ref.read(selectedPlaneIdProvider.notifier).state = val;
                    final plane = planes.firstWhere((p) => p.id == val);
                    final aircraft = aircraftList.firstWhere(
                      (a) => a.typeCode == plane.aircraftTypeCode,
                      orElse: () => aircraftList.first,
                    );
                    ref
                        .read(planeProvider.notifier)
                        .loadPlane(plane, aircraft.configs);
                    ref.read(lowerDeckProvider.notifier).loadFromPlane(plane);
                    ref.read(aircraftProvider.notifier).state = aircraft;
                  },
                ),
                if (configs.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  DropdownButton<LoadingSequence>(
                    value: selectedConfig,
                    underline: const SizedBox.shrink(),
                    dropdownColor: Colors.black,
                    items:
                        configs
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c.label,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (cfg) {
                      if (cfg == null) return;
                      ref
                          .read(planeProvider.notifier)
                          .selectSequence(cfg, outbound: isOutbound);
                      final pid = selectedPlane?.id;
                      if (pid != null) {
                        final plane = planes.firstWhere((p) => p.id == pid);
                        final updated = ref
                            .read(planeProvider.notifier)
                            .exportPlane(plane);
                        ref.read(planesProvider.notifier).updatePlane(updated);
                      }
                    },
                  ),
                ],
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text(
                      'Inbound',
                      style: TextStyle(color: Colors.white),
                    ),
                    Switch(
                      value: isOutbound,
                      onChanged: (val) {
                        ref.read(isOutboundProvider.notifier).state = val;
                      },
                    ),
                    const Text(
                      'Outbound',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
      body:
          aircraft == null || sequence == null
              ? const Center(
                child: Text(
                  'Please select a plane and configuration using the dropdowns above.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
              : SingleChildScrollView(
                padding: slotPadding,
                child: isLowerDeck
                    ? _buildLowerDeckLayout(context, ref, isOutbound)
                    : _buildLayout(context, ref, sequence, isOutbound),
              ),
    );
  }

  Widget _buildNoPlaneScaffold() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Plane'), backgroundColor: Colors.black),
      body: const Center(
        child: Text(
          'No plane selected. Please add a plane on the Config Page.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    WidgetRef ref,
    LoadingSequence sequence,
    bool outbound,
  ) {
    final plane = ref.watch(planeProvider);
    final slots = outbound ? plane.outboundSlots : plane.inboundSlots;
    final columns = _columnCount(sequence);

    if (columns == 2) {
      final pairCount = slots.length ~/ 2;
      final remainder = slots.length % 2;

      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: List.generate(pairCount, (i) {
                    final index = i * 2;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            i == pairCount - 1 && remainder == 0
                                ? 0
                                : slotRunSpacing,
                      ),
                      child: _buildSlot(
                        context,
                        ref,
                        index,
                        _slotLabel(index),
                        outbound,
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(width: slotSpacing),
              Expanded(
                child: Column(
                  children: List.generate(pairCount, (i) {
                    final index = i * 2 + 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            i == pairCount - 1 && remainder == 0
                                ? 0
                                : slotRunSpacing,
                      ),
                      child: _buildSlot(
                        context,
                        ref,
                        index,
                        _slotLabel(index),
                        outbound,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          if (remainder == 1) ...[
            SizedBox(height: slotRunSpacing),
            _buildSlot(
              context,
              ref,
              pairCount * 2,
              _slotLabel(pairCount * 2),
              outbound,
            ),
          ],
        ],
      );
    } else if (columns == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(slots.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == slots.length - 1 ? 0 : slotRunSpacing,
            ),
            child: _buildSlot(
              context,
              ref,
              i,
              _slotLabel(i),
              outbound,
            ),
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
                    child: _buildSlot(
                      context,
                      ref,
                      i * 2,
                      '${i + 1}L',
                      outbound,
                    ),
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
                    child: _buildSlot(
                      context,
                      ref,
                      i * 2 + 1,
                      '${i + 1}R',
                      outbound,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSlot(
          context,
          ref,
          18,
          'A10',
          outbound,
        ),
      ],
    );
  }

  Widget _buildLowerDeckLayout(
    BuildContext context,
    WidgetRef ref,
    bool outbound,
  ) {
    final deck = ref.watch(lowerDeckProvider);
    final slots = outbound ? deck.outboundSlots : deck.inboundSlots;
    const labels = [
      '1AC',
      '1BC',
      '1CC',
      '2DC',
      '2EC',
      '2FC',
      '3AC',
      '3BC',
      '3CC',
      '4DC',
      '4EC',
    ];

    final children = <Widget>[];
    for (int i = 0; i < slots.length; i++) {
      if (i == 6) {
        children.add(const SizedBox(height: 116)); // Spacing between sections
      }
      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i == slots.length - 1 ? 0 : slotRunSpacing,
          ),
          child: _buildLowerDeckSlot(context, ref, i, labels[i], outbound),
        ),
      );
    }
    return Column(children: children);
  }

  Widget _buildLowerDeckSlot(
    BuildContext context,
    WidgetRef ref,
    int index,
    String label,
    bool outbound,
  ) {
    final deck = ref.watch(lowerDeckProvider);
    final container =
        outbound ? deck.outboundSlots[index] : deck.inboundSlots[index];

    return GestureDetector(
      onLongPressStart: container == null
          ? (details) => showTransferMenu(
                context: context,
                ref: ref,
                position: details.globalPosition,
                onSelected: (c) {
                  ref
                      .read(lowerDeckProvider.notifier)
                      .placeContainer(index, c, outbound: outbound);
                  ref
                      .read(planeProvider.notifier)
                      .placeLowerDeckContainer(index, c, outbound: outbound);
                  final planeId = ref.watch(selectedPlaneIdProvider);
                  if (planeId != null) {
                    final planes = ref.read(planesProvider);
                    try {
                      final plane =
                          planes.firstWhere((p) => p.id == planeId);
                      final updated =
                          ref.read(planeProvider.notifier).exportPlane(plane);
                      ref.read(planesProvider.notifier).updatePlane(updated);
                    } catch (_) {}
                  }
                },
              )
          : null,
      child: DragTarget<model.StorageContainer>(
        onAccept: (c) {
          removeFromAll(ref, c);
          ref
              .read(lowerDeckProvider.notifier)
              .placeContainer(index, c, outbound: outbound);
          ref
              .read(planeProvider.notifier)
              .placeLowerDeckContainer(index, c, outbound: outbound);
        final planeId = ref.watch(selectedPlaneIdProvider);
        if (planeId != null) {
          final planes = ref.read(planesProvider);
          try {
            final plane = planes.firstWhere((p) => p.id == planeId);
            final updated = ref.read(planeProvider.notifier).exportPlane(plane);
            ref.read(planesProvider.notifier).updatePlane(updated);
          } catch (_) {}
        }
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
                    ? Text(label, style: const TextStyle(color: Colors.white70))
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

  Widget _buildSlot(
    BuildContext context,
    WidgetRef ref,
    int index,
    String label,
    bool outbound,
  ) {
    final planeState = ref.watch(planeProvider);
    final container =
        outbound
            ? planeState.outboundSlots[index]
            : planeState.inboundSlots[index];

    final planeId = ref.watch(selectedPlaneIdProvider);

    return GestureDetector(
      onLongPressStart: container == null
          ? (details) => showTransferMenu(
                context: context,
                ref: ref,
                position: details.globalPosition,
                onSelected: (c) {
                  ref
                      .read(planeProvider.notifier)
                      .placeContainer(index, c, outbound: outbound);
                  final pid = ref.watch(selectedPlaneIdProvider);
                  if (pid != null) {
                    final planes = ref.read(planesProvider);
                    try {
                      final plane = planes.firstWhere((p) => p.id == pid);
                      final updated =
                          ref.read(planeProvider.notifier).exportPlane(plane);
                      ref.read(planesProvider.notifier).updatePlane(updated);
                    } catch (_) {}
                  }
                },
              )
          : null,
      child: DragTarget<model.StorageContainer>(
        onAccept: (c) {
          removeFromAll(ref, c);
          ref
              .read(planeProvider.notifier)
              .placeContainer(index, c, outbound: outbound);
          if (planeId != null) {
            final planes = ref.read(planesProvider);
            try {
              final plane = planes.firstWhere((p) => p.id == planeId);
              final updated =
                  ref.read(planeProvider.notifier).exportPlane(plane);
              ref.read(planesProvider.notifier).updatePlane(updated);
            } catch (_) {}
          }
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
              child: container == null
                  ? Text(label, style: const TextStyle(color: Colors.white70))
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
