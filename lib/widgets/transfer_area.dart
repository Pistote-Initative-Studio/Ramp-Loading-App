import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../providers/transfer_queue_provider.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/train_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/lower_deck_provider.dart';

class TransferArea extends ConsumerWidget {
  const TransferArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(transferQueueProvider);
    return DragTarget<StorageContainer>(
      onAccept: (c) {
        // Remove the ULD from wherever it currently resides
        ref.read(ballDeckProvider.notifier).removeContainer(c);
        ref.read(storageProvider.notifier).removeContainer(c);
        ref.read(trainProvider.notifier).removeContainer(c);
        ref.read(planeProvider.notifier).removeContainer(c, outbound: true);
        ref.read(planeProvider.notifier).removeContainer(c, outbound: false);
        ref
            .read(planeProvider.notifier)
            .removeLowerDeckContainer(c, outbound: true);
        ref
            .read(planeProvider.notifier)
            .removeLowerDeckContainer(c, outbound: false);
        ref.read(lowerDeckProvider.notifier).removeContainer(c, outbound: true);
        ref.read(lowerDeckProvider.notifier).removeContainer(c, outbound: false);

        // Finally add it to the transfer queue
        ref.read(transferQueueProvider.notifier).add(c);
      },
      builder: (context, cand, rej) {
        final isActive = cand.isNotEmpty;
        return Container(
          height: 48,
          color: Colors.grey[850],
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, color: isActive ? Colors.yellow : Colors.white),
              const SizedBox(width: 8),
              Text(
                'Transfer (${queue.length})',
                style: TextStyle(
                  color: isActive ? Colors.yellow : Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
