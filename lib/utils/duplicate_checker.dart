import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/container.dart';
import '../models/plane.dart';
import '../providers/ball_deck_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/train_provider.dart';
import '../providers/plane_provider.dart';
import '../providers/planes_provider.dart';

/// Returns a description of where a ULD with [label] currently exists,
/// or `null` if the label is unused.
String? findUldLocation(WidgetRef ref, String label) {
  label = label.trim();
  if (label.isEmpty) return null;

  final ballDeck = ref.read(ballDeckProvider);
  for (final slot in ballDeck.slots) {
    if (slot?.uld == label) return 'Ball Deck';
  }
  for (final c in ballDeck.overflow) {
    if (c?.uld == label) return 'Ball Deck';
  }

  final storage = ref.read(storageProvider);
  for (final c in storage) {
    if (c?.uld == label) return 'Storage Page';
  }

  final trains = ref.read(trainProvider);
  for (final train in trains) {
    for (final dolly in train.dollys) {
      if (dolly.load?.uld == label) {
        return 'Train Page';
      }
    }
  }

  final planeState = ref.read(planeProvider);
  final selectedId = ref.read(selectedPlaneIdProvider);
  Plane? selectedPlane;
  final planes = ref.read(planesProvider);
  if (selectedId != null) {
    try {
      selectedPlane = planes.firstWhere((p) => p.id == selectedId);
    } catch (_) {}
  }

  // Check current plane state (unsaved changes)
  String planeName = selectedPlane?.name ?? 'Plane';
  for (final c in planeState.inboundSlots) {
    if (c?.uld == label) return '$planeName, Inbound, Main Deck';
  }
  for (final c in planeState.outboundSlots) {
    if (c?.uld == label) return '$planeName, Outbound, Main Deck';
  }
  for (final c in planeState.lowerInboundSlots) {
    if (c?.uld == label) return '$planeName, Inbound, Lower Deck';
  }
  for (final c in planeState.lowerOutboundSlots) {
    if (c?.uld == label) return '$planeName, Outbound, Lower Deck';
  }

  // Check all persisted planes
  for (final plane in planes) {
    for (final c in plane.inboundSlots) {
      if (c?.uld == label) return '${plane.name}, Inbound, Main Deck';
    }
    for (final c in plane.outboundSlots) {
      if (c?.uld == label) return '${plane.name}, Outbound, Main Deck';
    }
    for (final c in plane.lowerInboundSlots) {
      if (c?.uld == label) return '${plane.name}, Inbound, Lower Deck';
    }
    for (final c in plane.lowerOutboundSlots) {
      if (c?.uld == label) return '${plane.name}, Outbound, Lower Deck';
    }
  }

  return null;
}
