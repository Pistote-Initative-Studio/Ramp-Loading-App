import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aircraft_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/train_provider.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/storage_provider.dart';
import '../models/aircraft.dart';
import '../models/train.dart';
import '../models/container.dart' as model;
import '../models/uld_type.dart';

class _TrainDraft {
  String id;
  TextEditingController labelController;
  int dollyCount;

  _TrainDraft({
    required this.id,
    required String label,
    required this.dollyCount,
  }) : labelController = TextEditingController(text: label);
}

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _customUldController = TextEditingController();
  int ballDeckCount = 7;
  int storageCount = 20;

  //Train config drafts
  List<_TrainDraft> _trainDrafts = [];
  int _trainCount = 0;

  Aircraft? _dropdownAircraft;
  LoadingSequence? _dropdownConfig;

  final List<String> uldOptions = ['AAX', 'LAY', 'DQF', 'AKE', 'Cookie Sheet'];

  final List<Aircraft> aircraftList = [
    Aircraft('B762', 'Boeing 767-200 Freighter', [], [
      LoadingSequence('A', 'A', List.generate(19, (i) => i)),
      LoadingSequence('B', 'B', List.generate(21, (i) => i)),
      LoadingSequence('C', 'C', List.generate(10, (i) => i)),
      LoadingSequence('D', 'D', List.generate(13, (i) => i)),
      LoadingSequence('E', 'E', List.generate(12, (i) => i)),
    ]),
    Aircraft('B763', 'Boeing 767-300 Freighter', [], []),
    Aircraft('B752', 'Boeing 757-200 Freighter', [], []),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedAircraft = ref.read(aircraftProvider);
      if (savedAircraft != null) {
        setState(() {
          _dropdownAircraft = savedAircraft;
        });
      }
      // Sync the slider with the current ball deck slot count
      final deckSlots = ref.read(ballDeckProvider).slots.length;
      setState(() => ballDeckCount = deckSlots);

      final trains = ref.read(trainProvider);
      setState(() {
        _trainDrafts = trains 
        .map((t) => _TrainDraft(
          id: t.id,
          label: t.label,
          dollyCount: t.dollyCount,
        ))
      .tolist();
    _trainCount = _trainDrafts.length;
      });
    });
  }

  @override
  void dispose() {
    _customUldController.dispose();
    for (final d in _trainDrafts) {
      d.labelController.dispose();
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
      builder:
          (context) => AlertDialog(
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
                    if (val != null) destination = val;
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
  }

  @override
  Widget build(BuildContext context) {
    final aircraftConfigs = _dropdownAircraft?.configs ?? [];
    final ballDeck = ref.watch(ballDeckProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Config')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '✈️ Select Aircraft',
            style: TextStyle(color: Colors.white),
          ),
          DropdownButton<Aircraft>(
            value: _dropdownAircraft,
            isExpanded: true,
            dropdownColor: Colors.black,
            items:
                aircraftList
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                    .toList(),
            onChanged: (value) {
              setState(() {
                _dropdownAircraft = value;
                _dropdownConfig = null;
              });
            },
          ),
          if (aircraftConfigs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  '📋 Select Configuration',
                  style: TextStyle(color: Colors.white),
                ),
                DropdownButton<LoadingSequence>(
                  value: _dropdownConfig,
                  isExpanded: true,
                  dropdownColor: Colors.black,
                  hint: const Text(
                    'Choose Configuration',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items:
                      aircraftConfigs
                          .map(
                            (cfg) => DropdownMenuItem(
                              value: cfg,
                              child: Text(
                                cfg.label,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (cfg) {
                    setState(() => _dropdownConfig = cfg);
                  },
                ),
              ],
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed:
                (_dropdownAircraft != null && _dropdownConfig != null)
                    ? () {
                      ref.read(aircraftProvider.notifier).state =
                          _dropdownAircraft;
                      ref
                          .read(planeProvider.notifier)
                          .selectSequence(_dropdownConfig!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_dropdownAircraft!.name} with config ${_dropdownConfig!.label} selected',
                          ),
                        ),
                      );
                    }
                    : null,
            child: const Text('Select'),
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
            '🚛 Tugs',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Slider(
            value: _trainCount.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_trainCount',
            onChanged: (v) {
              final newCount = v.toInt();
              setState(() {
                if (newCount > _trainDrafts.length) {
                  for (int i = _trainDrafts.length; i < newCount; i++) {
                    _trainDrafts.add(_TrainDraft(
                      id: UniqueKey().toString(),
                      label: 'Tug ${i = 1}',
                      dollyCount: 0,
                    ));
                  }
                } else if (newCount < _trainDrafts.length) {
                  for (int i = newCount; i < _trainDrafts.length; i++) {
                    _trainDrafts[i].labelController.dispose();
                  }
                  _trainDrafts = _trainDrafts.sublist(0, newCount);
                }
                _trainCount = newCount;
              });
            },
          ),
          Column(
            children: List.generate(_trainDrafts.length, (i)) {
              final draft = _trainDrafts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  chrildren; [
                    textField(
                      controller: draft.labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tug ${i + 1} Label',
                        labelStyle: const TextStyle(color: Colors.white54),
                      ),
                    )
                    Slider(
                      value:dollyCount.toDouble(),
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: '${draft.dollyCount}',
                      onChanged: (v) => setState(() {
                        draft.dollyCount = v.toInt();
                      }),
                    ),
                  ],
                ),
              );
            }),
          ),
          ElevatedButton(
            onPressed:() {
              final newTrains = _trainsDrafts
                .map((d) => Train.withAutoDolly(
                  id: d.id,
                  label: d.labelController.text,
                  dollyCount: d.dollyCount,
                  colorIndex: 0,
                ))
            .toList();
        ref.read(trainProvider.notifier).setTrains(newTrains);
        ScoffoldMessenger.of(ontext).showSnackBar(
          const SnackBar(content: Text('Tug Configuration Updated'))
        );
      },
      child: const Text('Apply'),
    ),
          const SizedBox(height: 32),
          const Text(
            '🛒 Dolly Setup — coming soon',
            style: TextStyle(color: Colors.white),
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
