import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/container.dart';

class TransferQueueNotifier extends StateNotifier<List<StorageContainer>> {
  final Box box;
  static const String queueKey = 'queue';

  TransferQueueNotifier(this.box) : super([]) {
    _loadState();
  }

  void _loadState() {
    final stored = box.get(queueKey);
    if (stored != null && stored is List) {
      state = List<StorageContainer>.from(stored);
    }
  }

  void _saveState() {
    box.put(queueKey, state);
  }

  void add(StorageContainer container) {
    state = [...state, container];
    _saveState();
  }

  void remove(StorageContainer container) {
    state = state.where((c) => c.id != container.id).toList();
    _saveState();
  }

  void clear() {
    state = [];
    _saveState();
  }
}

final transferQueueProvider =
    StateNotifierProvider<TransferQueueNotifier, List<StorageContainer>>(
  (ref) => TransferQueueNotifier(Hive.box('transferBox')),
);
