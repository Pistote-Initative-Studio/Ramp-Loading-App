import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../models/plane.dart';

class LowerDeckState {
  final List<StorageContainer?> inboundSlots;
  final List<StorageContainer?> outboundSlots;

  const LowerDeckState({
    required this.inboundSlots,
    required this.outboundSlots,
  });

  LowerDeckState copyWith({
    List<StorageContainer?>? inboundSlots,
    List<StorageContainer?>? outboundSlots,
  }) {
    return LowerDeckState(
      inboundSlots: inboundSlots ?? this.inboundSlots,
      outboundSlots: outboundSlots ?? this.outboundSlots,
    );
  }
}

final lowerDeckProvider =
    StateNotifierProvider<LowerDeckNotifier, LowerDeckState>((ref) {
      return LowerDeckNotifier();
    });

class LowerDeckNotifier extends StateNotifier<LowerDeckState> {
  LowerDeckNotifier()
    : super(
        LowerDeckState(
          inboundSlots: List.filled(11, null),
          outboundSlots: List.filled(11, null),
        ),
      );

  void loadFromPlane(Plane plane) {
    state = LowerDeckState(
      inboundSlots: List.from(plane.lowerInboundSlots),
      outboundSlots: List.from(plane.lowerOutboundSlots),
    );
  }

  void placeContainer(
    int idx,
    StorageContainer container, {
    required bool outbound,
  }) {
    if (outbound) {
      final updated = [...state.outboundSlots];
      updated[idx] = container;
      state = state.copyWith(outboundSlots: updated);
    } else {
      final updated = [...state.inboundSlots];
      updated[idx] = container;
      state = state.copyWith(inboundSlots: updated);
    }
  }

  void removeContainer(StorageContainer container, {required bool outbound}) {
    if (outbound) {
      final updated = [
        for (final slot in state.outboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(outboundSlots: updated);
    } else {
      final updated = [
        for (final slot in state.inboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(inboundSlots: updated);
    }
  }
}
// This provider manages the state of the lower deck containers in a storage system.