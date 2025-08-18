import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const double kBannerHeight = 50.0;

class AdsController {
  AdsController._();
  static final AdsController instance = AdsController._();

  bool adsEnabled = false;
  bool bannerEnabled = true;
  bool testMode = true;

  final int cooldownSeconds = 120;
  final int dailyCap = 3;

  DateTime? _lastShown;
  DateTime? _day;
  int _shownToday = 0;

  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;

  bool get bannerVisible => adsEnabled && bannerEnabled && _bannerAd != null;
  Widget? get bannerWidget => _bannerAd == null ? null : AdWidget(ad: _bannerAd!);

  Future<void> initialize() async {
    if (!adsEnabled) return;
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: BannerAd.testAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Banner loaded'),
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
          _bannerAd = null;
        },
      ),
      request: const AdRequest(),
    )..load();

    await preloadInterstitial();
  }

  Future<void> preloadInterstitial() async {
    if (!adsEnabled) return;
    if (_interstitialAd != null) return;
    await InterstitialAd.load(
      adUnitId: InterstitialAd.testAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('Interstitial loaded');
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> maybeShowInterstitial({String? trigger}) async {
    if (!adsEnabled) return;
    final now = DateTime.now();
    if (_day == null || now.difference(_day!).inDays >= 1) {
      _day = now;
      _shownToday = 0;
    }
    if (_shownToday >= dailyCap) {
      debugPrint('Interstitial cap reached');
      return;
    }
    if (_lastShown != null &&
        now.difference(_lastShown!).inSeconds < cooldownSeconds) {
      debugPrint('Interstitial cooldown');
      return;
    }
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('Interstitial not ready');
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('Interstitial failed to show: $err');
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitial();
      },
    );
    ad.show();
    _lastShown = now;
    _shownToday++;
  }
}
