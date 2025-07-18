import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../managers/transfer_bin_manager.dart';

final storageProvider =
    StateNotifierProvider<StorageNotifier, List<StorageContainer?>>((ref) {
      return StorageNotifier();
    });

class StorageNotifier extends StateNotifier<List<StorageContainer?>> {
  StorageNotifier() : super(List.filled(20, null)); // Default 20 spaces

  void setSize(
    int count, {
    TransferBinManager? transferBin,
  }) {
    final oldState = state;
    final newState = List<StorageContainer?>.filled(count, null);
    final copyLen = count < oldState.length ? count : oldState.length;
    for (int i = 0; i < copyLen; i++) {
      newState[i] = oldState[i];
    }
    if (count < oldState.length && transferBin != null) {
      for (int i = count; i < oldState.length; i++) {
        final c = oldState[i];
        if (c != null) {
          transferBin.addULD(c);
          // Debug print
          // ignore: avoid_print
          print('ULD ${c.uld} moved to Transfer Bin due to slot removal');
        }
      }
    }
    state = newState;
  }

  void placeContainer(int idx, StorageContainer? container) {
    final newState = [...state];
    newState[idx] = container;
    state = newState;
  }

  // ✅ NEW: Add a ULD to the first available slot
  void addUld(StorageContainer container) {
    final newState = [...state];
    for (int i = 0; i < newState.length; i++) {
      if (newState[i] == null) {
        newState[i] = container;
        state = newState;
        return;
      }
    }
    newState.add(container); // Overflow behavior (expand list)
    state = newState;
  }

  // Remove a ULD from storage by id
  void removeContainer(StorageContainer container) {
    final newState = [
      for (final slot in state)
        if (slot?.id == container.id) null else slot
    ];
    state = newState;
  }
}
