import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';
import '../services/background_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo;

  SettingsProvider(this._repo);

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
    if (_usageTrackingEnabled) {
      await startUsageBackgroundService();
    }
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
    _usageTrackingEnabled = value;
    notifyListeners();
    await _repo.setUsageTrackingEnabled(value);
    if (value) {
      await startUsageBackgroundService();
    } else {
      await stopUsageBackgroundService();
    }
  }

  Future<void> setDailyResetHour(int hour) async {
    _dailyResetHour = hour;
    notifyListeners();
    await _repo.setDailyResetHour(hour);
  }
}
