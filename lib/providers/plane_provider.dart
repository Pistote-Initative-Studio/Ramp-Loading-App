import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../models/aircraft.dart';
import '../models/plane.dart';

class PlaneState {
  final LoadingSequence? selectedSequence;
  final List<LoadingSequence> configs;
  final List<StorageContainer?> slots;

  PlaneState({
    required this.selectedSequence,
    required this.configs,
    required this.slots,
  });

  PlaneState copyWith({
    LoadingSequence? selectedSequence,
    List<LoadingSequence>? configs,
    List<StorageContainer?>? slots,
  }) {
    return PlaneState(
      selectedSequence: selectedSequence ?? this.selectedSequence,
      configs: configs ?? this.configs,
      slots: slots ?? this.slots,
    );
  }
}

class PlaneNotifier extends StateNotifier<PlaneState> {
  PlaneNotifier()
    : super(PlaneState(selectedSequence: null, configs: const [], slots: []));

  void loadPlane(Plane plane, [List<LoadingSequence> configs = const []]) {
    final sequence = LoadingSequence(
      plane.sequenceLabel,
      plane.sequenceLabel,
      plane.sequenceOrder,
    );
    state = PlaneState(
      selectedSequence: sequence,
      configs: configs,
      slots: List.from(plane.slots),
    );
  }

  Plane exportPlane(Plane origional) {
    return Plane(
      id: origional.id,
      name: origional.name,
      aircraftTypeCode: origional.aircraftTypeCode,
      sequenceLabel: state.selectedSequence?.label ?? origional.sequenceLabel,
      sequenceOrder: state.selectedSequence?.order ?? origional.sequenceOrder,
      slots: List.from(state.slots),
    );
  }

  void selectSequence(LoadingSequence sequence) {
    final newSlots = List<StorageContainer?>.filled(
      sequence.order.length,
      null,
    );
    Future.microtask(() {
      state = state.copyWith(selectedSequence: sequence, slots: newSlots);
    });
  }

  void placeContainer(int index, StorageContainer container) {
    final updatedSlots = [...state.slots];
    updatedSlots[index] = container;
    state = state.copyWith(slots: updatedSlots);
  }

  void removeContainer(StorageContainer container) {
    final updatedSlots = [
      for (final slot in state.slots)
        if (slot?.id == container.id) null else slot,
    ];
    state = state.copyWith(slots: updatedSlots);
  }
}

final planeProvider = StateNotifierProvider<PlaneNotifier, PlaneState>(
  (ref) => PlaneNotifier(),
);
