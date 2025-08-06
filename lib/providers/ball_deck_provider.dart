import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/container.dart';
import '../managers/transfer_bin_manager.dart';
import '../managers/uld_placement_manager.dart';

part 'ball_deck_provider.g.dart';

@HiveType(typeId: 6)
class BallDeckState {
  @HiveField(0)
  final List<StorageContainer?> slots;

  @HiveField(1)
  final List<StorageContainer?> overflow;

  BallDeckState({required this.slots, required this.overflow});

  BallDeckState copyWith({
    List<StorageContainer?>? slots,
    List<StorageContainer?>? overflow,
  }) {
    return BallDeckState(
      slots: slots ?? this.slots,
      overflow: overflow ?? this.overflow,
    );
  }
}

class BallDeckNotifier extends StateNotifier<BallDeckState> {
  final Box _box = Hive.box('ballDeckBox');
  static const String stateKey = 'state';
  static const String _slotsId = 'ballDeck';
  static const String _overflowId = 'ballDeckOverflow';

  BallDeckNotifier() : super(_loadInitial(Hive.box('ballDeckBox')));

  static BallDeckState _loadInitial(Box box) {
    final stored = box.get(stateKey);
    if (stored != null && stored is BallDeckState) {
      return stored;
    }
    final manager = TransferBinManager.instance;
    final slots = manager.getSlots(_slotsId);
    final overflow = manager.getSlots(_overflowId);
    if (slots.isNotEmpty || overflow.isNotEmpty) {
      return BallDeckState(slots: slots, overflow: overflow);
    }
    return BallDeckState(slots: List.filled(7, null), overflow: []);
  }

  void setSlotCount(
    int count,
  ) {
    final manager = TransferBinManager.instance;
    // Move any ULDs that no longer fit into the ball deck to the transfer bin
    // before adjusting the slot count. This ensures containers from removed
    // slots do not remain associated with the same index and reappear when the
    // slots are restored.
    if (count < state.slots.length) {
      for (int i = count; i < state.slots.length; i++) {
        final c = state.slots[i];
        if (c != null) {
          debugPrint(
              'Moved ULD ${c.uld} from BallDeck slot $i to transfer bin');
          manager.addULD(c);
        }
      }
    }

    // Let the manager reconcile its internal slot list and remove any
    // containers that fall outside the new range.
    manager.validateSlots(_slotsId, count);
    manager.setSlotCount(_slotsId, count);

    // Persist the updated slot list in state and Hive.
    state = state.copyWith(slots: manager.getSlots(_slotsId));
    _saveState();

    // Keep placement tracking in sync so other zones see the move.
    final placement = ULDPlacementManager();
    placement.updateSlotCount('BallDeck', count);
  }

  void addUld(StorageContainer container) {
    final manager = TransferBinManager.instance;

    // Ensure the manager still has the correct number of slots. If the list of
    // slots has been lost or reset (e.g. returning an empty list), recreate the
    // slot structure based on the current state so that adding a ULD does not
    // change the configured slot count.
    if (manager.getSlots(_slotsId).length != state.slots.length) {
      manager.setSlotCount(_slotsId, state.slots.length);
    }

    final slots = manager.getSlots(_slotsId);
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) {
        manager.placeULDInSlot(_slotsId, i, container);
        state = state.copyWith(slots: manager.getSlots(_slotsId));
        _saveState();
        return;
      }
    }
    final overflow = manager.getSlots(_overflowId);
    for (int i = 0; i < overflow.length; i++) {
      final slot = overflow[i];
      if (slot == null || slot.uld.startsWith('EMPTY_SLOT')) {
        manager.placeULDInSlot(_overflowId, i, container);
        state = state.copyWith(
          slots: manager.getSlots(_slotsId),
          overflow: manager.getSlots(_overflowId),
        );
        _saveState();
        return;
      }
    }
    manager.placeULDInSlot(_overflowId, overflow.length, container);
    state = state.copyWith(
      slots: manager.getSlots(_slotsId),
      overflow: manager.getSlots(_overflowId),
    );
    _saveState();
  }

  void placeContainer(int slotIdx, StorageContainer container) {
    final manager = TransferBinManager.instance;
    manager.placeULDInSlot(_slotsId, slotIdx, container);
    state = state.copyWith(slots: manager.getSlots(_slotsId));
    _saveState();
  }

  void placeIntoOverflowAt(StorageContainer container, int index) {
    final manager = TransferBinManager.instance;
    manager.placeULDInSlot(_overflowId, index, container);
    state = state.copyWith(
      slots: manager.getSlots(_slotsId),
      overflow: manager.getSlots(_overflowId),
    );
    _saveState();
  }

  // Remove a ULD from anywhere on the ball deck or overflow by id
  void removeContainer(StorageContainer container) {
    final manager = TransferBinManager.instance;
    manager.removeULDFromSlots(container);
    state = state.copyWith(
      slots: manager.getSlots(_slotsId),
      overflow: manager.getSlots(_overflowId),
    );
    _saveState();
  }

  void _saveState() {
    _box.put(stateKey, state);
  }
}

final ballDeckProvider = StateNotifierProvider<BallDeckNotifier, BallDeckState>(
  (ref) {
    return BallDeckNotifier();
  },
);
