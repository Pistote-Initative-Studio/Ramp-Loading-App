import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/container.dart';
import '../models/aircraft.dart';

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
  BallDeckNotifier()
    : super(BallDeckState(slots: List.filled(7, null), overflow: []));

  void setSlotCount(int count) {
    final updatedSlots = List<StorageContainer?>.filled(count, null);
    state = BallDeckState(slots: updatedSlots, overflow: []);
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
          type: 'EMPTY',
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
          type: 'EMPTY',
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
          type: 'EMPTY',
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

  void _saveState() {
    // You can implement Hive or other persistence logic here
  }
}

final ballDeckProvider = StateNotifierProvider<BallDeckNotifier, BallDeckState>(
  (ref) {
    return BallDeckNotifier();
  },
);
