import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/container.dart';
import '../managers/transfer_bin_manager.dart';
import '../managers/uld_placement_manager.dart';

final storageProvider =
    StateNotifierProvider<StorageNotifier, List<StorageContainer?>>((ref) {
      return StorageNotifier();
    });

class StorageNotifier extends StateNotifier<List<StorageContainer?>> {
  static const _pageId = 'storage';
  static const _slotCountKey = 'slotCount';
  final TransferBinManager _manager = TransferBinManager.instance;
  late final Box _box;
  late final ValueListenable _listenable;

  StorageNotifier() : super([]) {
    _initializeBox();
  }

  void _initializeBox() {
    try {
      _box = Hive.box('storage_config');

      final savedSlotCount =
          _box.get(_slotCountKey, defaultValue: 0) as int? ?? 0;
      if (savedSlotCount > 0) {
        _manager.setSlotCount(_pageId, savedSlotCount);
      }
      state = _manager.getSlots(_pageId);

      _manager.addListener(_update);

      _listenable = _box.listenable(keys: [_slotCountKey]);
      _listenable.addListener(_onSlotCountChanged);
    } catch (e) {
      print('Error initializing storage box: $e');
      state = [];
    }
  }

  void _update() {
    state = _manager.getSlots(_pageId);
  }

  void _onSlotCountChanged() {
    final count = _box.get(_slotCountKey, defaultValue: 0) as int? ?? 0;
    _manager.setSlotCount(_pageId, count);
    state = _manager.getSlots(_pageId);
  }

  @override
  void dispose() {
    _manager.removeListener(_update);
    _listenable.removeListener(_onSlotCountChanged);
    super.dispose();
  }

  void setSize(int count) {
    _box.put(_slotCountKey, count);
    debugPrint('Storage slotCount set to $count');

    _manager.validateSlots(_pageId, count);
    state = _manager.getSlots(_pageId);
    ULDPlacementManager().updateSlotCount('Storage', count);
  }

  int getCurrentSlotCount() {
    return _box.get(_slotCountKey, defaultValue: 0) as int? ?? 0;
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