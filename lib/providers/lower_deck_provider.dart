import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';

final lowerDeckProvider =
    StateNotifierProvider<LowerDeckNotifier, List<StorageContainer?>>((ref) {
      return LowerDeckNotifier();
    });

class LowerDeckNotifier extends StateNotifier<List<StorageContainer?>> {
  LowerDeckNotifier() : super(List.filled(11, null));

  void placeContainer(int idx, StorageContainer container) {
    final updated = [...state];
    updated[idx] = container;
    state = updated;
  }

  void removeContainer(StorageContainer container) {
    final updated = [
      for (final slot in state)
        if (slot?.id == container.id) null else slot,
    ];
    state = updated;
  }
}
// This provider manages the state of the lower deck containers in a storage system.