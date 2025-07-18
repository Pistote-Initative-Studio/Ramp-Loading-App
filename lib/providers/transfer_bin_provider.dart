import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../managers/transfer_bin_manager.dart';

final transferBinProvider = ChangeNotifierProvider<TransferBinManager>((ref) {
  return TransferBinManager.instance;
});
