import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';
import '../services/background_service.dart';
import '../services/usage_tracking_service.dart';
import '../services/overlay_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo;

  SettingsProvider(
    this._repo, {
    Future<bool> Function()? hasUsagePermission,
    Future<bool> Function()? hasOverlayPermission,
    Future<void> Function()? startService,
    Future<void> Function()? stopService,
  }) : _hasUsagePermission =
           hasUsagePermission ?? UsageTrackingService.instance.hasPermission,
       _hasOverlayPermission =
           hasOverlayPermission ?? OverlayService.instance.isPermissionGranted,
       _startService = startService ?? startUsageBackgroundService,
       _stopService = stopService ?? stopUsageBackgroundService;
  final Future<bool> Function() _hasUsagePermission;
  final Future<bool> Function() _hasOverlayPermission;
  final Future<void> Function() _startService;
  final Future<void> Function() _stopService;
  bool _trackingBusy = false;
  String? _trackingError;
  bool get trackingBusy => _trackingBusy;
  String? get trackingError => _trackingError;

  bool _notificationEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _overlayDurationSeconds = 5;
  bool _usageTrackingEnabled = false;
  int _dailyResetHour = 0;

  bool get notificationEnabled => _notificationEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  int get overlayDurationSeconds => _overlayDurationSeconds;
  bool get usageTrackingEnabled => _usageTrackingEnabled;
  int get dailyResetHour => _dailyResetHour;

  Future<void> load() async {
    _notificationEnabled = await _repo.getNotificationEnabled();
    _soundEnabled = await _repo.getSoundEnabled();
    _vibrationEnabled = await _repo.getVibrationEnabled();
    _overlayDurationSeconds = await _repo.getOverlayDurationSeconds();
    _usageTrackingEnabled = await _repo.getUsageTrackingEnabled();
    _dailyResetHour = await _repo.getDailyResetHour();
    notifyListeners();
    if (_usageTrackingEnabled) await setUsageTrackingEnabled(true);
  }

  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
    notifyListeners();
    await _repo.setNotificationEnabled(value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _repo.setSoundEnabled(value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    await _repo.setVibrationEnabled(value);
  }

  Future<void> setOverlayDurationSeconds(int value) async {
    _overlayDurationSeconds = value.clamp(3, 30);
    notifyListeners();
    await _repo.setOverlayDurationSeconds(_overlayDurationSeconds);
  }

  Future<void> setUsageTrackingEnabled(bool value) async {
    if (_trackingBusy) return;
    _trackingBusy = true;
    _trackingError = null;
    notifyListeners();
    final previous = _usageTrackingEnabled;
    try {
      if (value &&
          (!await _hasUsagePermission() || !await _hasOverlayPermission())) {
        await _repo.setUsageTrackingEnabled(false);
        _usageTrackingEnabled = false;
        await _stopService();
        _trackingError = '설정에서 앱 사용 기록과 다른 앱 위에 표시 권한을 허용해주세요.';
        return;
      }
      // Persist before starting so the service sees the new opt-in.
      await _repo.setUsageTrackingEnabled(value);
      if (value) {
        await _startService();
      } else {
        await _stopService();
      }
      _usageTrackingEnabled = value;
    } catch (_) {
      _usageTrackingEnabled = value ? false : previous;
      try {
        await _repo.setUsageTrackingEnabled(_usageTrackingEnabled);
      } catch (_) {}
      _trackingError = '감시 상태를 변경하지 못했어요. 권한을 확인하고 다시 시도해주세요.';
    } finally {
      _trackingBusy = false;
      notifyListeners();
    }
  }

  Future<void> setDailyResetHour(int hour) async {
    _dailyResetHour = hour;
    notifyListeners();
    await _repo.setDailyResetHour(hour);
  }
}
