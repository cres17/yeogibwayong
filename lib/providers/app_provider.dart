import 'package:flutter/foundation.dart';

import '../data/repositories/settings_repository.dart';

/// Top-level app state: onboarding completion, permission statuses.
/// Lightweight — heavy domain state lives in the domain-specific providers.
class AppProvider extends ChangeNotifier {
  final SettingsRepository _repo;

  AppProvider(this._repo);

  bool _onboardingDone = false;
  bool _initialized = false;

  bool get onboardingDone => _onboardingDone;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    _onboardingDone = await _repo.getOnboardingDone();
    _initialized = true;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    await _repo.setOnboardingDone(true);
  }
}
