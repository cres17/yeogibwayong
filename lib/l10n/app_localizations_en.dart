// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Yeogi Bwayong';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get allow => 'Allow';

  @override
  String get allowed => 'Allowed';

  @override
  String get notAllowed => 'Not Allowed';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Yeogi Bwayong!';

  @override
  String get onboardingWelcomeDesc =>
      'When your app usage limit is reached or a timer runs out,\na pet character gently appears to remind you.\n\nWe need a few permissions before we start.';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get permNotificationTitle => 'Notifications';

  @override
  String get permNotificationDesc =>
      'We\'ll send you a notification when a timer finishes\nor when your app usage time is exceeded.';

  @override
  String get permOverlayTitle => 'Display Over Other Apps';

  @override
  String get permOverlayDesc =>
      'This permission lets the pet character appear on top of other apps.\n\nIn Settings, find \'Yeogi Bwayong\' and enable it.';

  @override
  String get permUsageTitle => 'App Usage Access';

  @override
  String get permUsageDesc =>
      'This permission lets us track how long you use specific apps.\n\nIn Settings, find \'Yeogi Bwayong\' and enable it.';

  @override
  String get permBatteryTitle => 'Battery Optimization';

  @override
  String get permBatteryDesc =>
      'To keep running in the background, we need to be excluded from battery optimization.\n\nWithout this, the pet may not appear after you leave the app.';

  @override
  String permStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotification => 'Notifications';

  @override
  String get settingsNotification => 'Notifications';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsSectionOverlay => 'Overlay';

  @override
  String get settingsOverlayDuration => 'Overlay Display Duration';

  @override
  String settingsOverlayDurationValue(int seconds) {
    return '${seconds}s';
  }

  @override
  String get settingsSectionUsage => 'App Usage Monitor';

  @override
  String get settingsUsageTracking => 'Usage Tracking';

  @override
  String get settingsUsageTrackingDesc =>
      'Requires App Usage Access permission';

  @override
  String get settingsSectionPermissions => 'Permission Status';

  @override
  String get settingsPermNotification => 'Notifications';

  @override
  String get settingsPermOverlay => 'Display Over Other Apps';

  @override
  String get settingsPermUsage => 'App Usage Access';

  @override
  String get settingsPermBattery => 'Battery Optimization';

  @override
  String get permGuideWhyTitle => 'Why is this needed?';

  @override
  String get permGuideHowTitle => 'How to allow';

  @override
  String get overlayDurationPickerTitle => 'Overlay Duration';

  @override
  String get oemAutostartTitle => 'Allow Auto-Start';

  @override
  String get oemAutostartDescSamsung =>
      'On Samsung devices, go to Device Care → Battery → App Power Management and set Yeogi Bwayong to \'Unrestricted\'.\n\nTap the button below to open that screen.';

  @override
  String get oemAutostartDescXiaomi =>
      'On Xiaomi/Redmi devices, go to Security → Permissions → Autostart and enable Yeogi Bwayong.\n\nTap the button below to open that screen.';

  @override
  String get oemAutostartButton => 'Open Autostart Settings';

  @override
  String get settingsOemAutostart => 'Autostart Settings';

  @override
  String get settingsOemAutostartDesc =>
      'Configure if the background service keeps getting killed';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsOpenSourceLicenses => 'Open-Source Licenses';
}
