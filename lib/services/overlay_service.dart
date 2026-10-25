import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class OverlayService {
  OverlayService._();
  static final OverlayService instance = OverlayService._();

  DateTime? _lastShownAt;

  // Minimum 10 minutes between overlay shows
  static const _cooldownMinutes = 10;

  Future<bool> isPermissionGranted() =>
      FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestPermission() => FlutterOverlayWindow.requestPermission();

  Future<void> show({
    required String petImagePath,
    required String triggerType,
    String? packageName,
    int? displaySeconds,
  }) async {
    final now = DateTime.now();
    if (triggerType == TriggerType.usageExceeded &&
        _lastShownAt != null &&
        now.difference(_lastShownAt!).inMinutes < _cooldownMinutes) {
      return;
    }

    final granted = await isPermissionGranted();
    if (!granted) return;
    if (await FlutterOverlayWindow.isActive()) return;

    final prefs = await SharedPreferences.getInstance();
    // The Android plugin accepts physical pixels; the Flutter card uses dp.
    final ratio = (prefs.getDouble(PrefKeys.displayPixelRatio) ?? 1).clamp(
      0.5,
      8.0,
    );
    final pixels = (240 * ratio).round();
    await FlutterOverlayWindow.showOverlay(
      height: pixels,
      width: pixels,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: '여기봐용',
      overlayContent: '펫이 나타났어요!',
    );

    final resolvedDisplaySeconds =
        (displaySeconds ?? prefs.getInt(PrefKeys.overlayDurationSeconds) ?? 5)
            .clamp(3, 30);

    await FlutterOverlayWindow.shareData({
      OverlayDataKeys.petImagePath: petImagePath,
      OverlayDataKeys.triggerType: triggerType,
      OverlayDataKeys.packageName: packageName ?? '',
      OverlayDataKeys.displaySeconds: resolvedDisplaySeconds,
    }).timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        // A detached/paused overlay engine may never acknowledge a platform message.
        // Its lifecycle fallback still loads the active photo from local storage.
        debugPrint('Overlay payload acknowledgement timed out');
        return null;
      },
    );

    _lastShownAt = now;
  }

  Future<void> close() async {
    // Plugin 0.5.0 does not reply to closeOverlay when it is already inactive.
    if (!await FlutterOverlayWindow.isActive()) return;
    await FlutterOverlayWindow.closeOverlay().timeout(
      const Duration(seconds: 2),
      onTimeout: () => false,
    );
  }
}
