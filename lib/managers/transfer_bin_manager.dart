import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/container.dart';

/// Identifier used to persist placed ULDs across the app.
class _SlotKey {
  final String pageId;
  const _SlotKey(this.pageId);

  @override
  String toString() => pageId;
}

class TransferBinManager extends ChangeNotifier {
  static final TransferBinManager _instance = TransferBinManager._internal();
  static TransferBinManager get instance => _instance;

  final Box _box = Hive.box('transferBox');
  static const String _queueKey = 'queue';
  static const String _slotKey = 'slots';

  List<StorageContainer> _ulds = [];
  final Map<String, List<StorageContainer?>> _slots = {};

  TransferBinManager._internal() {
    final storedQueue = _box.get(_queueKey);
    if (storedQueue != null && storedQueue is List) {
      _ulds = List<StorageContainer>.from(storedQueue);
    }
    final storedSlots = _box.get(_slotKey);
    if (storedSlots != null && storedSlots is Map) {
      for (final entry in storedSlots.entries) {
        _slots[entry.key] = List<StorageContainer?>.from(entry.value as List);
      }
    }
  }

  List<StorageContainer> get ulds => List.unmodifiable(_ulds);

  void _save() {
    _box.put(_queueKey, _ulds);
    _box.put(_slotKey, _slots);
  }

  void addULD(StorageContainer uld) {
    _ulds = [..._ulds, uld];
    _save();
    notifyListeners();
  }

  List<StorageContainer?> getSlots(String pageId) {
    return _slots[pageId] ?? const [];
  }

  void setSlotCount(String pageId, int count) {
    final existing = _slots[pageId] ?? [];
    final newList = List<StorageContainer?>.filled(count, null);
    
    // Only copy containers that should remain (within the new count)
    // Don't copy containers beyond the new count - they should be handled
    // by validateSlots or explicit removal
    final copyCount = count < existing.length ? count : existing.length;
    for (int i = 0; i < copyCount; i++) {
      newList[i] = existing[i];
    }
    
    _slots[pageId] = newList;
    _save();
    notifyListeners();
  }
  
  /// Clears slots for a given pageId and sets a new count with all null values
  /// Use this when you want to completely reset the slots
  void resetSlots(String pageId, int count) {
    _slots[pageId] = List<StorageContainer?>.filled(count, null);
    _save();
    notifyListeners();
  }

  void placeULDInSlot(String pageId, int index, StorageContainer container) {
    removeULDFromSlots(container);
    removeULD(container);

    final slots = _slots[pageId] ?? [];
    while (slots.length <= index) {
      slots.add(null);
    }
    slots[index] = container;
    _slots[pageId] = slots;
    _save();
    notifyListeners();
  }

  void removeULDFromSlots(StorageContainer container) {
    for (final entry in _slots.entries) {
      final updated = [
        for (final slot in entry.value)
          if (slot?.id == container.id) null else slot
      ];
      _slots[entry.key] = updated;
    }
    _save();
    notifyListeners();
  }

  /// Validates the slot list for [pageId]. Any ULDs beyond [newSlotCount]
  /// are moved into the transfer bin. This should be called whenever the
  /// number of slots on a page changes.
  void validateSlots(String pageId, int newSlotCount) {
    final slots = _slots[pageId];
    if (slots == null) return;
    if (newSlotCount >= slots.length) {
      // If we're increasing the size, just resize
      setSlotCount(pageId, newSlotCount);
      return;
    }

    debugPrint('VALIDATE $pageId -> $newSlotCount');
    
    // First, collect all containers that need to be moved to transfer bin
    final containersToMove = <StorageContainer>[];
    for (int i = newSlotCount; i < slots.length; i++) {
      final c = slots[i];
      if (c != null) {
        debugPrint(
            'Moved ULD ${c.uld} from $pageId slot $i to transfer bin');
        containersToMove.add(c);
      }
    }
    
    // Now resize the list to the new count FIRST
    _slots[pageId] = slots.sublist(0, newSlotCount);
    
    // Then add the containers to the transfer bin
    for (final c in containersToMove) {
      addULD(c);
    }
    
    _save();
    notifyListeners();
  }

  void removeULD(StorageContainer uld) {
    _ulds = _ulds.where((c) => c.id != uld.id).toList();
    _save();
    notifyListeners();
  }

  void clear() {
    _ulds = [];
    for (final entry in _slots.entries) {
      _slots[entry.key] = List<StorageContainer?>.filled(entry.value.length, null);
    }
    _save();
    notifyListeners();
  }
}