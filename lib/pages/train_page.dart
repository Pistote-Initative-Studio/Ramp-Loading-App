import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/train.dart';
import '../models/tug.dart';
import '../models/container.dart' as model;
import '../providers/train_provider.dart';
import '../providers/tug_provider.dart';
import '../widgets/uld_chip.dart';
import '../widgets/color_palette.dart';
import '../widgets/transfer_menu.dart';
import '../widgets/transfer_area.dart';
import '../utils/uld_mover.dart';

class _TrainDraft {
  String id;
  int dollyCount;
  _TrainDraft({required this.id, required this.dollyCount});
}

class TrainPage extends ConsumerStatefulWidget {
  const TrainPage({super.key});

  @override
  ConsumerState<TrainPage> createState() => _TrainPageState();
}

class _TrainPageState extends ConsumerState<TrainPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<_TrainDraft> _drafts = [];
  int _trainCount = 0;

  Future<void> _showDollyDialog(int index) async {
    int count = _drafts[index].dollyCount.clamp(1, 10);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Dolly Count for Train ${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              content: DropdownButton<int>(
                value: count,
                dropdownColor: Colors.black,
                underline: const SizedBox.shrink(),
                items: List.generate(
                  10,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) {
                    setStateDialog(() => count = val);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _drafts[index].dollyCount = count);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final trains = ref.read(trainProvider);
    _drafts = trains
        .map((t) => _TrainDraft(id: t.id, dollyCount: t.dollyCount))
        .toList();
    if (_drafts.isEmpty) {
      _drafts.add(_TrainDraft(id: UniqueKey().toString(), dollyCount: 1));
    }
    _trainCount = _drafts.length;
    _tabController = TabController(length: _trainCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChanges() {
    final newTrains = _drafts.asMap().entries.map((e) {
      return Train.withAutoDolly(
        id: e.value.id,
        label: 'Train ${e.key + 1}',
        dollyCount: e.value.dollyCount,
        colorIndex: 0,
      );
    }).toList();
    ref.read(trainProvider.notifier).setTrains(newTrains);
  }

  @override
  Widget build(BuildContext context) {
    final trains = ref.watch(trainProvider);
    final tugs = ref.watch(tugProvider);

    const topBarHeight = 60.0;

    final media = MediaQuery.of(context);
    final availableHeight = media.size.height -
        media.padding.top -
        topBarHeight -
        kTextTabBarHeight -
        60;
    final listHeight = availableHeight - 72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: topBarHeight,
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('Trains', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _trainCount,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Colors.black,
                  items: List.generate(
                    15,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      if (val > _drafts.length) {
                        for (int i = _drafts.length; i < val; i++) {
                          _drafts.add(
                            _TrainDraft(
                              id: UniqueKey().toString(),
                              dollyCount: 1,
                            ),
                          );
                        }
                      } else if (val < _drafts.length) {
                        _drafts = _drafts.sublist(0, val);
                      }
                      _trainCount = val;
                      _tabController.dispose();
                      _tabController =
                          TabController(length: _trainCount, vsync: this);
                    });
                  },
                ),
                const SizedBox(width: 16),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyChanges,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      onTap: _showDollyDialog,
                      tabs: List.generate(
                        _drafts.length,
                        (i) => Tab(text: 'Train ${i + 1}'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(trains.length, (i) {
                          final tug = i < tugs.length ? tugs[i] : null;
                          final train = trains[i];
                          return Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Column(
                              children: [
                                _buildTug(tug),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 100,
                                  height: listHeight,
                                  child: _buildDollyStack(
                                    context,
                                    train,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60, child: TransferArea()),
        ],
      ),
    ),
  );
  }

  Widget _buildTug(Tug? tug) {
    if (tug == null) {
      return const SizedBox(width: 100, height: 60);
    }
    final color = rampColors[tug.colorIndex % rampColors.length];
    return Container(
      width: 100,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tug.label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDollyStack(BuildContext context, Train train) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: train.dollyCount,
      itemBuilder: (context, index) {
        final dolly = train.dollys[index];
        final uld = dolly.load;
        return GestureDetector(
          onLongPressStart: uld == null
              ? (details) => showTransferMenu(
                    context: context,
                    ref: ref,
                    position: details.globalPosition,
                    onSelected: (c) {
                      ref.read(trainProvider.notifier).assignUldToDolly(
                            trainId: train.id,
                            dollyIdx: index,
                            container: c,
                          );
                    },
                  )
              : null,
          child: DragTarget<model.StorageContainer>(
            onAccept: (c) {
              removeFromAll(ref, c);
              ref.read(trainProvider.notifier).assignUldToDolly(
                    trainId: train.id,
                    dollyIdx: index,
                    container: c,
                  );
            },
            builder: (context, candidateData, rejectedData) {
              final isActive = candidateData.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DottedBorder(
                  color: isActive ? Colors.yellow : Colors.white,
                  strokeWidth: 2,
                  dashPattern: uld == null ? const [4, 4] : const [1, 0],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(8),
                  child: Container(
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    child: uld == null
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
      },
    );
  }
}
