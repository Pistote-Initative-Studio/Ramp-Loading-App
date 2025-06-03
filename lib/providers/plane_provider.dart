import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../models/aircraft.dart';

class PlaneState {
  final LoadingSequence? selectedSequence;
  final List<StorageContainer?> slots;

  PlaneState({required this.selectedSequence, required this.slots});

  PlaneState copyWith({
    LoadingSequence? selectedSequence,
    List<StorageContainer?>? slots,
  }) {
    return PlaneState(
      selectedSequence: selectedSequence ?? this.selectedSequence,
      slots: slots ?? this.slots,
    );
  }
}

class PlaneNotifier extends StateNotifier<PlaneState> {
  PlaneNotifier() : super(PlaneState(selectedSequence: null, slots: []));

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
        if (slot?.uld == container.uld) null else slot,
    ];
    state = state.copyWith(slots: updatedSlots);
  }
}

final planeProvider = StateNotifierProvider<PlaneNotifier, PlaneState>(
  (ref) => PlaneNotifier(),
);
