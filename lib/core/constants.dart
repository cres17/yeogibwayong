// Isolate 경계를 넘는 모든 키는 여기서 관리 — 오타 방지용 상수
class PrefKeys {
  PrefKeys._();
  static const selectedPetId = 'selected_pet_id';
  static const notificationEnabled = 'notification_enabled';
  static const soundEnabled = 'sound_enabled';
  static const vibrationEnabled = 'vibration_enabled';
  static const overlayDurationSeconds = 'overlay_duration_seconds';
  static const onboardingDone = 'onboarding_done';
  static const usageTrackingEnabled = 'usage_tracking_enabled';
  static const dailyResetHour = 'daily_reset_hour';
}

class ServiceEvents {
  ServiceEvents._();
  static const usageUpdate = 'usageUpdate';
  static const timerComplete = 'timerComplete';
  static const showOverlay = 'showOverlay';
  static const serviceStarted = 'serviceStarted';
  static const stopService = 'stopService';
}

class OverlayDataKeys {
  OverlayDataKeys._();
  static const petImagePath = 'petImagePath';
  static const triggerType = 'triggerType';
  static const packageName = 'packageName';
  static const displaySeconds = 'displaySeconds';
}

class TriggerType {
  TriggerType._();
  static const timerComplete = 'timer_complete';
  static const usageExceeded = 'usage_exceeded';
}

class WorkManagerTasks {
  WorkManagerTasks._();
  static const backgroundServiceRecovery = 'backgroundServiceRecovery';
}
