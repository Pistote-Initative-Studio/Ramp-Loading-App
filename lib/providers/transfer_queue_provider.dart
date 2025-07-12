import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';

class TransferQueueNotifier extends StateNotifier<List<StorageContainer>> {
  TransferQueueNotifier() : super([]);

  void add(StorageContainer container) {
    state = [...state, container];
  }

  void remove(StorageContainer container) {
    state = state.where((c) => c.id != container.id).toList();
  }
}

final transferQueueProvider =
    StateNotifierProvider<TransferQueueNotifier, List<StorageContainer>>(
  (ref) => TransferQueueNotifier(),
);
