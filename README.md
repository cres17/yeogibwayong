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

정해 둔 앱의 사용 시간을 넘기면 반려동물 사진이 화면 위에 나타나는 Android 앱입니다. 앱을 강제로 차단하는 대신 잠시 시선을 돌릴 수 있도록 만들었습니다. 사용 통계, 집중 타이머, 반려동물 등록 기능을 제공하며 한국어와 영어를 지원합니다.

## 구성

![여기봐용 서비스 구성](docs/assets/readme/architecture.svg)

Flutter 화면과 백그라운드 감시 서비스를 분리했습니다. 화면 상태는 Provider로 관리하고, 사용량과 반려동물 정보는 SQLite에 저장합니다. 다른 앱 위에 표시되는 오버레이는 `lib/overlay/overlay_main.dart`에서 따로 시작합니다.

| 위치 | 내용 |
|---|---|
| `lib/screens/` | 홈, 통계, 타이머, 반려동물, 설정과 권한 안내 |
| `lib/providers/` | 사용량, 타이머, 반려동물, 설정 상태 |
| `lib/services/` | 감시, 사용량 조회, 오버레이와 알림 |
| `lib/data/` | SQLite 스키마와 repository |
| Android `MainActivity.kt` | 제조사 설정 화면으로 이동하는 MethodChannel |

## 사용 시간 감시

<p><img src="https://img.shields.io/badge/MAIN%20FEATURE-7E9B53?style=flat-square" alt="MAIN 기능" height="20"></p>

포그라운드 서비스가 5초마다 UsageStats에서 오늘의 앱별 사용량을 읽습니다. 검사 중이면 다음 검사를 건너뛰고, 설정은 매번 `reload()`해 앱에서 바꾼 값을 반영합니다.

조회한 사용량을 `usage_log_daily`에 저장한 뒤 감시 대상과 하루 한도를 확인합니다. 한도를 넘겼고 같은 앱의 마지막 표시 후 10분이 지났을 때 오버레이를 띄웁니다. 한 번의 검사에서는 하나만 표시합니다.

활성 반려동물 사진이 없으면 표시하지 않습니다. 오버레이의 유지 시간은 설정값을 3~30초로 제한하며, 표시 기록은 `popup_history`에 남깁니다. 화면에는 `usageUpdate` 이벤트를 보내 통계를 갱신합니다.

제조사 배터리 정책에 의해 서비스가 종료될 수 있습니다. WorkManager는 15분 주기의 작업에서 감시 설정을 확인하고 서비스 복구를 시도합니다. 삼성·샤오미 기기에서는 자동 실행 및 배터리 예외 설정 화면으로 이동하는 안내도 제공합니다.

## 집중 타이머

<p><img src="https://img.shields.io/badge/SUB%20FEATURE-B9C9A2?style=flat-square" alt="SUB 기능" height="20"></p>

시작과 재개 시점에 종료 시각을 정하고, 매초 현재 시각과의 차이로 남은 시간을 구합니다. 일시정지하면 남은 시간만 보관합니다. 타이머 tick을 계속 차감하는 방식에서 생길 수 있는 누적 오차를 피하려는 구현입니다.

완료하면 `timer_sessions`에 기록하고 반려동물 오버레이를 표시합니다. 취소한 세션은 `was_interrupted = 1`로 저장합니다. 앱이 백그라운드로 이동하면 완료 알림을 예약하고, 다시 돌아오면 예약을 취소합니다.

## 반려동물과 기록

<p><img src="https://img.shields.io/badge/SUB%20FEATURE-B9C9A2?style=flat-square" alt="SUB 기능" height="20"></p>

갤러리 사진을 정사각형으로 잘라 앱 저장소에 복사합니다. `pets.image_path`에 경로를 저장하고 활성 반려동물을 선택하면 사용 한도 알림과 타이머 완료에 같은 사진을 사용합니다. 홈에서는 가속도 센서 값에 따라 사진이 기울어집니다.

| 테이블 | 기록 |
|---|---|
| `pets` | 이름, 사진 경로, 활성 여부 |
| `monitored_apps` | 감시 앱과 하루 한도 |
| `usage_log_daily` | 앱·날짜별 사용 시간 |
| `popup_history` | 오버레이 표시 시각과 사유 |
| `timer_sessions` | 집중 세션과 중단 여부 |

테이블 간 외래 키 제약은 없습니다. `package_name`과 `pet_id` 값으로 연결하며, 사용 시간은 `(package_name, date_string)` 유니크 키로 하루 한 행을 갱신합니다.

## 권한

사용량 조회에는 사용 기록 접근, 오버레이에는 다른 앱 위에 표시 권한이 필요합니다. 포그라운드 서비스와 타이머는 알림 권한을 사용합니다. 앱의 권한 안내 화면에서 시스템 설정으로 이동할 수 있습니다.

## 기술별 역할

| 기술 | 용도 | 위치 |
|------|------|------|
| Flutter · Provider | `ChangeNotifier`로 타이머 · 반려동물 · 사용량 · 설정 상태를 분리. 홈의 반려동물은 `sensors_plus` 가속도 값에 따라 기울어짐 | `lib/providers/` |
| SQLite (sqflite) | `pets`, `monitored_apps`, `usage_log_daily`, `popup_history`, `timer_sessions` 다섯 테이블 | `lib/data/database/database_service.dart` |
| UsageStats API | `usage_stats` 패키지로 오늘 앱별 포그라운드 시간을 읽고, 감시할 앱은 `device_apps`로 설치 목록에서 선택 | `lib/services/usage_tracking_service.dart` |
| flutter_overlay_window | 등록한 반려동물 사진을 다른 앱 위에 정해진 시간 동안 표시. 오버레이는 별도 진입점에서 그림 | `lib/overlay/overlay_main.dart` |
| image_picker · image_cropper | 갤러리 사진을 고르고 정사각형으로 잘라 앱 저장소에 복사, 경로는 `pets.image_path`에 저장 | `lib/screens/pet_management/pet_management_screen.dart` |
| fl_chart | 통계 화면의 일간 · 주간 막대 차트(`usage_log_daily`) | `lib/screens/statistics/statistics_screen.dart` |
| flutter_local_notifications · Google AdMob | 상시 알림과 로컬 알림. 배너는 `BannerAdWidget` | `lib/services/notification_service.dart`, `lib/widgets/banner_ad_widget.dart` |

### 감시 서비스와 설정

flutter_background_service가 사용 시간 감시를 이어가고 WorkManager가 서비스 복구를 보조합니다. SharedPreferences는 사용자 설정, package_info_plus는 설정 화면의 버전·빌드 번호 표시에 사용합니다. 타이머 기록·사용량·팝업 이력은 SQLite에 남기므로 설정값과 활동 기록의 저장 위치가 다릅니다.

## 실행

Android 기기와 Dart SDK `^3.11.5`가 필요합니다.

```bash
flutter pub get
flutter run
flutter analyze
```

릴리스 광고 단위는 빌드 시 전달합니다. 지정하지 않으면 Google 테스트 광고 ID를 사용합니다.

```bash
flutter build apk --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY
```
