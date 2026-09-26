/// IDs für Store und Werbung. Vor der Veröffentlichung von 1.1 prüfen!
library;

/// Einmaliger Kauf „Redewendix Pro“ (nicht verbrauchbar). Muss in App Store
/// Connect und in der Play Console mit genau dieser ID angelegt sein.
const String kProProductId = 'bq.p526.rede.pro';

// --- Werbung (AdMob) ------------------------------------------------------
//
// In Debug-Builds laufen immer Googles Test-Anzeigen. In Release-Builds
// werden nur Anzeigen geladen, wenn hier echte IDs eingetragen sind – sonst
// bleibt die App werbefrei (kein Risiko, mit Test-IDs zu veröffentlichen).
// Die App-IDs stehen zusätzlich in AndroidManifest.xml und Info.plist.

const String kAdBannerAndroid = '';
const String kAdBannerIos = '';
const String kAdInterstitialAndroid = '';
const String kAdInterstitialIos = '';

/// Googles Test-IDs (https://developers.google.com/admob/flutter/test-ads).
const String kTestBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
const String kTestBannerIos = 'ca-app-pub-3940256099942544/2435281174';
const String kTestInterstitialAndroid =
    'ca-app-pub-3940256099942544/1033173712';
const String kTestInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
