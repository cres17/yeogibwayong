<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" alt="yeogibwayong 앱 아이콘" width="124">
</p>

<h1 align="center">여기봐용</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat&amp;logoColor=white&amp;logo=flutter" alt="Flutter" height="20">
  <img src="https://img.shields.io/badge/Provider-355A85?style=flat&amp;logoColor=white" alt="Provider" height="20">
  <img src="https://img.shields.io/badge/SQLite-003B57?style=flat&amp;logoColor=white&amp;logo=sqlite" alt="SQLite" height="20">
  <br>
  <img src="https://img.shields.io/badge/Kotlin-7F52FF?style=flat&amp;logoColor=white&amp;logo=kotlin" alt="Kotlin" height="20">
  <img src="https://img.shields.io/badge/Android-3DDC84?style=flat&amp;logoColor=black&amp;logo=android" alt="Android" height="20">
  <img src="https://img.shields.io/badge/UsageStats%20API-3DDC84?style=flat&amp;logoColor=black" alt="UsageStats API" height="20">
  <br>
  <img src="https://img.shields.io/badge/flutter__background__service-2F6B4F?style=flat&amp;logoColor=white" alt="flutter_background_service" height="20">
  <img src="https://img.shields.io/badge/WorkManager-4D5868?style=flat&amp;logoColor=white" alt="WorkManager" height="20">
  <img src="https://img.shields.io/badge/flutter__overlay__window-8A6420?style=flat&amp;logoColor=white" alt="flutter_overlay_window" height="20">
</p>

정해 둔 앱의 사용 시간을 넘기면 반려동물 사진이 화면 위에 나타나는 Android 앱입니다. 앱을 강제로 차단하는 대신 잠시 시선을 돌릴 수 있도록 만들었습니다. 사용 통계, 집중 타이머, 반려동물 등록 기능을 제공하며 주요 사용 화면은 한국어이며, 한국어·영어 번역 리소스를 포함합니다.

## 구성

<p align="center">
  <img src="docs/assets/readme/architecture.svg" alt="여기봐용 서비스 구성" width="1120">
</p>

Flutter 화면과 백그라운드 감시 서비스를 분리했습니다. 화면 상태는 Provider로 관리하고, 사용량과 반려동물 정보는 SQLite에 저장합니다. 다른 앱 위에 표시되는 오버레이는 `lib/overlay/overlay_main.dart`에서 따로 시작합니다.

<div align="center">

| 위치 | 내용 |
|:---:|:---:|
| `lib/screens/` | 홈, 통계, 타이머, 반려동물, 설정과 권한 안내 |
| `lib/providers/` | 사용량, 타이머, 반려동물, 설정 상태 |
| `lib/services/` | 감시, 사용량 조회, 오버레이와 알림 |
| `lib/data/` | SQLite 스키마와 repository |
| Android `MainActivity.kt` | 제조사 설정 화면으로 이동하는 MethodChannel |

</div>

## 사용 시간 감시

포그라운드 서비스가 5초마다 UsageStats 이벤트에서 오늘의 앱별 사용량을 계산합니다. 화면 꺼짐·잠금 시 사용 구간을 닫고, 날짜 경계를 넘은 구간은 오늘에 해당하는 시간만 합산합니다. 검사 중이면 다음 검사를 건너뛰고, 설정은 매번 `reload()`해 앱에서 바꾼 값을 반영합니다.

조회한 사용량을 `usage_log_daily`에 하루 단위 트랜잭션으로 저장한 뒤 감시 대상과 하루 한도를 확인합니다. 현재 전면에 있는 앱이 한도를 넘겼고 같은 앱의 마지막 표시 후 10분이 지났을 때 오버레이를 띄웁니다. 한 번의 검사에서는 하나만 표시합니다. 표시 이력을 조회하므로 서비스가 재시작돼도 10분 간격을 유지합니다.

활성 반려동물 사진이 없으면 표시하지 않습니다. 오버레이의 유지 시간은 설정값을 3~30초로 제한하며, 표시 기록은 `popup_history`에 남깁니다. 화면에는 `usageUpdate` 이벤트를 보내 통계를 갱신합니다.

제조사 배터리 정책에 의해 서비스가 종료될 수 있습니다. WorkManager는 15분 주기의 작업에서 감시 설정을 확인하고 서비스 복구를 시도합니다. 삼성·샤오미 기기에서는 자동 실행 및 배터리 예외 설정 화면으로 이동하는 안내도 제공합니다.

## 집중 타이머


시작과 재개 시점에 종료 시각을 정하고, 매초 현재 시각과의 차이로 남은 시간을 구합니다. 일시정지하면 남은 시간만 보관합니다. 타이머 tick을 계속 차감하는 방식에서 생길 수 있는 누적 오차를 피하려는 구현입니다.

완료하면 `timer_sessions`에 기록하고 반려동물 오버레이를 표시합니다. 취소한 세션은 `was_interrupted = 1`로 저장합니다. 시작·재개할 때 완료 알림을 예약하고, 일시정지·취소하면 예약을 취소합니다. 실행 상태는 `active_timer`에 저장되어 앱 프로세스가 종료돼도 다음 실행 시 남은 시간 또는 완료 상태를 복구합니다. 완료 기록과 상태 변경은 한 트랜잭션으로 저장합니다. 정확한 알람 특별 권한을 요구하지 않는 예약 방식이므로 절전 중 알림이 늦어질 수 있습니다. 홈의 집중 타이머 카드로 다시 열 수 있습니다.

## 반려동물과 기록


갤러리 사진을 정사각형으로 잘라 앱 저장소에 복사합니다. `pets.image_path`에 경로를 저장하고 활성 반려동물을 선택하면 사용 한도 알림과 타이머 완료에 같은 사진을 사용합니다. 홈에서는 가속도 센서 값에 따라 사진이 기울어집니다.

<div align="center">

| 테이블 | 기록 |
|:---:|:---:|
| `pets` | 이름, 사진 경로, 활성 여부 |
| `monitored_apps` | 감시 앱과 하루 한도 |
| `usage_log_daily` | 앱·날짜별 사용 시간 |
| `popup_history` | 오버레이 표시 시각과 사유 |
| `timer_sessions` | 집중 세션과 중단 여부 |
| `active_timer` | 복구할 실행·일시정지·완료 타이머 한 개 |

</div>

테이블 간 외래 키 제약은 없습니다. `package_name`과 `pet_id` 값으로 연결하며, 사용 시간은 `(package_name, date_string)` 유니크 키로 하루 한 행을 갱신합니다.

## 권한

사용량 조회에는 사용 기록 접근, 오버레이에는 다른 앱 위에 표시 권한이 필요합니다. 포그라운드 서비스와 타이머는 알림 권한을 사용합니다. 앱의 권한 안내 화면에서 시스템 설정으로 이동할 수 있습니다.

## 기술별 역할

<div align="center">

| 기술 | 용도 | 위치 |
|:---:|:---:|:---:|
| Flutter · Provider | `ChangeNotifier`로 타이머 · 반려동물 · 사용량 · 설정 상태를 분리. 홈의 반려동물은 `sensors_plus` 가속도 값에 따라 기울어짐 | `lib/providers/` |
| SQLite (sqflite) | `pets`, `monitored_apps`, `usage_log_daily`, `popup_history`, `timer_sessions`, `active_timer` 여섯 테이블 | `lib/data/database/database_service.dart` |
| UsageStats API | `usage_stats` 패키지로 오늘 앱별 포그라운드 시간을 읽고, 감시할 앱은 Kotlin MethodChannel로 실행 가능한 앱 목록에서 선택 | `lib/services/usage_tracking_service.dart` |
| flutter_overlay_window | 등록한 반려동물 사진을 다른 앱 위에 정해진 시간 동안 표시. 오버레이는 별도 진입점에서 그림 | `lib/overlay/overlay_main.dart` |
| image_picker · image_cropper | 갤러리 사진을 고르고 정사각형으로 잘라 앱 저장소에 복사, 경로는 `pets.image_path`에 저장 | `lib/screens/pet_management/pet_management_screen.dart` |
| fl_chart | 통계 화면의 일간 · 주간 막대 차트(`usage_log_daily`) | `lib/screens/statistics/statistics_screen.dart` |
| flutter_local_notifications · Google AdMob | 상시 알림과 로컬 알림. 배너는 `BannerAdWidget` | `lib/services/notification_service.dart`, `lib/widgets/banner_ad_widget.dart` |

</div>

### 감시 서비스와 설정

flutter_background_service가 사용 시간 감시를 이어가고 WorkManager가 서비스 복구를 보조합니다. SharedPreferences는 사용자 설정, package_info_plus는 설정 화면의 버전·빌드 번호 표시에 사용합니다. 타이머 기록·사용량·팝업 이력은 SQLite에 남기므로 설정값과 활동 기록의 저장 위치가 다릅니다.

## 실행

Android 기기, Flutter 3.44.6 (Dart 3.12.2), JDK 21, Android SDK 36으로 검증합니다. Dart 최소 조건은 `^3.11.5`입니다.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

기본 빌드는 광고가 꺼져 있으며 광고 SDK 초기화·요청을 하지 않습니다. 광고 기능을 별도로 켤 경우 `ENABLE_ADS=true`와 배너 ID를 전달합니다. AdMob App ID는 AndroidManifest의 테스트 값을 교체해야 합니다. 스토어 배포용 서명은 `android/key.properties.example`을 참고하세요. 키가 없으면 테스트용 debug 키로 서명됩니다.

```bash
flutter build apk --debug
# 광고를 켜는 별도 빌드
flutter build apk --dart-define=ENABLE_ADS=true --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY
```


## 처음 사용하기

1. APK를 Android 기기에 설치하고 앱을 실행합니다. 권한은 나중에 설정할 수 있습니다.
2. **제한** 탭에서 앱을 선택하고 하루 제한 시간을 저장합니다.
3. **설정 → 권한**에서 사용 기록 접근과 다른 앱 위에 표시를 허용합니다.
4. 홈의 **쉬는 중** 버튼을 눌러 감시를 켭니다. 권한 부족·시작 실패는 화면에 안내됩니다.
5. **놀이터**에서 사진을 등록하고 우측 상단 **팝업 미리보기**로 확인합니다.
6. 홈의 **집중 타이머**에서 시간을 선택합니다. 일시정지·재개·취소와 재실행 복구를 지원합니다.

감시는 사용자가 켠 경우에만 실행합니다. 삭제한 대표 펫은 남은 펫으로 자동 교체됩니다. 모든 기록은 기기에 저장되며 별도 계정이나 서버가 필요하지 않습니다.

## 검증

- `flutter analyze`와 `flutter test`로 상태 전이·날짜 경계·권한 실패·작은 화면/가로 화면을 검사합니다.
- `.github/workflows/android.yml`은 분석, 단위/위젯 테스트, debug APK와 Android 35 에뮬레이터 통합 테스트를 실행합니다.
- `scripts/android-smoke.sh`는 개발용 에뮬레이터에 앱을 설치하고 사용 기록·오버레이·알림 권한을 부여합니다. 개인 기기의 권한 설정을 바꾸므로 테스트 전용 기기에서 실행하세요.
- [검증 기록과 남은 실기기 확인](docs/verification/2026-10-25.md)

사용량은 한 시점의 전면 앱을 기준으로 집계합니다. 분할 화면·PIP는 Android 시스템의 통계와 차이가 있을 수 있습니다. WorkManager 복구는 운영체제 정책에 따른 최선의 시도이며 강제 종료·제조사 절전 정책을 우회하지 않습니다. `specialUse` 서비스의 스토어 심사 통과나 삼성·샤오미 실기기 장시간 동작은 별도 검증이 필요합니다.
