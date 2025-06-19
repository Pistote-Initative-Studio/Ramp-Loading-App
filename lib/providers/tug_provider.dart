import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tug.dart';

final tugProvider = StateNotifierProvider<TugNotifier, List<Tug>>((ref) {
  return TugNotifier(Hive.box('tugBox'));
});

class TugNotifier extends StateNotifier<List<Tug>> {
  final Box box;
  static const String tugsKey = 'tugs';

  TugNotifier(this.box) : super([]) {
    _loadState();
  }

  void _loadState() {
    final stored = box.get(tugsKey);
    if (stored != null && stored is List) {
      state = List<Tug>.from(stored);
    }
  }

  void _saveState() {
    box.put(tugsKey, state);
  }

  void setTugs(List<Tug> tugs) {
    state = tugs;
    _saveState();
  }

  void addTug(Tug tug) {
    state = [...state, tug];
    _saveState();
  }

  void removeTug(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveState();
  }

  void updateTug(Tug updated) {
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
    _saveState();
  }
}
