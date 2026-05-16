import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class SettingsRepository {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> getNotificationEnabled() async =>
      (await _prefs).getBool(PrefKeys.notificationEnabled) ?? true;

  Future<void> setNotificationEnabled(bool value) async =>
      (await _prefs).setBool(PrefKeys.notificationEnabled, value);

  Future<bool> getSoundEnabled() async =>
      (await _prefs).getBool(PrefKeys.soundEnabled) ?? true;

  Future<void> setSoundEnabled(bool value) async =>
      (await _prefs).setBool(PrefKeys.soundEnabled, value);

  Future<bool> getVibrationEnabled() async =>
      (await _prefs).getBool(PrefKeys.vibrationEnabled) ?? true;

  Future<void> setVibrationEnabled(bool value) async =>
      (await _prefs).setBool(PrefKeys.vibrationEnabled, value);

  Future<int> getOverlayDurationSeconds() async =>
      (await _prefs).getInt(PrefKeys.overlayDurationSeconds) ?? 5;

  Future<void> setOverlayDurationSeconds(int value) async =>
      (await _prefs).setInt(PrefKeys.overlayDurationSeconds, value);

  Future<bool> getOnboardingDone() async =>
      (await _prefs).getBool(PrefKeys.onboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) async =>
      (await _prefs).setBool(PrefKeys.onboardingDone, value);

  Future<bool> getUsageTrackingEnabled() async =>
      (await _prefs).getBool(PrefKeys.usageTrackingEnabled) ?? false;

  Future<void> setUsageTrackingEnabled(bool value) async =>
      (await _prefs).setBool(PrefKeys.usageTrackingEnabled, value);

  Future<int> getDailyResetHour() async =>
      (await _prefs).getInt(PrefKeys.dailyResetHour) ?? 0;

  Future<void> setDailyResetHour(int hour) async =>
      (await _prefs).setInt(PrefKeys.dailyResetHour, hour);

  Future<int?> getSelectedPetId() async =>
      (await _prefs).getInt(PrefKeys.selectedPetId);

  Future<void> setSelectedPetId(int id) async =>
      (await _prefs).setInt(PrefKeys.selectedPetId, id);
}
