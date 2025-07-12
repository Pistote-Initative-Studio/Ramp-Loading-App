import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../providers/transfer_queue_provider.dart';

class TransferArea extends ConsumerWidget {
  const TransferArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(transferQueueProvider);
    return DragTarget<StorageContainer>(
      onAccept: (c) {
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
