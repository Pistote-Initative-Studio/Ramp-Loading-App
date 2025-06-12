import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dotted_border/dotted_border.dart';
import '../models/train.dart';
import '../models/container.dart' as model;
import '../providers/train_provider.dart';
import '../widgets/uld_chip.dart';

class TrainPage extends ConsumerWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trains = ref.watch(trainProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trains'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                trains.map((train) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      children: [
                        _buildTug(train),
                        const SizedBox(height: 24),
                        _buildDollyStack(ref, train),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTug(Train train) {
    return Container(
      width: 100,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        train.label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDollyStack(WidgetRef ref, Train train) {
    return SizedBox(
      width: 100,
      height: 400,
      child: ListView.builder(
        itemCount: train.dollys.length,
        itemBuilder: (context, index) {
          final dolly = train.dollys[index];
          final uld = dolly.load;
          return DragTarget<model.StorageContainer>(
            onAccept: (c) {
              ref
                  .read(trainProvider.notifier)
                  .assignUldToDolly(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
