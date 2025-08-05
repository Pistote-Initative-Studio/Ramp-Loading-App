import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/aircraft.dart';
import '../models/container.dart' as model;
import '../models/train.dart';
import '../models/tug.dart';
import '../models/plane.dart';
import '../providers/aircraft_provider.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/planes_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/train_provider.dart';
import '../providers/tug_provider.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/color_palette.dart';
import '../managers/transfer_bin_manager.dart';

/// Draft object used to edit train/tug configuration in the UI.
class _TrainDraft {
  final String id;
  final TextEditingController labelController;
  int colorIndex;
  int dollyCount;

  _TrainDraft({
    required this.id,
    required String label,
    required this.colorIndex,
    required this.dollyCount,
  }) : labelController = TextEditingController(text: label);
}

/// Draft object used to configure planes.
class _PlaneDraft {
  final String id;
  final TextEditingController nameController;
  Aircraft? aircraft;
  LoadingSequence? config;

  _PlaneDraft({
    required this.id,
    required String name,
    this.aircraft,
    this.config,
  }) : nameController = TextEditingController(text: name);
}

/// Configuration page that exposes widgets for editing planes, trains,
/// storage slots and allowed ULD types. The interactive widgets were removed
/// during a previous refactor and are restored here while keeping the more
/// recent provider based state management and Hive persistence.
class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _customUldController = TextEditingController();

  /// Allowed ULD type codes that can be created.
  List<String> _allowedUlds = [];

  /// Drafts for trains/tugs.
  List<_TrainDraft> _trainDrafts = [];

  /// Drafts for planes.
  List<_PlaneDraft> _planeDrafts = [];

  /// Current ball deck slot count.
  int _ballDeckCount = 0;

  /// Current storage slot count.
  int _storageCount = 0;

  /// List of available aircraft to choose from when configuring planes.
  final List<Aircraft> _aircraftList = [
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

  late Future<void> _initFuture;

  /// Ensure all Hive boxes used on this page are opened before the widgets
  /// try to read from them.
  Future<void> _ensureBoxesOpen() async {
    final boxes = [
      'configBox',
      'planeBox',
      'planesBox',
      'trainBox',
      'tugBox',
      'tugsBox',
      'uldBox',
      'ballDeckBox',
      'transferBox',
    ];
    for (final b in boxes) {
      if (!Hive.isBoxOpen(b)) {
        await Hive.openBox(b);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    await _ensureBoxesOpen();

    if (Hive.isBoxOpen('configBox')) {
      final box = Hive.box('configBox');
      final storedTypes = box.get('allowedUlds');
      if (storedTypes is List) {
        _allowedUlds = List<String>.from(storedTypes);
      }
    }

    final trains = ref.read(trainProvider);
    final tugs = ref.read(tugProvider);
    final maxLen = trains.length > tugs.length ? trains.length : tugs.length;
    _trainDrafts = List.generate(maxLen, (i) {
      final train = i < trains.length ? trains[i] : null;
      final tug = i < tugs.length ? tugs[i] : null;
      return _TrainDraft(
        id: train?.id ?? tug?.id ?? UniqueKey().toString(),
        label: tug?.label ?? train?.label ?? 'Tug ${i + 1}',
        colorIndex: tug?.colorIndex ?? train?.colorIndex ?? 0,
        dollyCount: train?.dollyCount ?? 0,
      );
    });

    _ballDeckCount = ref.read(ballDeckProvider).slots.length;
    _storageCount = ref.read(storageProvider).length;

    final planes = ref.read(planesProvider);
    _planeDrafts = planes.map((p) {
      final ac = _aircraftList.firstWhere(
        (a) => a.typeCode == p.aircraftTypeCode,
        orElse: () => _aircraftList.first,
      );
      LoadingSequence? cfg;
      try {
        cfg = ac.configs.firstWhere((c) => c.label == p.inboundSequenceLabel);
      } catch (_) {}
      return _PlaneDraft(id: p.id, name: p.name, aircraft: ac, config: cfg);
    }).toList();

    setState(() {});
  }

  @override
  void dispose() {
    _customUldController.dispose();
    for (final d in _trainDrafts) {
      d.labelController.dispose();
    }
    for (final p in _planeDrafts) {
      p.nameController.dispose();
    }
    super.dispose();
  }

  /// Persist the current list of allowed ULD types.
  void _saveAllowedUlds() {
    if (Hive.isBoxOpen('configBox')) {
      Hive.box('configBox').put('allowedUlds', _allowedUlds);
    }
  }

  void _addCustomUld() {
    final type = _customUldController.text.trim();
    if (type.isEmpty) return;
    if (!_allowedUlds.contains(type)) {
      setState(() => _allowedUlds.add(type));
      _saveAllowedUlds();
    }
    _customUldController.clear();
    _promptForUldDetails(type);
  }

  /// Prompt the user for a ULD name and destination page then create it.
  void _promptForUldDetails(String type) {
    String name = '';
    String destination = 'Ball Deck';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Add $type ULD', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ULD Name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: destination,
                dropdownColor: Colors.black,
                items: ['Ball Deck', 'Train', 'Plane', 'Storage']
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) destination = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final container = model.StorageContainer(
                  id: UniqueKey().toString(),
                  uld: name,
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
                  case 'Storage':
                    ref.read(storageProvider.notifier).addUld(container);
                    break;
                  case 'Train':
                    _addUldToTrain(container);
                    break;
                  case 'Plane':
                    ref
                        .read(planeProvider.notifier)
                        .addToFirstAvailable(container, outbound: false, lowerDeck: false);
                    break;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name ($type) added to $destination')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addUldToTrain(model.StorageContainer container) {
    final trains = ref.read(trainProvider);
    for (final t in trains) {
      for (int i = 0; i < t.dollys.length; i++) {
        if (t.dollys[i].load == null) {
          ref
              .read(trainProvider.notifier)
              .assignUldToDolly(trainId: t.id, dollyIdx: i, container: container);
          TransferBinManager.instance
              .placeULDInSlot('train_${t.id}', i, container);
          return;
        }
      }
    }
    // If no slots available, send to transfer bin for later placement.
    TransferBinManager.instance.addULD(container);
  }

  void _applyTrain(int index) {
    final draft = _trainDrafts[index];
    final trains = ref.read(trainProvider);
    Train? existing;
    try {
      existing = trains.firstWhere((t) => t.id == draft.id);
    } catch (_) {}

    final dollys = List<Dolly>.generate(draft.dollyCount, (i) {
      model.StorageContainer? load;
      if (existing != null && i < existing.dollys.length) {
        load = existing.dollys[i].load;
      }
      return Dolly(i + 1, load: load);
    });

    if (existing != null && draft.dollyCount < existing.dollys.length) {
      TransferBinManager.instance
          .validateSlots('train_${draft.id}', draft.dollyCount);
    }
    TransferBinManager.instance
        .setSlotCount('train_${draft.id}', draft.dollyCount);

    final train = Train(
      id: draft.id,
      label: draft.labelController.text,
      dollyCount: draft.dollyCount,
      dollys: dollys,
      colorIndex: draft.colorIndex,
    );

    final trainNotifier = ref.read(trainProvider.notifier);
    if (existing == null) {
      trainNotifier.addTrain(train);
    } else {
      trainNotifier.updateTrain(train);
    }

    final tug = Tug(
      id: draft.id,
      label: draft.labelController.text,
      colorIndex: draft.colorIndex,
    );
    final tugs = ref.read(tugProvider);
    final tugNotifier = ref.read(tugProvider.notifier);
    if (tugs.any((t) => t.id == tug.id)) {
      tugNotifier.updateTug(tug);
    } else {
      tugNotifier.addTug(tug);
    }
  }

  void _deleteTrain(int index) {
    final draft = _trainDrafts[index];
    ref.read(trainProvider.notifier).removeTrain(draft.id);
    ref.read(tugProvider.notifier).removeTug(draft.id);
    TransferBinManager.instance.validateSlots('train_${draft.id}', 0);
    setState(() => _trainDrafts.removeAt(index));
  }

  void _addTrain() {
    setState(() {
      _trainDrafts.add(
        _TrainDraft(
          id: UniqueKey().toString(),
          label: 'Tug ${_trainDrafts.length + 1}',
          colorIndex: 0,
          dollyCount: 0,
        ),
      );
    });
  }

  void _applyPlane(int index) {
    final draft = _planeDrafts[index];
    final ac = draft.aircraft;
    if (ac == null) return;

    final cfg = draft.config ??
        (ac.configs.isNotEmpty
            ? ac.configs.first
            : LoadingSequence('', '', []));

    final plane = Plane(
      id: draft.id,
      name: draft.nameController.text,
      aircraftTypeCode: ac.typeCode,
      inboundSequenceLabel: cfg.label,
      inboundSequenceOrder: cfg.order,
      inboundSlots: List<model.StorageContainer?>.filled(cfg.order.length, null),
      outboundSequenceLabel: cfg.label,
      outboundSequenceOrder: cfg.order,
      outboundSlots: List<model.StorageContainer?>.filled(cfg.order.length, null),
      lowerInboundSlots: const [],
      lowerOutboundSlots: const [],
    );

    final planesNotifier = ref.read(planesProvider.notifier);
    final existing = ref.read(planesProvider).any((p) => p.id == plane.id);
    if (existing) {
      planesNotifier.updatePlane(plane);
    } else {
      planesNotifier.addPlane(plane);
    }

    ref.read(aircraftProvider.notifier).state = ac;
    ref.read(planeProvider.notifier).loadPlane(plane, ac.configs);
    ref.read(selectedPlaneIdProvider.notifier).state = plane.id;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${plane.name} applied')));
  }

  void _deletePlane(int index) {
    final draft = _planeDrafts[index];
    ref.read(planesProvider.notifier).removePlane(draft.id);
    setState(() => _planeDrafts.removeAt(index));
  }

  void _addPlane() {
    setState(() {
      _planeDrafts.add(
        _PlaneDraft(
          id: UniqueKey().toString(),
          name: 'Plane ${_planeDrafts.length + 1}',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Config')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Plane Configuration'),
              _planeDrafts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No planes configured'),
                    )
                  : Column(
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
                                      decoration: const InputDecoration(
                                          labelText: 'Plane Name'),
                                    ),
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _deletePlane(i),
                                  ),
                                  ElevatedButton(
                                    onPressed: draft.aircraft != null
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
                                hint: const Text('Select Aircraft'),
                                items: _aircraftList
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
                                        value != null && value.configs.isNotEmpty
                                            ? value.configs.first
                                            : null;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
              ElevatedButton(
                onPressed: _addPlane,
                child: const Text('Add Plane'),
              ),
              const SizedBox(height: 24),
              const Text('ULD Type Configuration'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customUldController,
                      decoration: const InputDecoration(labelText: 'Add ULD Type'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addCustomUld,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Tug/Train Configuration'),
              const SizedBox(height: 8),
              _trainDrafts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No tugs configured'),
                    )
                  : Column(
                      children: List.generate(_trainDrafts.length, (i) {
                        final draft = _trainDrafts[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => ColorPickerDialog(
                                          onColorPicked: (c) {
                                            setState(() {
                                              draft.colorIndex =
                                                  rampColors.indexOf(c);
                                            });
                                          },
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: rampColors[
                                          draft.colorIndex %
                                              rampColors.length],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: draft.labelController,
                                      decoration: const InputDecoration(
                                          labelText: 'Tug Label'),
                                    ),
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _deleteTrain(i),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _applyTrain(i),
                                    child: const Text('Apply'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
              ElevatedButton(
                onPressed: _addTrain,
                child: const Text('Add Tug'),
              ),
              const SizedBox(height: 24),
              const Text('Ball Deck Configuration'),
              const Text('Number of Ball Deck Slots'),
              Slider(
                value: _ballDeckCount.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                label: '$_ballDeckCount',
                onChanged: (v) => setState(() => _ballDeckCount = v.toInt()),
              ),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(ballDeckProvider.notifier)
                      .setSlotCount(_ballDeckCount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ball deck slot count updated')),
                  );
                },
                child: const Text('Apply'),
              ),
              const SizedBox(height: 24),
              const Text('Storage Configuration'),
              Slider(
                value: _storageCount.toDouble(),
                min: 0,
                max: 50,
                divisions: 50,
                label: '$_storageCount',
                onChanged: (v) => setState(() => _storageCount = v.toInt()),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(storageProvider.notifier).setSize(_storageCount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage slot count updated')),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }
}

