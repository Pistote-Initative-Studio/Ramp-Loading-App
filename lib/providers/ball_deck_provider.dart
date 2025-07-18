import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/container.dart';
import '../models/aircraft.dart';
import '../managers/transfer_bin_manager.dart';

part 'ball_deck_provider.g.dart';

@HiveType(typeId: 1)
class BallDeckState {
  @HiveField(0)
  final List<StorageContainer?> slots;

  @HiveField(1)
  final List<StorageContainer> overflow;

  BallDeckState({required this.slots, required this.overflow});
}

class BallDeckNotifier extends StateNotifier<BallDeckState> {
  final Box _box = Hive.box('ballDeckBox');
  static const String stateKey = 'state';

  BallDeckNotifier() : super(_loadInitial(Hive.box('ballDeckBox')));

  static BallDeckState _loadInitial(Box box) {
    final stored = box.get(stateKey);
    if (stored != null && stored is BallDeckState) {
      return stored;
    }
    return BallDeckState(slots: List.filled(7, null), overflow: []);
  }

  void setSlotCount(
    int count, {
    TransferBinManager? transferBin,
  }) {
    final oldSlots = state.slots;
    final updatedSlots = List<StorageContainer?>.filled(count, null);
    final copyLen = count < oldSlots.length ? count : oldSlots.length;
    for (int i = 0; i < copyLen; i++) {
      updatedSlots[i] = oldSlots[i];
    }
    if (count < oldSlots.length && transferBin != null) {
      for (int i = count; i < oldSlots.length; i++) {
        final c = oldSlots[i];
        if (c != null) {
          transferBin.addULD(c);
          // Debug print to verify transfer logic
          // ignore: avoid_print
          print('ULD ${c.uld} moved to Transfer Bin due to slot removal');
        }
      }
    }
    state = BallDeckState(slots: updatedSlots, overflow: state.overflow);
    _saveState();
  }

  void addUld(StorageContainer container) {
    final newSlots = [...state.slots];
    final newOverflow = [...state.overflow];

    for (int i = 0; i < newSlots.length; i++) {
      if (newSlots[i] == null) {
        newSlots[i] = container;
        state = BallDeckState(slots: newSlots, overflow: newOverflow);
        _saveState();
        return;
      }
    }

    for (int i = 0; i < newOverflow.length; i++) {
      if (newOverflow[i].uld.startsWith('EMPTY_SLOT')) {
        newOverflow[i] = container;
        state = BallDeckState(slots: newSlots, overflow: newOverflow);
        _saveState();
        return;
      }
    }

    newOverflow.add(container);
    state = BallDeckState(slots: newSlots, overflow: newOverflow);
    _saveState();
  }

  void placeContainer(int slotIdx, StorageContainer container) {
    final newSlots = [...state.slots];
    final newOverflow = [...state.overflow];

    for (int i = 0; i < newSlots.length; i++) {
      if (newSlots[i]?.id == container.id) newSlots[i] = null;
    }

    for (int i = 0; i < newOverflow.length; i++) {
      if (newOverflow[i].id == container.id) {
        newOverflow[i] = StorageContainer(
          id: 'EMPTY_SLOT_$i',
          uld: 'EMPTY_SLOT_$i',
          type: SizeEnum.EMPTY,
          size: SizeEnum.PAG_88x125,
          weightKg: 0,
          hasDangerousGoods: false,
          colorIndex: null,
        );
      }
    }

    newSlots[slotIdx] = container;
    state = BallDeckState(slots: newSlots, overflow: newOverflow);
    _saveState();
  }

  void placeIntoOverflowAt(StorageContainer container, int index) {
    final newSlots = [...state.slots];
    final newOverflow = [...state.overflow];

    for (int i = 0; i < newSlots.length; i++) {
      if (newSlots[i]?.id == container.id) newSlots[i] = null;
    }

    for (int i = 0; i < newOverflow.length; i++) {
      if (newOverflow[i].id == container.id) {
        newOverflow[i] = StorageContainer(
          id: 'EMPTY_SLOT_$i',
          uld: 'EMPTY_SLOT_$i',
          type: SizeEnum.EMPTY,
          size: SizeEnum.PAG_88x125,
          weightKg: 0,
          hasDangerousGoods: false,
          colorIndex: null,
        );
      }
    }

    while (newOverflow.length <= index) {
      newOverflow.add(
        StorageContainer(
          id: 'EMPTY_SLOT_${newOverflow.length}',
          uld: 'EMPTY_SLOT_${newOverflow.length}',
          type: SizeEnum.EMPTY,
          size: SizeEnum.PAG_88x125,
          weightKg: 0,
          hasDangerousGoods: false,
          colorIndex: null,
        ),
      );
    }

    newOverflow[index] = container;
    state = BallDeckState(slots: newSlots, overflow: newOverflow);
    _saveState();
  }

  // Remove a ULD from anywhere on the ball deck or overflow by id
  void removeContainer(StorageContainer container) {
    final newSlots = [
      for (final slot in state.slots)
        if (slot?.id == container.id) null else slot
    ];

    final newOverflow = [
      for (int i = 0; i < state.overflow.length; i++)
        state.overflow[i].id == container.id
            ? StorageContainer(
                id: 'EMPTY_SLOT_$i',
                uld: 'EMPTY_SLOT_$i',
                type: SizeEnum.EMPTY,
                size: SizeEnum.PAG_88x125,
                weightKg: 0,
                hasDangerousGoods: false,
                colorIndex: null,
              )
            : state.overflow[i]
    ];

    state = BallDeckState(slots: newSlots, overflow: newOverflow);
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
