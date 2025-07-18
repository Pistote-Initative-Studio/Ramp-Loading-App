import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/train_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/lower_deck_provider.dart';
import '../managers/transfer_bin_manager.dart';

/// Removes the given [container] from every page before placing it elsewhere.
void removeFromAll(WidgetRef ref, StorageContainer container) {
  // Let the manager clear from all registered slots
  TransferBinManager.instance.removeULDFromSlots(container);

  // Keep legacy providers in sync
  ref.read(ballDeckProvider.notifier).removeContainer(container);
  ref.read(storageProvider.notifier).removeContainer(container);
  ref.read(trainProvider.notifier).removeContainer(container);
  ref.read(planeProvider.notifier).removeContainer(container, outbound: true);
  ref.read(planeProvider.notifier).removeContainer(container, outbound: false);
  ref
      .read(lowerDeckProvider.notifier)
      .removeContainer(container, outbound: true);
  ref
      .read(lowerDeckProvider.notifier)
      .removeContainer(container, outbound: false);
}
