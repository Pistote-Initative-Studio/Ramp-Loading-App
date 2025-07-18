import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/container.dart';

class TransferBinManager extends ChangeNotifier {
  static final TransferBinManager _instance = TransferBinManager._internal();
  static TransferBinManager get instance => _instance;

  final Box _box = Hive.box('transferBox');
  static const String _key = 'queue';

  List<StorageContainer> _ulds = [];

  TransferBinManager._internal() {
    final stored = _box.get(_key);
    if (stored != null && stored is List) {
      _ulds = List<StorageContainer>.from(stored);
    }
  }

  List<StorageContainer> get ulds => List.unmodifiable(_ulds);

  void _save() {
    _box.put(_key, _ulds);
  }

  void addULD(StorageContainer uld) {
    _ulds = [..._ulds, uld];
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
    _save();
    notifyListeners();
  }
}

