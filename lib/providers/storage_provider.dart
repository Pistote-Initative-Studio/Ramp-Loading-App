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
  static const _slotCountKey = 'storageSlotCount';
  final TransferBinManager _manager = TransferBinManager.instance;
  late final Box _box;

  StorageNotifier() : super([]) {
    _initializeBox();
  }

  void _initializeBox() async {
    if (!Hive.isBoxOpen('storageBox')) {
      await Hive.openBox('storageBox');
    }
    _box = Hive.box('storageBox');
    
    // Load the persisted slot count
    final savedSlotCount = _box.get(_slotCountKey, defaultValue: 0) as int;
    
    // Initialize the manager with the saved slot count
    if (savedSlotCount > 0) {
      _manager.setSlotCount(_pageId, savedSlotCount);
    }
    
    // Set initial state
    state = _manager.getSlots(_pageId);
    
    // Listen for changes
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
    // Save the slot count to persistence
    _box.put(_slotCountKey, count);
    
    // Validate slots first - this moves excess ULDs to transfer bin
    _manager.validateSlots(_pageId, count);

    // Update the state to reflect the new slots
    state = _manager.getSlots(_pageId);

    // Keep placement tracking in sync
    ULDPlacementManager().updateSlotCount('Storage', count);
  }

  int getCurrentSlotCount() {
    return _box.get(_slotCountKey, defaultValue: 0) as int;
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