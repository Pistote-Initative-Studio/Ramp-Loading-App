import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';

final uldProvider = ChangeNotifierProvider((ref) => UldNotifier());

class UldNotifier extends ChangeNotifier {
  void togglePallets(StorageContainer uld, bool value) {
    uld.hasPallets = value;
    try {
      uld.save();
    } catch (_) {}
    notifyListeners();
  }
}
