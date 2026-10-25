import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Shows a banner ad. Collapses to zero height if the ad fails to load,
/// so no empty whitespace is ever shown to the user.
///
/// Pass the real ad unit ID at build time:
///   flutter build apk --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY
/// Without that define, the Google-provided test ID is used automatically.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  // Resolved at compile time: real ID via --dart-define, otherwise test ID.
  static const String _adUnitId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // test ID
  );

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (adsEnabled) _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: BannerAdWidget._adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
