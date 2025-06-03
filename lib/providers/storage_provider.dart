import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';

final storageProvider =
    StateNotifierProvider<StorageNotifier, List<StorageContainer?>>((ref) {
      return StorageNotifier();
    });

class StorageNotifier extends StateNotifier<List<StorageContainer?>> {
  StorageNotifier() : super(List.filled(20, null)); // Default 20 spaces

  void setSize(int count) {
    state = List.generate(
      count,
      (index) => index < state.length ? state[index] : null,
    );
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
}
