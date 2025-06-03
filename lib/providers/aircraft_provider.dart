import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/aircraft.dart';

// This provider will hold the selected aircraft
final aircraftProvider = StateProvider<Aircraft?>((ref) => null);
