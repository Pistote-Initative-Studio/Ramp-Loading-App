import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/plane.dart';

final selectedPlaneIdProvider = StateProvider<String?>((ref) => null);

final planesProvider = StateNotifierProvider<PlanesNotifier, List<Plane>>((
  ref,
) {
  return PlanesNotifier();
});

class PlanesNotifier extends StateNotifier<List<Plane>> {
  final _box = Hive.box('planeBox');
  static const String planesKey = 'planes';

  PlanesNotifier() : super([]) {
    _loadState();
  }

  void _loadState() {
    final stored = _box.get(planesKey);
    if (stored != null && stored is List) {
      state = List<Plane>.from(stored);
    }
  }

  void _saveState() {
    _box.put(planesKey, state);
  }

  void setPlanes(List<Plane> planes) {
    state = planes;
    _saveState();
  }

  void addPlane(Plane plane) {
    state = [...state, plane];
    _saveState();
  }

  void updatePlane(Plane updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
    _saveState();
  }

  void removePlane(String id) {
    state = state.where((p) => p.id != id).toList();
    _saveState();
  }
}
