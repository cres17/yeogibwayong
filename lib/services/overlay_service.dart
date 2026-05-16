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
    if (_lastShownAt != null &&
        now.difference(_lastShownAt!).inMinutes < _cooldownMinutes) {
      return;
    }

    final granted = await isPermissionGranted();
    if (!granted) return;

    await FlutterOverlayWindow.showOverlay(
      height: 240,
      width: 240,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: '여기봐용',
      overlayContent: '펫이 나타났어요!',
    );

    final prefs = await SharedPreferences.getInstance();
    final resolvedDisplaySeconds =
        (displaySeconds ?? prefs.getInt(PrefKeys.overlayDurationSeconds) ?? 5)
            .clamp(3, 30);

    await FlutterOverlayWindow.shareData({
      OverlayDataKeys.petImagePath: petImagePath,
      OverlayDataKeys.triggerType: triggerType,
      OverlayDataKeys.packageName: packageName ?? '',
      OverlayDataKeys.displaySeconds: resolvedDisplaySeconds,
    });

    _lastShownAt = now;
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();
}
