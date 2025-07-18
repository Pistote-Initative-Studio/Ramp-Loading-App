import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../providers/transfer_bin_provider.dart';

Future<void> showTransferMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset position,
  required void Function(StorageContainer) onSelected,
}) async {
  final queue = ref.read(transferBinProvider).ulds;
  if (queue.isEmpty) return;
  final selected = await showMenu<StorageContainer>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      for (final c in queue)
        PopupMenuItem<StorageContainer>(
          value: c,
          child: Text(c.uld),
        ),
    ],
  );
  if (selected != null) {
    ref.read(transferBinProvider).removeULD(selected);
    onSelected(selected);
  }
}
