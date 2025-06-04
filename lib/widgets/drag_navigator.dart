// /lib/widgets/drag_navigator.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart'; // import HomeNavState

class DragNavigator {
  static const _edge = 24.0;
  static const _delay = Duration(milliseconds: 300);

  static Timer? _edgeTimer;
  static OverlayEntry? _dock;
  static const _icons = [
    Icons.flight,
    Icons.train,
    Icons.grid_on,
    Icons.warehouse,
  ];

  static void maybeFlip(BuildContext ctx, Offset global) {
    final size = MediaQuery.of(ctx).size;
    if (global.dx < _edge && _edgeTimer == null) {
      _edgeTimer = Timer(_delay, () => _flip(ctx, false));
    } else if (global.dx > size.width - _edge && _edgeTimer == null) {
      _edgeTimer = Timer(_delay, () => _flip(ctx, true));
    } else if (global.dx >= _edge && global.dx <= size.width - _edge) {
      _edgeTimer?.cancel();
      _edgeTimer = null;
    }
  }

  static void _flip(BuildContext ctx, bool forward) {
    final nav = ctx.findAncestorStateOfType<HomeNavState>()!;
    final target = (nav.page + (forward ? 1 : -1)) % 4;
    nav.jumpToPage(target);
    _edgeTimer = null;
  }

  static void showDock(BuildContext ctx) {
    if (_dock != null) return;
    final nav = ctx.findAncestorStateOfType<HomeNavState>()!;
    _dock = OverlayEntry(
      builder:
          (_) => Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (i) => DragTarget(
                  onAcceptWithDetails: (_) => nav.jumpToPage(i),
                  builder:
                      (ctx, cand, rej) => Icon(
                        _icons[i],
                        size: 36,
                        color:
                            cand.isEmpty ? Colors.white54 : Colors.yellowAccent,
                      ),
                ),
              ),
            ),
          ),
    );
    Overlay.of(ctx, rootOverlay: true).insert(_dock!);
  }

  static void hideDock() {
    _dock?.remove();
    _dock = null;
  }
}
