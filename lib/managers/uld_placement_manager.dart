import 'package:hive_flutter/hive_flutter.dart';

import '../models/container.dart';

/// Central manager for ULD placement across all zones in the app.
class ULDPlacementManager {
  ULDPlacementManager._internal() {
    final Map? bd = _box.get(_ballDeckKey);
    if (bd is Map) ballDeck.addAll(bd.cast<String, StorageContainer>());

    final Map? pd = _box.get(_planeDeckKey);
    if (pd is Map) planeDeck.addAll(pd.cast<String, StorageContainer>());

    final Map? td = _box.get(_trainDeckKey);
    if (td is Map) trainDeck.addAll(td.cast<String, StorageContainer>());

    final Map? st = _box.get(_storageKey);
    if (st is Map) storage.addAll(st.cast<String, StorageContainer>());

    final List? tb = _box.get(_transferKey);
    if (tb is List) transferBin.addAll(List<StorageContainer>.from(tb));
  }

  static final ULDPlacementManager _instance = ULDPlacementManager._internal();

  factory ULDPlacementManager() => _instance;

  final Box _box = Hive.box('uldPlacementBox');

  static const String _ballDeckKey = 'ballDeck';
  static const String _planeDeckKey = 'planeDeck';
  static const String _trainDeckKey = 'trainDeck';
  static const String _storageKey = 'storage';
  static const String _transferKey = 'transferBin';

  /// Zone maps
  final Map<String, StorageContainer> ballDeck = {};
  final Map<String, StorageContainer> planeDeck = {};
  final Map<String, StorageContainer> trainDeck = {};
  final Map<String, StorageContainer> storage = {};
  final List<StorageContainer> transferBin = [];

  void _save() {
    _box
      ..put(_ballDeckKey, ballDeck)
      ..put(_planeDeckKey, planeDeck)
      ..put(_trainDeckKey, trainDeck)
      ..put(_storageKey, storage)
      ..put(_transferKey, transferBin);
  }

  /// Update the slot count for [zone] and move any containers in now-invalid
  /// slots to the transfer bin.
  void updateSlotCount(String zone, int newCount) {
    final map = _getZoneMap(zone);
    final removedKeys =
        map.keys.where((key) => !_slotExists(key, newCount)).toList();

    for (final key in removedKeys) {
      transferBin.add(map[key]!);
      map.remove(key);
    }
    _save();
  }

  Map<String, StorageContainer> _getZoneMap(String zone) {
    switch (zone) {
      case 'BallDeck':
        return ballDeck;
      case 'Plane':
        return planeDeck;
      case 'Train':
        return trainDeck;
      case 'Storage':
        return storage;
      default:
        throw Exception('Unknown zone: ' + zone);
    }
  }

  bool _slotExists(String slotId, int newCount) {
    final index = int.tryParse(slotId.replaceAll(RegExp(r'[^0-9]'), ''));
    return index != null && index < newCount;
  }
}

