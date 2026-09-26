import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import '../config.dart';
import 'app_state.dart';

/// Werbung in der kostenlosen Version: ein Banner unten auf Detail- und
/// Listen-Seite und höchstens eine Vollbild-Anzeige pro Tag.
///
/// Vor dem ersten Laden fragt Googles Einwilligungs-Dialog (UMP) nach der
/// Zustimmung, wo das nötig ist (EU/EWR, UK, Schweiz). Mit Pro gibt es keine
/// Werbung.
class AdService extends ChangeNotifier {
  AppState? _state;
  bool _ready = false;
  bool _privacyOptionsRequired = false;
  InterstitialAd? _interstitial;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Anzeigen dürfen geladen werden (unterstützt, Einwilligung geklärt,
  /// kein Pro).
  bool get enabled => _ready && !(_state?.isPro ?? true);

  /// In den Einstellungen „Datenschutz-Einstellungen“ anbieten (DSGVO).
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  static String? get bannerUnitId => _unit(
    test: Platform.isIOS ? kTestBannerIos : kTestBannerAndroid,
    real: Platform.isIOS ? kAdBannerIos : kAdBannerAndroid,
  );

  static String? get _interstitialUnitId => _unit(
    test: Platform.isIOS ? kTestInterstitialIos : kTestInterstitialAndroid,
    real: Platform.isIOS ? kAdInterstitialIos : kAdInterstitialAndroid,
  );

  static String? _unit({required String test, required String real}) {
    if (!kReleaseMode) return test;
    return real.isEmpty ? null : real;
  }

  Future<void> init(AppState state) async {
    _state = state;
    state.addListener(_onStateChanged);
    if (!_supported || bannerUnitId == null) return;
    // Den Einwilligungs-Dialog erst nach dem Onboarding zeigen.
    if (state.onboardingDone) await _start();
  }

  bool _started = false;

  Future<void> _start() async {
    final state = _state;
    if (_started || state == null || state.isPro) return;
    _started = true;

    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('Einwilligung: ${error.message}');
        });
        done.complete();
      },
      (error) {
        debugPrint('Einwilligung: ${error.message}');
        done.complete();
      },
    );
    await done.future;

    try {
      _privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) {
        notifyListeners();
        return;
      }
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
    } catch (e) {
      debugPrint('Werbung: $e');
    }
    notifyListeners();
  }

  /// Einwilligung ändern (Pflicht-Link in den Einstellungen).
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Datenschutz: ${error.message}');
    });
  }

  /// Nach dem Schließen einer Detailseite aufrufen, die in der App geöffnet
  /// wurde (nicht über Mitteilung oder Widget).
  Future<void> onDetailClosed() async {
    final state = _state;
    if (state == null) return;
    final now = DateTime.now();
    await state.countDetailOpen(now);
    if (!enabled || _interstitial == null) return;
    if (!shouldShowInterstitial(
      now: now,
      firstLaunch: state.firstLaunch,
      opensToday: state.detailOpensToday(now),
      shownToday: state.interstitialShownToday(now),
    )) {
      return;
    }
    await state.markInterstitialShown(now);
    await _interstitial!.show();
    _interstitial = null;
  }

  void _loadInterstitial() {
    final unit = _interstitialUnitId;
    if (unit == null || !enabled) return;
    InterstitialAd.load(
      adUnitId: unit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
          );
          _interstitial = ad;
        },
        onAdFailedToLoad: (e) => debugPrint('Vollbild-Anzeige: ${e.message}'),
      ),
    );
  }

  void _onStateChanged() {
    final state = _state;
    if (state != null && state.onboardingDone && !_started && _supported) {
      unawaited(_start());
    }
    if (state?.isPro ?? false) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _state?.removeListener(_onStateChanged);
    _interstitial?.dispose();
    super.dispose();
  }
}

/// Regel für die Vollbild-Anzeige: nicht am ersten Tag, erst ab der dritten
/// geöffneten Redewendung des Tages und höchstens einmal pro Tag.
bool shouldShowInterstitial({
  required DateTime now,
  required DateTime firstLaunch,
  required int opensToday,
  required bool shownToday,
}) {
  final firstDay = DateTime(
    firstLaunch.year,
    firstLaunch.month,
    firstLaunch.day,
  );
  final today = DateTime(now.year, now.month, now.day);
  if (!today.isAfter(firstDay)) return false;
  if (shownToday) return false;
  return opensToday >= 3;
}
