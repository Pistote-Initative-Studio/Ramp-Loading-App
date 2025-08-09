import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/container.dart';
import '../models/aircraft.dart';
import '../models/plane.dart';
import '../managers/transfer_bin_manager.dart';
import '../managers/uld_placement_manager.dart';

class PlaneState {
  final LoadingSequence? inboundSequence;
  final LoadingSequence? outboundSequence;
  final List<LoadingSequence> configs;
  final List<StorageContainer?> inboundSlots;
  final List<StorageContainer?> outboundSlots;
  final List<StorageContainer?> lowerInboundSlots;
  final List<StorageContainer?> lowerOutboundSlots;

  PlaneState({
    required this.inboundSequence,
    required this.outboundSequence,
    required this.configs,
    required this.inboundSlots,
    required this.outboundSlots,
    required this.lowerInboundSlots,
    required this.lowerOutboundSlots,
  });

  PlaneState copyWith({
    LoadingSequence? inboundSequence,
    LoadingSequence? outboundSequence,
    List<LoadingSequence>? configs,
    List<StorageContainer?>? inboundSlots,
    List<StorageContainer?>? outboundSlots,
    List<StorageContainer?>? lowerInboundSlots,
    List<StorageContainer?>? lowerOutboundSlots,
  }) {
    return PlaneState(
      inboundSequence: inboundSequence ?? this.inboundSequence,
      outboundSequence: outboundSequence ?? this.outboundSequence,
      configs: configs ?? this.configs,
      inboundSlots: inboundSlots ?? this.inboundSlots,
      outboundSlots: outboundSlots ?? this.outboundSlots,
      lowerInboundSlots: lowerInboundSlots ?? this.lowerInboundSlots,
      lowerOutboundSlots: lowerOutboundSlots ?? this.lowerOutboundSlots,
    );
  }
}

class PlaneNotifier extends StateNotifier<PlaneState> {
  PlaneNotifier()
    : super(
        PlaneState(
          inboundSequence: null,
          outboundSequence: null,
          configs: const [],
          inboundSlots: const [],
          outboundSlots: const [],
          lowerInboundSlots: const [],
          lowerOutboundSlots: const [],
        ),
      );

  void loadPlane(Plane plane, [List<LoadingSequence> configs = const []]) {
    final inboundSequence = LoadingSequence(
      plane.inboundSequenceLabel ?? '',
      plane.inboundSequenceLabel ?? '',
      plane.inboundSequenceOrder,
    );
    final outboundSequence = LoadingSequence(
      plane.outboundSequenceLabel,
      plane.outboundSequenceLabel,
      plane.outboundSequenceOrder,
    );
    final lowerRequired = plane.aircraftTypeCode == 'B762' ? 11 : 15;
    var lowerInbound = List<StorageContainer?>.from(plane.lowerInboundSlots);
    var lowerOutbound = List<StorageContainer?>.from(plane.lowerOutboundSlots);
    if (lowerInbound.length < lowerRequired) {
      lowerInbound.addAll(List.filled(lowerRequired - lowerInbound.length, null));
    } else if (lowerInbound.length > lowerRequired) {
      lowerInbound = lowerInbound.sublist(0, lowerRequired);
    }
    if (lowerOutbound.length < lowerRequired) {
      lowerOutbound
          .addAll(List.filled(lowerRequired - lowerOutbound.length, null));
    } else if (lowerOutbound.length > lowerRequired) {
      lowerOutbound = lowerOutbound.sublist(0, lowerRequired);
    }
    state = PlaneState(
      inboundSequence: inboundSequence,
      outboundSequence: outboundSequence,
      configs: configs,
      inboundSlots: List.from(plane.inboundSlots),
      outboundSlots: List.from(plane.outboundSlots),
      lowerInboundSlots: lowerInbound,
      lowerOutboundSlots: lowerOutbound,
    );
  }

  Plane exportPlane(Plane original) {
    return Plane(
      id: original.id,
      name: original.name,
      aircraftTypeCode: original.aircraftTypeCode,
      inboundSequenceLabel:
          state.inboundSequence?.label ?? original.inboundSequenceLabel,
      inboundSequenceOrder:
          state.inboundSequence?.order ?? original.inboundSequenceOrder,
      inboundSlots: List.from(state.inboundSlots),
      outboundSequenceLabel:
          state.outboundSequence?.label ?? original.outboundSequenceLabel,
      outboundSequenceOrder:
          state.outboundSequence?.order ?? original.outboundSequenceOrder,
      outboundSlots: List.from(state.outboundSlots),
      lowerInboundSlots: List.from(state.lowerInboundSlots),
      lowerOutboundSlots: List.from(state.lowerOutboundSlots),
    );
  }

  void selectSequence(LoadingSequence sequence, {required bool outbound}) {
    final transfer = TransferBinManager.instance;
    final current = outbound ? state.outboundSlots : state.inboundSlots;
    final newCount = sequence.order.length;

    // If reducing slots, move excess ULDs to transfer bin
    if (newCount < current.length) {
      for (int i = newCount; i < current.length; i++) {
        final uld = current[i];
        if (uld != null) {
          transfer.addULD(uld);
        }
      }
    }

    // Create new slots array with correct size
    final updated = List<StorageContainer?>.filled(newCount, null);
    
    // Copy over ULDs that fit in the new configuration
    final copyCount = newCount < current.length ? newCount : current.length;
    for (int i = 0; i < copyCount; i++) {
      updated[i] = current[i];
    }

    if (outbound) {
      state = state.copyWith(
        outboundSequence: sequence,
        outboundSlots: updated,
      );
    } else {
      state = state.copyWith(
        inboundSequence: sequence,
        inboundSlots: updated,
      );
    }

    ULDPlacementManager().updateSlotCount('Plane', newCount);
  }

  void placeContainer(
    int index,
    StorageContainer container, {
    required bool outbound,
  }) {
    if (outbound) {
      final updatedSlots = [...state.outboundSlots];
      updatedSlots[index] = container;
      state = state.copyWith(outboundSlots: updatedSlots);
    } else {
      final updatedSlots = [...state.inboundSlots];
      updatedSlots[index] = container;
      state = state.copyWith(inboundSlots: updatedSlots);
    }
  }

  void removeContainer(StorageContainer container, {required bool outbound}) {
    if (outbound) {
      final updatedSlots = [
        for (final slot in state.outboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(outboundSlots: updatedSlots);
    } else {
      final updatedSlots = [
        for (final slot in state.inboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(inboundSlots: updatedSlots);
    }
  }

  void placeLowerDeckContainer(
    int index,
    StorageContainer container, {
    required bool outbound,
  }) {
    if (outbound) {
      final updated = [...state.lowerOutboundSlots];
      updated[index] = container;
      state = state.copyWith(lowerOutboundSlots: updated);
    } else {
      final updated = [...state.lowerInboundSlots];
      updated[index] = container;
      state = state.copyWith(lowerInboundSlots: updated);
    }
  }

  void removeLowerDeckContainer(
    StorageContainer container, {
    required bool outbound,
  }) {
    if (outbound) {
      final updated = [
        for (final slot in state.lowerOutboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(lowerOutboundSlots: updated);
    } else {
      final updated = [
        for (final slot in state.lowerInboundSlots)
          if (slot?.id == container.id) null else slot,
      ];
      state = state.copyWith(lowerInboundSlots: updated);
    }
  }

  /// Adds a container to the first available slot of the plane.
  ///
  /// When [lowerDeck] is true the container is placed on the lower deck,
  /// otherwise it is placed on the main deck. The [outbound] flag selects
  /// between the outbound and inbound views.
  void addToFirstAvailable(
    StorageContainer container, {
    required bool outbound,
    required bool lowerDeck,
  }) {
    if (lowerDeck) {
      final slots =
          outbound ? state.lowerOutboundSlots : state.lowerInboundSlots;
      for (int i = 0; i < slots.length; i++) {
        if (slots[i] == null) {
          placeLowerDeckContainer(i, container, outbound: outbound);
          return;
        }
      }
    } else {
      final slots = outbound ? state.outboundSlots : state.inboundSlots;
      for (int i = 0; i < slots.length; i++) {
        if (slots[i] == null) {
          placeContainer(i, container, outbound: outbound);
          return;
        }
      }
    }
  }
}

final planeProvider = StateNotifierProvider<PlaneNotifier, PlaneState>(
  (ref) => PlaneNotifier(),
);

/// Tracks wether the Plane page is showing the outbound view.
final isOutboundProvider = StateProvider<bool>((ref) => false);
