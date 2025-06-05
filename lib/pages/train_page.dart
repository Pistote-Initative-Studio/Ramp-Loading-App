import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/train.dart';
import '../providers/train_provider.dart';

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
                        _buildDollyStack(train),
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
    final color = _safeColor(train.colorIndex);

    return Draggable<Train>(
      data: train,
      feedback: Opacity(opacity: 0.7, child: _tugWidget(train, color)),
      childWhenDragging: Opacity(opacity: 0.2, child: _tugWidget(train, color)),
      child: _tugWidget(train, color),
    );
  }

  Widget _tugWidget(Train train, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 80,
          child: Stack(
            children: [
              Positioned(
                left: 15,
                top: 20,
                child: Container(width: 30, height: 40, color: color),
              ),
              Positioned(
                left: 20,
                top: 0,
                child: Container(width: 20, height: 20, color: color),
              ),
              Positioned(left: 5, top: 5, child: _tire(color)),
              Positioned(right: 5, top: 5, child: _tire(color)),
              Positioned(left: 5, bottom: 5, child: _tire(color)),
              Positioned(right: 5, bottom: 5, child: _tire(color)),
            ],
          ),
        ),
        Positioned(
          bottom: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              train.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tire(Color color) => Container(width: 10, height: 10, color: color);

  Widget _buildDollyStack(Train train) {
    return SizedBox(
      width: 60,
      height: 400,
      child: ListView.builder(
        itemCount: train.dollys.length,
        itemBuilder: (context, index) {
          return DragTarget<Train>(
            onAccept: (tug) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tug ${tug.label} dropped on dolly ${index + 1}',
                  ),
                ),
              );
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        candidateData.isNotEmpty ? Colors.yellow : Colors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _safeColor(int index) {
    final colors = Colors.primaries.where((c) => c != Colors.black).toList();
    return colors[index % colors.length];
  }
}
