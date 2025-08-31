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
  Aircraft('B762', 'Boeing 767-200 Freighter', [], [
    LoadingSequence('A', 'A', List.generate(19, (i) => i)),
    LoadingSequence('B', 'B', List.generate(21, (i) => i)),
    LoadingSequence('C', 'C', List.generate(10, (i) => i)),
    LoadingSequence('D', 'D', List.generate(13, (i) => i)),
    LoadingSequence('E', 'E', List.generate(12, (i) => i)),
  ]),
  Aircraft('B763', 'Boeing 767-300 Freighter', [], [
    LoadingSequence('A', 'A', List.generate(17, (i) => i)),
    LoadingSequence('B', 'B', List.generate(13, (i) => i)),
    LoadingSequence('C', 'C', List.generate(24, (i) => i)),
  ]),
  Aircraft('B752', 'Boeing 757-200 Freighter', [], []),
];

final lowerDeckviewProvider = StateProvider<bool>((ref) => false);

// Width of a single column of ULD slots. Used to center single-column
// layouts for both main deck and lower deck views.
const double _kSingleColumnWidth = 100.0;

// Lower deck labels for supported aircraft
const List<String> _kB762LowerDeckLabels = [
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

const List<String> _kB763LowerDeckLabels = [
  '11',
  '12',
  '13',
  '14',
  '21',
  '22',
  '23',
  '24',
  '31',
  '32',
  '33',
  '34',
  '41',
  '42',
  '43',
];

class PlanePage extends ConsumerStatefulWidget {
  const PlanePage({super.key});

  @override
  ConsumerState<PlanePage> createState() => _PlanePageState();
}

class _PlanePageState extends ConsumerState<PlanePage> {
  final _gridKey = GlobalKey();
  final Map<String, GlobalKey> _slotKeys = {};
  Rect? _doorMarkerRect;
  Rect? _lowerDeckMarker14;
  Rect? _lowerDeckMarkerDoor;
  Rect? _lowerDeckSplitRect;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    try {
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
        } catch (_) {
          // Config not found, ignore
        }
      }

      Plane? selectedPlane;
      if (selectedId != null && selectedId.isNotEmpty) {
        try {
          selectedPlane = planes.firstWhere((p) => p.id == selectedId);
        } catch (_) {
          // Plane not found, will set to first available below
        }
      }
      
      if (selectedPlane == null && planes.isNotEmpty) {
        selectedPlane = planes.first;
        // Safely update the selected plane ID
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedPlaneIdProvider.notifier).state = selectedPlane!.id;
          final initialAircraft =
              aircraft ??
              aircraftList.firstWhere(
                (a) => a.typeCode == selectedPlane?.aircraftTypeCode,
                orElse: () => aircraftList.first,
              );
          ref.read(aircraftProvider.notifier).state = initialAircraft;
          ref
              .read(planeProvider.notifier)
              .loadPlane(selectedPlane, initialAircraft.configs);
          ref.read(lowerDeckProvider.notifier).loadFromPlane(selectedPlane);
        });
      }

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Plane'),
          backgroundColor: Colors.black,
          actions: [
            if (planes.isNotEmpty && selectedPlane != null)
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
                    value: selectedPlane.id,
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
        body: Column(
          children: [
            Expanded(
              child: aircraft == null || sequence == null || selectedPlane == null
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
                          : _buildMainDeckWithDoor(context, ref, sequence, isOutbound),
                    ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Catch any errors and show a safe fallback
      print('Error in PlanePage: $e');
      return _buildNoPlaneScaffold();
    }
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

  Widget _buildMainDeckWithDoor(
    BuildContext context,
    WidgetRef ref,
    LoadingSequence sequence,
    bool outbound,
  ) {
    _slotKeys.clear();
    final grid = _buildLayout(context, ref, sequence, outbound);
    WidgetsBinding.instance.addPostFrameCallback((_) => _repositionDoorMarker());
    return Stack(
      key: _gridKey,
      children: [
        grid,
        if (_doorMarkerRect != null)
          Positioned(
            left: _doorMarkerRect!.left,
            top: _doorMarkerRect!.top,
            child: IgnorePointer(
              child: Container(
                width: _doorMarkerRect!.width,
                height: _doorMarkerRect!.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Rect? _rectForSlot(String slotId) {
    final key = _slotKeys[slotId];
    if (key?.currentContext == null || _gridKey.currentContext == null) {
      return null;
    }
    final slotBox = key!.currentContext!.findRenderObject() as RenderBox;
    final stackBox = _gridKey.currentContext!.findRenderObject() as RenderBox;
    final slotPos = slotBox.localToGlobal(Offset.zero, ancestor: stackBox);
    return Rect.fromLTWH(
      slotPos.dx,
      slotPos.dy,
      slotBox.size.width,
      slotBox.size.height,
    );
  }

  void _repositionDoorMarker() {
    final aircraft = ref.read(aircraftProvider);
    final isLowerDeck = ref.read(lowerDeckviewProvider);
    final type = aircraft?.typeCode;
    if (isLowerDeck || (type != 'B763' && type != 'B762')) {
      if (_doorMarkerRect != null) {
        setState(() => _doorMarkerRect = null);
      }
      return;
    }
    final planeState = ref.read(planeProvider);
    final isOutbound = ref.read(isOutboundProvider);
    final sequence =
        isOutbound ? planeState.outboundSequence : planeState.inboundSequence;
    String? label;
    if (type == 'B763') {
      switch (sequence?.label) {
        case 'A':
          label = 'A3';
          break;
        case 'B':
          label = 'B3';
          break;
        case 'C':
          label = '3L';
          break;
        default:
          label = null;
      }
    } else if (type == 'B762') {
      switch (sequence?.label) {
        case 'A':
        case 'B':
          label = '2L';
          break;
        case 'C':
        case 'D':
          label = '1R';
          break;
        case 'E':
          label = '2';
          break;
        default:
          label = null;
      }
    }
    if (label == null) {
      if (_doorMarkerRect != null) {
        setState(() => _doorMarkerRect = null);
      }
      return;
    }
    final slotRect = _rectForSlot(label);
    if (slotRect == null) {
      if (_doorMarkerRect != null) {
        setState(() => _doorMarkerRect = null);
      }
      return;
    }
    const doorWidth = 3.0;
    const doorGap = 8.0;
    final rect = Rect.fromLTWH(
      slotRect.left - doorGap - doorWidth,
      slotRect.top,
      doorWidth,
      slotRect.height,
    );
    if (_doorMarkerRect != rect) {
      setState(() {
        _doorMarkerRect = rect;
      });
    }
  }

  void _repositionLowerDeckMarkers() {
    final aircraft = ref.read(aircraftProvider);
    final isLowerDeck = ref.read(lowerDeckviewProvider);
    final type = aircraft?.typeCode;
    if (!isLowerDeck || (type != 'B763' && type != 'B762')) {
      if (_lowerDeckMarker14 != null ||
          _lowerDeckMarkerDoor != null ||
          _lowerDeckSplitRect != null) {
        setState(() {
          _lowerDeckMarker14 = null;
          _lowerDeckMarkerDoor = null;
          _lowerDeckSplitRect = null;
        });
      }
      return;
    }

    const thickness = 2.0;
    const offset = 8.0;

    if (type == 'B763') {
      final rect12 = _rectForSlot('12');
      final rect42 = _rectForSlot('42');
      final rect24 = _rectForSlot('24');
      final rect31 = _rectForSlot('31');
      if (rect12 == null || rect42 == null || rect24 == null || rect31 == null) {
        if (_lowerDeckMarker14 != null ||
            _lowerDeckMarkerDoor != null ||
            _lowerDeckSplitRect != null) {
          setState(() {
            _lowerDeckMarker14 = null;
            _lowerDeckMarkerDoor = null;
            _lowerDeckSplitRect = null;
          });
        }
        return;
      }
      final marker12 = Rect.fromLTWH(
        rect12.right + offset,
        rect12.top,
        thickness,
        rect12.height,
      );
      final markerDoor = Rect.fromLTWH(
        rect42.right + offset,
        rect42.top,
        thickness,
        rect42.height,
      );
      final splitTop = (rect24.bottom + rect31.top) / 2 - thickness / 2;
      final splitRect = Rect.fromLTWH(
        rect24.left,
        splitTop,
        rect24.width,
        thickness,
      );
      if (_lowerDeckMarker14 != marker12 ||
          _lowerDeckMarkerDoor != markerDoor ||
          _lowerDeckSplitRect != splitRect) {
        setState(() {
          _lowerDeckMarker14 = marker12;
          _lowerDeckMarkerDoor = markerDoor;
          _lowerDeckSplitRect = splitRect;
        });
      }
      return;
    }

    // B762 lower deck markers
    final rect2dc = _rectForSlot('2DC');
    final rect4dc = _rectForSlot('4DC');
    final rect2fc = _rectForSlot('2FC');
    final rect3ac = _rectForSlot('3AC');
    if (rect2dc == null || rect4dc == null || rect2fc == null || rect3ac == null) {
      if (_lowerDeckMarker14 != null ||
          _lowerDeckMarkerDoor != null ||
          _lowerDeckSplitRect != null) {
        setState(() {
          _lowerDeckMarker14 = null;
          _lowerDeckMarkerDoor = null;
          _lowerDeckSplitRect = null;
        });
      }
      return;
    }
    final marker2dc = Rect.fromLTWH(
      rect2dc.right + offset,
      rect2dc.top,
      thickness,
      rect2dc.height,
    );
    final markerDoor = Rect.fromLTWH(
      rect4dc.right + offset,
      rect4dc.top,
      thickness,
      rect4dc.height,
    );
    final splitTop = (rect2fc.bottom + rect3ac.top) / 2 - thickness / 2;
    final splitRect = Rect.fromLTWH(
      rect2fc.left,
      splitTop,
      rect2fc.width,
      thickness,
    );
    if (_lowerDeckMarker14 != marker2dc ||
        _lowerDeckMarkerDoor != markerDoor ||
        _lowerDeckSplitRect != splitRect) {
      setState(() {
        _lowerDeckMarker14 = marker2dc;
        _lowerDeckMarkerDoor = markerDoor;
        _lowerDeckSplitRect = splitRect;
      });
    }
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
    final aircraft = ref.watch(aircraftProvider);

    if (aircraft?.typeCode == 'B763' && sequence.label == 'C') {
      // For 767-300 Config C: 1 at top, 2L-12L and 2R-12R in columns, A13 at bottom
      final leftColumnSlots = <int>[];
      final rightColumnSlots = <int>[];
      
      // Build left column (2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L)
      for (int i = 1; i < slots.length - 1; i += 2) {
        leftColumnSlots.add(i);
      }
      
      // Build right column (2R, 3R, 4R, 5R, 6R, 7R, 8R, 9R, 10R, 11R, 12R)  
      for (int i = 2; i < slots.length - 1; i += 2) {
        rightColumnSlots.add(i);
      }
      
      return Column(
        children: [
          // Slot 1 at top
          _buildSlot(
            context,
            ref,
            0,
            _slotLabel(ref, sequence, 0),
            outbound,
          ),
          SizedBox(height: slotRunSpacing),
          
          // Two columns: Left (2L-12L) and Right (2R-12R)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: leftColumnSlots.map((index) {
                    final isLast = index == leftColumnSlots.last;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : slotRunSpacing,
                      ),
                      child: _buildSlot(
                        context,
                        ref,
                        index,
                        _slotLabel(ref, sequence, index),
                        outbound,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(width: slotSpacing),
              Expanded(
                child: Column(
                  children: rightColumnSlots.map((index) {
                    final isLast = index == rightColumnSlots.last;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast ? 0 : slotRunSpacing,
                      ),
                      child: _buildSlot(
                        context,
                        ref,
                        index,
                        _slotLabel(ref, sequence, index),
                        outbound,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: slotRunSpacing),
          
          // A13 at bottom (centered)
          _buildSlot(
            context,
            ref,
            slots.length - 1,
            _slotLabel(ref, sequence, slots.length - 1),
            outbound,
          ),
        ],
      );
    }

    if (columns == 2) {
      if (sequence.order.length == 24) {
        final pairCount = (slots.length - 2) ~/ 2;
        return Column(
          children: [
            _buildSlot(
              context,
              ref,
              0,
              _slotLabel(ref, sequence, 0),
              outbound,
            ),
            SizedBox(height: slotRunSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: List.generate(pairCount, (i) {
                      final index = i * 2 + 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == pairCount - 1 ? 0 : slotRunSpacing,
                        ),
                        child: _buildSlot(
                          context,
                          ref,
                          index,
                          _slotLabel(ref, sequence, index),
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
                      final index = i * 2 + 2;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i == pairCount - 1 ? 0 : slotRunSpacing,
                        ),
                        child: _buildSlot(
                          context,
                          ref,
                          index,
                          _slotLabel(ref, sequence, index),
                          outbound,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            SizedBox(height: slotRunSpacing),
            _buildSlot(
              context,
              ref,
              slots.length - 1,
              _slotLabel(ref, sequence, slots.length - 1),
              outbound,
            ),
          ],
        );
      }

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
                        _slotLabel(ref, sequence, index),
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
                        _slotLabel(ref, sequence, index),
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
              _slotLabel(ref, sequence, pairCount * 2),
              outbound,
            ),
          ],
        ],
      );
    } else if (columns == 1) {
      if ((aircraft?.typeCode == 'B763' &&
              (sequence.label == 'A' || sequence.label == 'B')) ||
          (aircraft?.typeCode == 'B762' &&
              (sequence.label == 'C' ||
                  sequence.label == 'D' ||
                  sequence.label == 'E'))) {
        return LayoutBuilder(
          builder: (context, constraints) {
            const columnWidth = _kSingleColumnWidth;
            final availableWidth = constraints.maxWidth;
            final centeredLeft = (availableWidth - columnWidth) / 2;
            return Padding(
              padding: EdgeInsets.only(left: centeredLeft),
              child: Column(
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
                      _slotLabel(ref, sequence, i),
                      outbound,
                    ),
                  );
                }),
              ),
            );
          },
        );
      }
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
              _slotLabel(ref, sequence, i),
              outbound,
            ),
          );
        }),
      );
    }

    // Fallback for future configurations: display slots in a centered column.
    return LayoutBuilder(
      builder: (context, constraints) {
        const columnWidth = _kSingleColumnWidth;
        final availableWidth = constraints.maxWidth;
        final centeredLeft = (availableWidth - columnWidth) / 2;
        return Padding(
          padding: EdgeInsets.only(left: centeredLeft),
          child: Column(
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
                  _slotLabel(ref, sequence, i),
                  outbound,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildLowerDeckLayout(
    BuildContext context,
    WidgetRef ref,
    bool outbound,
  ) {
    _slotKeys.clear();
    ref.watch(lowerDeckProvider);
    final aircraft = ref.watch(aircraftProvider);
    final labels = aircraft?.typeCode == 'B762'
        ? _kB762LowerDeckLabels
        : _kB763LowerDeckLabels;

    final children = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      children.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i == labels.length - 1 ? 0 : slotRunSpacing,
          ),
          child: _buildLowerDeckSlot(context, ref, i, labels[i], outbound),
        ),
      );
    }
    final grid = Center(
      child: SizedBox(
        width: _kSingleColumnWidth,
        child: Column(children: children),
      ),
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _repositionLowerDeckMarkers());
    return Stack(
      key: _gridKey,
      children: [
        grid,
        if (_lowerDeckMarker14 != null)
          Positioned(
            left: _lowerDeckMarker14!.left,
            top: _lowerDeckMarker14!.top,
            child: IgnorePointer(
              child: Container(
                width: _lowerDeckMarker14!.width,
                height: _lowerDeckMarker14!.height,
                color: Colors.white,
              ),
            ),
          ),
        if (_lowerDeckMarkerDoor != null)
          Positioned(
            left: _lowerDeckMarkerDoor!.left,
            top: _lowerDeckMarkerDoor!.top,
            child: IgnorePointer(
              child: Container(
                width: _lowerDeckMarkerDoor!.width,
                height: _lowerDeckMarkerDoor!.height,
                color: Colors.white,
              ),
            ),
          ),
        if (_lowerDeckSplitRect != null)
          Positioned(
            left: _lowerDeckSplitRect!.left,
            top: _lowerDeckSplitRect!.top,
            child: IgnorePointer(
              child: Container(
                width: _lowerDeckSplitRect!.width,
                height: _lowerDeckSplitRect!.height,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
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
      key: _slotKeys[label] ??= GlobalKey(),
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
        onAcceptWithDetails: (details) {
          final c = details.data;
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
            child: container == null
                ? Text(label, style: const TextStyle(color: Colors.white70))
                : Stack(
                    children: [
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.6 * 255).toInt()),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: LongPressDraggable<model.StorageContainer>(
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
                    ],
                  ),
          ),
        );
      },
      ),
    );
  }

  int _columnCount(LoadingSequence sequence) {
    final count = sequence.order.length;
    if (count >= 18) return 2; // e.g. 767-200 config A or 767-300 config C
    if (count <= 10 || count == 12 || count == 13 || count == 17) return 1;
    return 0;
  }

  String _slotLabel(WidgetRef ref, LoadingSequence sequence, int index) {
    final aircraft = ref.watch(aircraftProvider);
    if (aircraft?.typeCode == 'B763') {
      switch (sequence.label) {
        case 'A':
          return 'A${index + 1}';
        case 'B':
          return 'B${index + 3}';
        case 'C':
          if (index == 0) return '1';
          if (index == sequence.order.length - 1) return 'A13';
          final adj = index - 1;
          final row = adj ~/ 2 + 2;
          final side = adj % 2 == 0 ? 'L' : 'R';
          return '$row$side';
      }
    }

    if (aircraft?.typeCode == 'B762' && sequence.label == 'E') {
      return '${index + 1}';
    }

    if (sequence.order.length >= 21 && index == 20) return 'A11';
    if (sequence.order.length >= 21 && index == 18) return '10L';
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
    final aircraft = ref.watch(aircraftProvider);
    final slotKey = GlobalKey();
    if (aircraft?.typeCode == 'B763' || aircraft?.typeCode == 'B762') {
      _slotKeys[label] = slotKey;
    }

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
        onAcceptWithDetails: (details) {
          final c = details.data;
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
              key: slotKey,
              width: 100,
              height: 100,
              alignment: Alignment.center,
              child: container == null
                  ? Text(label, style: const TextStyle(color: Colors.white70))
                  : Stack(
                      children: [
                        Positioned(
                          top: 2,
                          left: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha((0.6 * 255).toInt()),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: LongPressDraggable<model.StorageContainer>(
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
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}