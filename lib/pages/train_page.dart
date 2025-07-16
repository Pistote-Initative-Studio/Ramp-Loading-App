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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_TrainDraft> _drafts = [];
  int _trainCount = 0;

  @override
  void initState() {
    super.initState();
    final trains = ref.read(trainProvider);
    _drafts =
        trains.map((t) => _TrainDraft(id: t.id, dollyCount: t.dollyCount)).toList();
    if (_drafts.isEmpty) {
      _drafts.add(_TrainDraft(id: UniqueKey().toString(), dollyCount: 0));
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
    final outbound = ref.watch(isTrainOutboundProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trains'),
        backgroundColor: Colors.grey[900],
        actions: [
          Row(
            children: [
              const Text('Inbound', style: TextStyle(color: Colors.white)),
              Switch(
                value: outbound,
                onChanged: (val) =>
                    ref.read(isTrainOutboundProvider.notifier).state = val,
              ),
              const Text('Outbound', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyChanges,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Text('Trains', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _trainCount,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Colors.black,
                  items: List.generate(
                    25,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      if (val > _drafts.length) {
                        for (int i = _drafts.length; i < val; i++) {
                          _drafts.add(
                              _TrainDraft(id: UniqueKey().toString(), dollyCount: 0));
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
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: List.generate(
              _drafts.length,
              (i) => Tab(text: 'Train ${i + 1}'),
            ),
          ),
          SizedBox(
            height: 60,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_drafts.length, (i) {
                final draft = _drafts[i];
                return Center(
                  child: Slider(
                    value: draft.dollyCount.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '${draft.dollyCount}',
                    onChanged: (v) =>
                        setState(() => draft.dollyCount = v.toInt()),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(trains.length, (i) {
                    final train = trains[i];
                    final Tug? tug = i < tugs.length ? tugs[i] : null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        children: [
                          _buildTug(tug),
                          const SizedBox(height: 24),
                          _buildDollyStack(context, train, outbound),
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

  Widget _buildDollyStack(BuildContext context, Train train, bool outbound) {
    return SizedBox(
      width: 100,
      height: 400,
      child: ListView.builder(
        itemCount: train.dollyCount,
        itemBuilder: (context, index) {
          final dolly =
              outbound ? train.outboundDollys[index] : train.inboundDollys[index];
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
                              outbound: outbound,
                            );
                      },
                    )
                : null,
            child: DragTarget<model.StorageContainer>(
              onAccept: (c) {
                removeFromAll(ref, c);
                ref
                    .read(trainProvider.notifier)
                    .assignUldToDolly(
                      trainId: train.id,
                      dollyIdx: index,
                      container: c,
                      outbound: outbound,
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
      ),
    );
  }
}
