import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/initialization_service.dart';

/// Splash screen that waits for initialization while displaying branding.
///
/// The screen remains visible for at least [kSplashMinDuration]. If
/// initialization takes longer, it will wait until initialization completes or
/// until [kSplashMaxDuration] elapses, whichever comes first. A short fade-out
/// animation is played before navigating away.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const bool _hasLogoAsset = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _navigated = false;
  bool _initDegraded = false;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(_fadeController);
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final initFuture = InitializationService.initialize();
    final minDelay = Future.delayed(kSplashMinDuration);

    // Watchdog to ensure we never wait indefinitely.
    Future.delayed(kSplashMaxDuration).then((_) {
      if (!_navigated) {
        _initDegraded = true;
        _proceed();
      }
    });

    await Future.wait([initFuture, minDelay]);
    if (!_navigated) {
      _proceed();
    }
  }

  Future<void> _proceed() async {
    _navigated = true;
    await _fadeController.forward();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: const Center(
            child: _hasLogoAsset
                ? Image.asset('assets/icon.png')
                : Icon(Icons.flight_takeoff, size: 64),
          ),
        ),
      ),
    );
  }
}


