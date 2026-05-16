import 'package:flutter/services.dart';

/// Detects OEM brand and opens the manufacturer-specific autostart / battery
/// settings screen that Samsung, Xiaomi, and other aggressive battery-killers
/// hide behind non-standard intents.
///
/// On stock Android (Pixel, AOSP) there is no autostart screen — this service
/// returns [OemBrand.standard] and [canOpenAutostartSettings] returns false.
class OemSettingsService {
  OemSettingsService._();
  static final OemSettingsService instance = OemSettingsService._();

  static const _channel = MethodChannel('com.cres.yeogibwayong/oem_settings');

  OemBrand? _cachedBrand;

  /// Detects the device OEM brand (cached after first call).
  Future<OemBrand> detectBrand() async {
    if (_cachedBrand != null) return _cachedBrand!;
    try {
      final brand =
          await _channel.invokeMethod<String>('getBrand') ?? '';
      _cachedBrand = _parseBrand(brand.toLowerCase());
    } catch (_) {
      _cachedBrand = OemBrand.standard;
    }
    return _cachedBrand!;
  }

  /// Returns true only for OEMs that have a launchable autostart screen.
  Future<bool> canOpenAutostartSettings() async {
    final brand = await detectBrand();
    return brand == OemBrand.samsung || brand == OemBrand.xiaomi;
  }

  /// Opens the OEM-specific autostart / power-management settings.
  /// Does nothing on standard Android.
  Future<void> openAutostartSettings() async {
    final brand = await detectBrand();
    try {
      switch (brand) {
        case OemBrand.samsung:
          await _channel.invokeMethod('openSamsungAutostart');
        case OemBrand.xiaomi:
          await _channel.invokeMethod('openMiuiAutostart');
        case OemBrand.standard:
          break;
      }
    } catch (_) {
      // Silently fail — OEM intents are non-standard and may not exist on
      // every firmware version of the same brand.
    }
  }

  static OemBrand _parseBrand(String brand) {
    if (brand.contains('samsung')) {
      return OemBrand.samsung;
    }
    if (brand.contains('xiaomi') ||
        brand.contains('redmi') ||
        brand.contains('poco')) {
      return OemBrand.xiaomi;
    }
    return OemBrand.standard;
  }
}

enum OemBrand {
  samsung,
  xiaomi,
  standard,
}
