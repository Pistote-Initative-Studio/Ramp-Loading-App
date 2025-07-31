import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../providers/transfer_bin_provider.dart';
import '../utils/uld_mover.dart';

class TransferArea extends ConsumerWidget {
  const TransferArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(transferBinProvider);
    final queue = manager.ulds;
    return DragTarget<StorageContainer>(
      onAcceptWithDetails: (details) {
        final c = details.data;
        // Remove the ULD from wherever it currently resides
        removeFromAll(ref, c);

        // Finally add it to the transfer queue
        ref.read(transferBinProvider).addULD(c);
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
