// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '여기봐용';

  @override
  String get next => '다음';

  @override
  String get skip => '건너뛰기';

  @override
  String get done => '완료';

  @override
  String get allow => '허용하기';

  @override
  String get allowed => '허용됨';

  @override
  String get notAllowed => '허용 안 됨';

  @override
  String get requestPermission => '권한 요청';

  @override
  String get goToSettings => '설정으로 이동';

  @override
  String get onboardingWelcomeTitle => '여기봐용에 오신 것을 환영해요!';

  @override
  String get onboardingWelcomeDesc =>
      '앱 사용 시간이 초과되거나 타이머가 끝나면\n펫 캐릭터가 등장해 부드럽게 알려드려요.\n\n시작하기 전에 몇 가지 권한이 필요해요.';

  @override
  String get onboardingStart => '시작하기';

  @override
  String get permNotificationTitle => '알림 권한';

  @override
  String get permNotificationDesc => '타이머가 끝나거나 앱 사용 시간이 초과될 때\n알림으로 알려드려요.';

  @override
  String get permOverlayTitle => '다른 앱 위에 표시';

  @override
  String get permOverlayDesc =>
      '펫 캐릭터를 다른 앱 위에 표시하려면\n이 권한이 필요해요.\n\n설정 화면에서 \'여기봐용\'을 찾아 허용해 주세요.';

  @override
  String get permUsageTitle => '앱 사용량 접근';

  @override
  String get permUsageDesc =>
      '어떤 앱을 얼마나 사용했는지 확인하기 위해\n이 권한이 필요해요.\n\n설정 화면에서 \'여기봐용\'을 찾아 허용해 주세요.';

  @override
  String get permBatteryTitle => '배터리 최적화 제외';

  @override
  String get permBatteryDesc =>
      '백그라운드에서도 계속 작동하려면\n배터리 최적화에서 제외해야 해요.\n\n이 권한을 허용하지 않으면 앱이 꺼진 후\n펫이 등장하지 않을 수 있어요.';

  @override
  String permStepOf(int current, int total) {
    return '$current / $total';
  }

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionNotification => '알림';

  @override
  String get settingsNotification => '알림';

  @override
  String get settingsSound => '소리';

  @override
  String get settingsVibration => '진동';

  @override
  String get settingsSectionOverlay => '오버레이';

  @override
  String get settingsOverlayDuration => '오버레이 표시 시간';

  @override
  String settingsOverlayDurationValue(int seconds) {
    return '$seconds초';
  }

  @override
  String get settingsSectionUsage => '앱 사용 감시';

  @override
  String get settingsUsageTracking => '사용량 추적';

  @override
  String get settingsUsageTrackingDesc => 'UsageStats 권한 필요';

  @override
  String get settingsSectionPermissions => '권한 상태';

  @override
  String get settingsPermNotification => '알림';

  @override
  String get settingsPermOverlay => '다른 앱 위에 표시';

  @override
  String get settingsPermUsage => '앱 사용량 접근';

  @override
  String get settingsPermBattery => '배터리 최적화 제외';

  @override
  String get permGuideWhyTitle => '왜 필요한가요?';

  @override
  String get permGuideHowTitle => '허용 방법';

  @override
  String get overlayDurationPickerTitle => '오버레이 표시 시간';

  @override
  String get oemAutostartTitle => '자동 시작 허용';

  @override
  String get oemAutostartDescSamsung =>
      '삼성 기기에서는 \'기기 관리\' → \'배터리\' → \'앱 전원 관리\'에서 여기봐용을 \'제한 없음\'으로 설정해야 해요.\n\n아래 버튼을 누르면 해당 화면으로 이동해요.';

  @override
  String get oemAutostartDescXiaomi =>
      '샤오미/Redmi 기기에서는 \'보안\' → \'권한\' → \'자동 시작\'에서 여기봐용을 활성화해야 해요.\n\n아래 버튼을 누르면 해당 화면으로 이동해요.';

  @override
  String get oemAutostartButton => '자동 시작 설정 열기';

  @override
  String get settingsOemAutostart => '자동 시작 설정';

  @override
  String get settingsOemAutostartDesc => '백그라운드 서비스가 강제 종료되는 경우 설정하세요';

  @override
  String get settingsSectionAbout => '앱 정보';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsPrivacyPolicy => '개인정보처리방침';

  @override
  String get settingsOpenSourceLicenses => '오픈소스 라이선스';
}
