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
            inboundSlots: List.filled(15, null),
            outboundSlots: List.filled(15, null),
          ),
        );

  void loadFromPlane(Plane plane) {
    final required = plane.aircraftTypeCode == 'B762' ? 11 : 15;
    var inbound = List<StorageContainer?>.from(plane.lowerInboundSlots);
    var outbound = List<StorageContainer?>.from(plane.lowerOutboundSlots);
    if (inbound.length < required) {
      inbound.addAll(List.filled(required - inbound.length, null));
    } else if (inbound.length > required) {
      inbound = inbound.sublist(0, required);
    }
    if (outbound.length < required) {
      outbound.addAll(List.filled(required - outbound.length, null));
    } else if (outbound.length > required) {
      outbound = outbound.sublist(0, required);
    }
    state = LowerDeckState(
      inboundSlots: inbound,
      outboundSlots: outbound,
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