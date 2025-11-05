import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper with ChangeNotifier {
  AdHelper._();
  static final AdHelper instance = AdHelper._();

  static const int maxFailedLoadAttempts = 3;
  static const Duration adCooldown = Duration(seconds: 55);

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  DateTime? _lastInterstitialShowTime;

  BannerAd? bannerAd;
  bool isBannerAdReady = false;

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6781596667721012/7479756886';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6781596667721012/7479756886';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6781596667721012/1285382613';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6781596667721012/1285382613';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  void loadBannerAd() {
    bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          isBannerAdReady = false;
          ad.dispose();
          notifyListeners();
        },
      ),
    )..load();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (Ad ad) {
          _interstitialAd = ad as InterstitialAd;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    // Check if enough time has passed since the last ad
    if (_lastInterstitialShowTime != null &&
        DateTime.now().difference(_lastInterstitialShowTime!) < adCooldown) {
      print("Ad cooldown active. Not showing interstitial ad.");
      return;
    }

    if (_interstitialAd == null) {
      print('Warning: Interstitial ad is not loaded yet.');
      loadInterstitialAd(); // Try to load for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        loadInterstitialAd(); // Pre-load the next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        loadInterstitialAd(); // Pre-load the next ad
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
    _lastInterstitialShowTime = DateTime.now();
  }

  void dispose() {
    _interstitialAd?.dispose();
    bannerAd?.dispose();
  }
} 