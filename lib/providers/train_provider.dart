import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/train.dart';
import '../models/container.dart';

final trainProvider = StateNotifierProvider<TrainNotifier, List<Train>>((ref) {
  return TrainNotifier();
});

class TrainNotifier extends StateNotifier<List<Train>> {
  final _box = Hive.box('trainBox');
  static const String trainsKey = 'trains';
  static const String lastOpenedKey = 'lastOpenedDate';

  TrainNotifier() : super([]) {
    _loadState();
  }

  void _loadState() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastOpened = _box.get(lastOpenedKey) as String?;

    final stored = _box.get(trainsKey);
    if (stored != null && stored is List) {
      final List<Train> loaded = List<Train>.from(stored);

      // If it's a new day, clear the ULDs but keep config
      if (lastOpened != today) {
        for (final train in loaded) {
          for (int i = 0; i < train.dollys.length; i++) {
            train.dollys[i] = Dolly(train.dollys[i].idx);
          }
        }
      }

      state = loaded;
    }

    _box.put(lastOpenedKey, today);
  }

  void _saveState() {
    _box.put(trainsKey, state);
    _box.put(lastOpenedKey, DateTime.now().toIso8601String().substring(0, 10));
  }

  void setTrains(List<Train> trains) {
    state = trains;
    _saveState();
  }

  void addTrain(Train train) {
    state = [...state, train];
    _saveState();
  }

  void removeTrain(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveState();
  }

  void updateTrain(Train updated) {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    _saveState();
  }

  void assignUldToDolly({
    required String trainId,
    required int dollyIdx,
    required StorageContainer container,
  }) {
    final trains = [...state];
    final train = trains.firstWhere((t) => t.id == trainId);
    final dolly = train.dollys[dollyIdx];
    train.dollys[dollyIdx] = Dolly(dolly.idx, load: container);
    state = trains;
    _saveState();
  }

  void clearUldFromDolly({
    required String trainId,
    required int dollyIdx,
  }) {
    final trains = [...state];
    final train = trains.firstWhere((t) => t.id == trainId);
    final dolly = train.dollys[dollyIdx];
    train.dollys[dollyIdx] = Dolly(dolly.idx);
    state = trains;
    _saveState();
  }

  // Remove a ULD from any train dolly by id
  void removeContainer(StorageContainer container) {
    final trains = [...state];
    bool changed = false;
    for (int t = 0; t < trains.length; t++) {
      final train = trains[t];
      for (int i = 0; i < train.dollys.length; i++) {
        if (train.dollys[i].load?.id == container.id) {
          train.dollys[i] = Dolly(train.dollys[i].idx);
          changed = true;
        }
      }
    }
    if (changed) {
      state = trains;
      _saveState();
    }
  }

  /// Adds a [container] to the first available dolly starting from the first
  /// train. If all dollies are occupied the container is ignored.
  void addToFirstAvailable(StorageContainer container) {
    final trains = [...state];
    for (final train in trains) {
      for (int i = 0; i < train.dollys.length; i++) {
        if (train.dollys[i].load == null) {
          train.dollys[i] = Dolly(train.dollys[i].idx, load: container);
          state = trains;
          _saveState();
          return;
        }
      }
    }
  }
}
