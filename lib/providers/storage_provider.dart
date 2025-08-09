import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/container.dart';

final storageProvider =
    StateNotifierProvider<StorageNotifier, List<StorageContainer?>>((ref) {
      return StorageNotifier();
    });

class StorageNotifier extends StateNotifier<List<StorageContainer?>> {
  static const _slotCountKey = 'storageSlotCount';
  Box? _box;

  StorageNotifier() : super([]) {
    _initializeBox();
  }

  void _initializeBox() {
    try {
      _box = Hive.box('storageBox');
      
      // Load the persisted slot count
      final savedSlotCount = _box!.get(_slotCountKey, defaultValue: 0) as int;
      print('Storage: Loading saved slot count: $savedSlotCount');
      
      // Create the initial state with the saved slot count
      if (savedSlotCount > 0) {
        state = List<StorageContainer?>.filled(savedSlotCount, null);
        print('Storage: Created ${state.length} slots');
      } else {
        state = [];
        print('Storage: No slots to create');
      }
    } catch (e) {
      print('Error initializing storage box: $e');
      state = [];
    }
  }

  void setSize(int count) {
    print('Storage: Setting size to $count');
    
    // Save the slot count to persistence
    _box?.put(_slotCountKey, count);
    
    // Create new slots list
    final newSlots = List<StorageContainer?>.filled(count, null);
    
    // Copy existing containers that fit
    for (int i = 0; i < count && i < state.length; i++) {
      newSlots[i] = state[i];
    }
    
    // Update state
    state = newSlots;
    
    print('Storage: New state has ${state.length} slots');
  }

  int getCurrentSlotCount() {
    final count = _box?.get(_slotCountKey, defaultValue: 0) as int? ?? 0;
    print('Storage: Current slot count: $count');
    return count;
  }

  void placeContainer(int idx, StorageContainer container) {
    if (idx < state.length) {
      final newState = [...state];
      newState[idx] = container;
      state = newState;
    }
  }

  void removeContainer(StorageContainer container) {
    final newState = [
      for (final slot in state)
        if (slot?.id == container.id) null else slot
    ];
    state = newState;
  }
}