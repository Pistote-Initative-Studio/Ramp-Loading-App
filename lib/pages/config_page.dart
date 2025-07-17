import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/planes_provider.dart';
import '../models/plane.dart';
import 'plane_page.dart' show lowerDeckviewProvider;
import '../providers/tug_provider.dart';
import '../providers/train_provider.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/storage_provider.dart';
import '../models/aircraft.dart';
import '../models/tug.dart';
import '../models/container.dart' as model;
import '../models/uld_type.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/color_palette.dart';

class TugDraft {
  String id;
  TextEditingController labelController;
  int colorIndex;

  TugDraft({required this.id, required String label, required this.colorIndex})
    : labelController = TextEditingController(text: label);
}


class _PlaneDraft {
  String id;
  TextEditingController nameController;
  Aircraft? aircraft;
  LoadingSequence? config;

  _PlaneDraft({
    required this.id,
    required String name,
    this.aircraft,
    this.config,
  }) : nameController = TextEditingController(text: name);
}

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _customUldController = TextEditingController();
  int ballDeckCount = 6;
  int storageCount = 20;

  //Tug config drafts
  List<TugDraft> tugDrafts = [];
  int tugCount = 0;

  // Plane config drafts
  List<_PlaneDraft> _planeDrafts = [];
  int _planeCount = 0;
  List<_PlaneDraft> planeDrafts = [];

  final List<String> uldOptions = ['AAX', 'LAY', 'DQF', 'AKE', 'Cookie Sheet'];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync the slider with the current ball deck slot count
      final deckSlots = ref.read(ballDeckProvider).slots.length;
      setState(() => ballDeckCount = deckSlots);

      final tugs = ref.read(tugProvider);
      final planes = ref.read(planesProvider);
      setState(() {
        tugDrafts =
            tugs
                .map(
                  (t) => TugDraft(
                    id: t.id,
                    label: t.label,
                    colorIndex: t.colorIndex,
                  ),
                )
                .toList();
        tugCount = tugDrafts.length;
        if (tugDrafts.isEmpty) {
          tugDrafts.add(
            TugDraft(id: UniqueKey().toString(), label: 'Tug 1', colorIndex: 0),
          );
          tugCount = 1;
        }

        _planeDrafts =
            planes.map((p) {
              final ac = aircraftList.firstWhere(
                (a) => a.typeCode == p.aircraftTypeCode,
                orElse: () => aircraftList.first,
              );
              LoadingSequence? cfg;
              try {
                cfg = ac.configs.firstWhere(
                  (c) => c.label == (p.inboundSequenceLabel ?? ''),
                );
              } catch (_) {}
              return _PlaneDraft(
                id: p.id,
                name: p.name,
                aircraft: ac,
                config: cfg,
              );
            }).toList();
        planeDrafts = _planeDrafts;
        _planeCount = planeDrafts.length;
        if (_planeDrafts.isEmpty) {
          _planeDrafts.add(
            _PlaneDraft(id: UniqueKey().toString(), name: 'Plane 1'),
          );
          _planeCount = 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _customUldController.dispose();
    for (final d in tugDrafts) {
      d.labelController.dispose();
    }
    for (final p in _planeDrafts) {
      p.nameController.dispose();
    }
    super.dispose();
  }

  void _addCustomUld() {
    final type = _customUldController.text.trim();
    if (type.isEmpty) return;
    _promptForUldDetails(type);
    _customUldController.clear();
  }

  void _promptForUldDetails(String type) {
    String name = '';
    String destination = 'Ball Deck';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Add $type ULD',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'ULD Name',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: destination,
                  dropdownColor: Colors.black,
                  items:
                      ['Ball Deck', 'Train', 'Plane', 'Storage']
                          .map(
                            (dest) => DropdownMenuItem(
                              value: dest,
                              child: Text(
                                dest,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => destination = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final container = model.StorageContainer(
                    id: UniqueKey().toString(),
                    uld: name,
                    // Newly created ULDs may not correspond to a predefined
                    // SizeEnum value. Treat the type as custom and rely on the
                    // `size` field for any sizing logic instead of converting
                    // the label into a SizeEnum.
                    type: SizeEnum.Custom,
                    size: SizeEnum.PAG_88x125,
                    weightKg: 0,
                    hasDangerousGoods: false,
                    colorIndex: 0,
                  );
                  switch (destination) {
                    case 'Ball Deck':
                      ref.read(ballDeckProvider.notifier).addUld(container);
                      break;
                    case 'Train':
                      final outbound = ref.read(isTrainOutboundProvider);
                      ref
                          .read(trainProvider.notifier)
                          .addToFirstAvailable(
                            container,
                            outbound: outbound,
                          );
                      break;
                    case 'Plane':
                      final outbound = ref.read(isOutboundProvider);
                      final lower = ref.read(lowerDeckviewProvider);
                      ref.read(planeProvider.notifier).addToFirstAvailable(
                            container,
                            outbound: outbound,
                            lowerDeck: lower,
                          );
                      final pid = ref.read(selectedPlaneIdProvider);
                      if (pid != null) {
                        final planes = ref.read(planesProvider);
                        try {
                          final plane = planes.firstWhere((p) => p.id == pid);
                          final updated = ref
                              .read(planeProvider.notifier)
                              .exportPlane(plane);
                          ref.read(planesProvider.notifier).updatePlane(updated);
                        } catch (_) {}
                      }
                      break;
                    case 'Storage':
                      ref.read(storageProvider.notifier).addUld(container);
                      break;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name ($type) added to $destination'),
                    ),
                  );
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }


  void _commitTugs() {
    final newTugs =
        tugDrafts
            .map(
              (d) => Tug(
                id: d.id,
                label: d.labelController.text,
                colorIndex: d.colorIndex,
              ),
            )
            .toList();
    ref.read(tugProvider.notifier).setTugs(newTugs);
  }

  void _applyPlane(int index) {
    final draft = _planeDrafts[index];
    final ac = draft.aircraft;
    LoadingSequence? cfg = draft.config;
    if (ac == null) return;
    cfg = cfg ?? (ac.configs.isNotEmpty ? ac.configs.first : null);
    if (cfg == null) return;
    final plane = Plane(
      id: draft.id,
      name: draft.nameController.text,
      aircraftTypeCode: ac.typeCode,
      inboundSequenceLabel: cfg.label,
      inboundSequenceOrder: cfg.order,
      inboundSlots: List.filled(cfg.order.length, null),
      outboundSequenceLabel: cfg.label,
      outboundSequenceOrder: cfg.order,
      outboundSlots: List.filled(cfg.order.length, null),
      lowerInboundSlots: List.filled(15, null),
      lowerOutboundSlots: List.filled(15, null),
    );
    final existing = ref.read(planesProvider).any((p) => p.id == plane.id);
    if (existing) {
      ref.read(planesProvider.notifier).updatePlane(plane);
    } else {
      ref.read(planesProvider.notifier).addPlane(plane);
    }
    ref.read(aircraftProvider.notifier).state = ac;
    ref.read(planeProvider.notifier).loadPlane(plane, ac.configs);
    ref.read(selectedPlaneIdProvider.notifier).state = plane.id;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${plane.name} applied')));
  }

  void _deletePlane(int index) {
    final draft = _planeDrafts[index];
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Are you sure you want to remove this plane?',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(planesProvider.notifier).removePlane(draft.id);
                  setState(() {
                    _planeDrafts.removeAt(index);
                    planeDrafts = _planeDrafts;
                    _planeCount = _planeDrafts.length;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  void _addPlane() {
    setState(() {
      if (_planeDrafts.length < 15) {
        _planeDrafts.add(
          _PlaneDraft(
            id: UniqueKey().toString(),
            name: 'Plane ${_planeDrafts.length + 1}',
          ),
        );
        planeDrafts = _planeDrafts;
        _planeCount = _planeDrafts.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ballDeck = ref.watch(ballDeckProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Config')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Planes',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Column(
            children: List.generate(_planeDrafts.length, (i) {
              final draft = _planeDrafts[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: draft.nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Plane Identifier',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _deletePlane(i),
                        ),
                        ElevatedButton(
                          onPressed:
                              draft.aircraft != null
                                  ? () => _applyPlane(i)
                                  : null,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    DropdownButton<Aircraft>(
                      value: draft.aircraft,
                      isExpanded: true,
                      dropdownColor: Colors.black,
                      hint: const Text(
                        'Select Aircraft',
                        style: TextStyle(color: Colors.white70),
                      ),
                      items:
                          aircraftList
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          draft.aircraft = value;
                          draft.config =
                              null; // Reset config when aircraft changes
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
          ),
          if (_planeDrafts.length < 15)
            ElevatedButton(
              onPressed: _addPlane,
              child: const Text('Add Plane'),
            ),
          const SizedBox(height: 24),
          const Text(
            '🟦 Ball Deck Slots',
            style: TextStyle(color: Colors.white),
          ),
          Slider(
            value: ballDeckCount.toDouble(),
            min: 1,
            max: 25,
            divisions: 24,
            label: '$ballDeckCount',
            onChanged: (value) => setState(() => ballDeckCount = value.toInt()),
          ),
          ElevatedButton(
            onPressed:
                (ballDeckCount != ballDeck.slots.length)
                    ? () {
                      ref
                          .read(ballDeckProvider.notifier)
                          .setSlotCount(ballDeckCount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ball Deck slot count updated'),
                        ),
                      );
                    }
                    : null,
            child: const Text('Apply'),
          ),
          const SizedBox(height: 24),
          const Text('📦 ULD Types', style: TextStyle(color: Colors.white)),
          Wrap(
            spacing: 12,
            children:
                uldOptions.map((type) {
                  return ElevatedButton(
                    onPressed: () => _promptForUldDetails(type),
                    child: Text(type),
                  );
                }).toList(),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customUldController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Other',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              IconButton(
                onPressed: _addCustomUld,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '🚛 Tugs Configuration',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Slider(
            value: tugCount.toDouble(),
            min: 0,
            max: 25,
            divisions: 25,
            label: '$tugCount',
            onChanged: (v) {
              final newCount = v.toInt();
              setState(() {
                if (newCount > tugDrafts.length) {
                  for (int i = tugDrafts.length; i < newCount; i++) {
                    tugDrafts.add(
                      TugDraft(
                        id: UniqueKey().toString(),
                        label: 'Tug ${i + 1}',
                        colorIndex: 0,
                      ),
                    );
                  }
                } else if (newCount < tugDrafts.length) {
                  for (int i = newCount; i < tugDrafts.length; i++) {
                    tugDrafts[i].labelController.dispose();
                  }
                  tugDrafts = tugDrafts.sublist(0, newCount);
                }
                tugCount = newCount;
              });
            },
          ),
          Column(
            children: List.generate(tugDrafts.length, (i) {
              final draft = tugDrafts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: draft.labelController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Tug ${i + 1} Label',
                          labelStyle: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => ColorPickerDialog(
                                onColorPicked: (c) {
                                  setState(() {
                                    draft.colorIndex = rampColors
                                        .indexOf(c)
                                        .clamp(0, rampColors.length - 1);
                                  });
                                },
                              ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor:
                            rampColors[draft.colorIndex % rampColors.length],
                        radius: 20,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          ElevatedButton(
            onPressed: () {
              _commitTugs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tug configuration updated')),
              );
            },
            child: const Text('Apply'),
          ),
          const SizedBox(height: 32),
          const Text('🏬 Storage Slots', style: TextStyle(color: Colors.white)),
          Slider(
            value: storageCount.toDouble(),
            min: 0,
            max: 50,
            divisions: 50,
            label: '$storageCount',
            onChanged: (value) => setState(() => storageCount = value.toInt()),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(storageProvider.notifier).setSize(storageCount);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage slot count updated')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
