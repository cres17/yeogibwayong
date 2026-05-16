import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// Application name
  ///
  /// In ko, this message translates to:
  /// **'여기봐용'**
  String get appName;

  /// Next button
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// Skip button
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// Done button
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// Allow permission button
  ///
  /// In ko, this message translates to:
  /// **'허용하기'**
  String get allow;

  /// Permission is granted
  ///
  /// In ko, this message translates to:
  /// **'허용됨'**
  String get allowed;

  /// Permission is not granted
  ///
  /// In ko, this message translates to:
  /// **'허용 안 됨'**
  String get notAllowed;

  /// Re-request permission button
  ///
  /// In ko, this message translates to:
  /// **'권한 요청'**
  String get requestPermission;

  /// Open system settings button
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get goToSettings;

  /// Onboarding welcome title
  ///
  /// In ko, this message translates to:
  /// **'여기봐용에 오신 것을 환영해요!'**
  String get onboardingWelcomeTitle;

  /// Onboarding welcome description
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 시간이 초과되거나 타이머가 끝나면\n펫 캐릭터가 등장해 부드럽게 알려드려요.\n\n시작하기 전에 몇 가지 권한이 필요해요.'**
  String get onboardingWelcomeDesc;

  /// Start onboarding button
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get onboardingStart;

  /// Notification permission step title
  ///
  /// In ko, this message translates to:
  /// **'알림 권한'**
  String get permNotificationTitle;

  /// Notification permission description
  ///
  /// In ko, this message translates to:
  /// **'타이머가 끝나거나 앱 사용 시간이 초과될 때\n알림으로 알려드려요.'**
  String get permNotificationDesc;

  /// Overlay permission step title
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 위에 표시'**
  String get permOverlayTitle;

  /// Overlay permission description
  ///
  /// In ko, this message translates to:
  /// **'펫 캐릭터를 다른 앱 위에 표시하려면\n이 권한이 필요해요.\n\n설정 화면에서 \'여기봐용\'을 찾아 허용해 주세요.'**
  String get permOverlayDesc;

  /// Usage stats permission step title
  ///
  /// In ko, this message translates to:
  /// **'앱 사용량 접근'**
  String get permUsageTitle;

  /// Usage stats permission description
  ///
  /// In ko, this message translates to:
  /// **'어떤 앱을 얼마나 사용했는지 확인하기 위해\n이 권한이 필요해요.\n\n설정 화면에서 \'여기봐용\'을 찾아 허용해 주세요.'**
  String get permUsageDesc;

  /// Battery optimization step title
  ///
  /// In ko, this message translates to:
  /// **'배터리 최적화 제외'**
  String get permBatteryTitle;

  /// Battery optimization description
  ///
  /// In ko, this message translates to:
  /// **'백그라운드에서도 계속 작동하려면\n배터리 최적화에서 제외해야 해요.\n\n이 권한을 허용하지 않으면 앱이 꺼진 후\n펫이 등장하지 않을 수 있어요.'**
  String get permBatteryDesc;

  /// Permission step indicator
  ///
  /// In ko, this message translates to:
  /// **'{current} / {total}'**
  String permStepOf(int current, int total);

  /// Settings screen title
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// Notification section header
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsSectionNotification;

  /// Notification toggle label
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotification;

  /// Sound toggle label
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get settingsSound;

  /// Vibration toggle label
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get settingsVibration;

  /// Overlay section header
  ///
  /// In ko, this message translates to:
  /// **'오버레이'**
  String get settingsSectionOverlay;

  /// Overlay duration setting label
  ///
  /// In ko, this message translates to:
  /// **'오버레이 표시 시간'**
  String get settingsOverlayDuration;

  /// Overlay duration value label
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String settingsOverlayDurationValue(int seconds);

  /// Usage tracking section header
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 감시'**
  String get settingsSectionUsage;

  /// Usage tracking toggle label
  ///
  /// In ko, this message translates to:
  /// **'사용량 추적'**
  String get settingsUsageTracking;

  /// Usage tracking description
  ///
  /// In ko, this message translates to:
  /// **'UsageStats 권한 필요'**
  String get settingsUsageTrackingDesc;

  /// Permission status section header
  ///
  /// In ko, this message translates to:
  /// **'권한 상태'**
  String get settingsSectionPermissions;

  /// Notification permission label in settings
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsPermNotification;

  /// Overlay permission label in settings
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 위에 표시'**
  String get settingsPermOverlay;

  /// Usage stats permission label in settings
  ///
  /// In ko, this message translates to:
  /// **'앱 사용량 접근'**
  String get settingsPermUsage;

  /// Battery optimization label in settings
  ///
  /// In ko, this message translates to:
  /// **'배터리 최적화 제외'**
  String get settingsPermBattery;

  /// Permission guide why section title
  ///
  /// In ko, this message translates to:
  /// **'왜 필요한가요?'**
  String get permGuideWhyTitle;

  /// Permission guide how-to section title
  ///
  /// In ko, this message translates to:
  /// **'허용 방법'**
  String get permGuideHowTitle;

  /// Overlay duration picker dialog title
  ///
  /// In ko, this message translates to:
  /// **'오버레이 표시 시간'**
  String get overlayDurationPickerTitle;

  /// OEM autostart onboarding step title
  ///
  /// In ko, this message translates to:
  /// **'자동 시작 허용'**
  String get oemAutostartTitle;

  /// Samsung-specific autostart description
  ///
  /// In ko, this message translates to:
  /// **'삼성 기기에서는 \'기기 관리\' → \'배터리\' → \'앱 전원 관리\'에서 여기봐용을 \'제한 없음\'으로 설정해야 해요.\n\n아래 버튼을 누르면 해당 화면으로 이동해요.'**
  String get oemAutostartDescSamsung;

  /// Xiaomi-specific autostart description
  ///
  /// In ko, this message translates to:
  /// **'샤오미/Redmi 기기에서는 \'보안\' → \'권한\' → \'자동 시작\'에서 여기봐용을 활성화해야 해요.\n\n아래 버튼을 누르면 해당 화면으로 이동해요.'**
  String get oemAutostartDescXiaomi;

  /// Open OEM autostart settings button
  ///
  /// In ko, this message translates to:
  /// **'자동 시작 설정 열기'**
  String get oemAutostartButton;

  /// OEM autostart settings tile label in settings screen
  ///
  /// In ko, this message translates to:
  /// **'자동 시작 설정'**
  String get settingsOemAutostart;

  /// OEM autostart settings tile description
  ///
  /// In ko, this message translates to:
  /// **'백그라운드 서비스가 강제 종료되는 경우 설정하세요'**
  String get settingsOemAutostartDesc;

  /// About section header in settings
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsSectionAbout;

  /// App version label in settings
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settingsVersion;

  /// Privacy policy tile label
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get settingsPrivacyPolicy;

  /// Open-source licenses tile label
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get settingsOpenSourceLicenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
