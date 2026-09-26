import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;

import '../app_scope.dart';
import '../services/ad_service.dart';

/// Banner unten auf der Seite; mit Pro oder ohne Einwilligung unsichtbar.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loading = false;

  Future<void> _load() async {
    final unit = AdService.bannerUnitId;
    if (_loading || _ad != null || unit == null) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    _ad = BannerAd(
      adUnitId: unit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = AppScope.of(context).ads;
    return ListenableBuilder(
      listenable: ads,
      builder: (context, _) {
        if (!ads.enabled) return const SizedBox.shrink();
        _load();
        final ad = _ad;
        if (ad == null || !_loaded) return const SizedBox.shrink();
        return SafeArea(
          top: false,
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        );
      },
    );
  }
}
