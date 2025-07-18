import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../managers/transfer_bin_manager.dart';

final storageProvider =
    StateNotifierProvider<StorageNotifier, List<StorageContainer?>>((ref) {
      return StorageNotifier();
    });

class StorageNotifier extends StateNotifier<List<StorageContainer?>> {
  static const _pageId = 'storage';
  final TransferBinManager _manager = TransferBinManager.instance;

  StorageNotifier() : super(TransferBinManager.instance.getSlots(_pageId)) {
    _manager.addListener(_update);
  }

  void _update() {
    state = _manager.getSlots(_pageId);
  }

  @override
  void dispose() {
    _manager.removeListener(_update);
    super.dispose();
  }

  void setSize(int count) {
    _manager.validateSlots(_pageId, count);
    _manager.setSlotCount(_pageId, count);
    state = _manager.getSlots(_pageId);
  }

  void placeContainer(int idx, StorageContainer container) {
    _manager.placeULDInSlot(_pageId, idx, container);
    state = _manager.getSlots(_pageId);
  }

  void addUld(StorageContainer container) {
    final slots = _manager.getSlots(_pageId);
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        placeContainer(i, container);
        return;
      }
    }
    placeContainer(slots.length, container);
  }

  void removeContainer(StorageContainer container) {
    _manager.removeULDFromSlots(container);
    state = _manager.getSlots(_pageId);
  }
}
