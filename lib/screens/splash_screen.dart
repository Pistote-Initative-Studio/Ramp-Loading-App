import 'package:flutter/material.dart';

/// Simple splash screen that optionally shows a logo image.
///
/// The `_hasLogoAsset` flag can be toggled in a future update when an
/// actual image asset is bundled with the app. Until then, an icon is shown
/// to avoid requiring any binary assets in this branch.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const bool _hasLogoAsset = false;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: _hasLogoAsset
            ? Image.asset('assets/icon.png')
            : Icon(Icons.flight_takeoff, size: 64),
      ),
    );
  }
}

