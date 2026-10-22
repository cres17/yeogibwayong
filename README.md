<div align="center">

# 여기봐용

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logoColor=white&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat&logoColor=white&logo=dart)
![Provider](https://img.shields.io/badge/Provider-355A85?style=flat&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=flat&logoColor=white&logo=sqlite)
![SharedPreferences](https://img.shields.io/badge/SharedPreferences-4D5868?style=flat&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=flat&logoColor=white&logo=kotlin)
![Android](https://img.shields.io/badge/Android-3DDC84?style=flat&logoColor=black&logo=android)
![UsageStats API](https://img.shields.io/badge/UsageStats%20API-3DDC84?style=flat&logoColor=black)
![flutter_background_service](https://img.shields.io/badge/flutter__background__service-2F6B4F?style=flat&logoColor=white)
![WorkManager](https://img.shields.io/badge/WorkManager-4D5868?style=flat&logoColor=white)
![flutter_overlay_window](https://img.shields.io/badge/flutter__overlay__window-8A6420?style=flat&logoColor=white)
![fl_chart](https://img.shields.io/badge/fl__chart-0175C2?style=flat&logoColor=white)
![Google AdMob](https://img.shields.io/badge/Google%20AdMob-EA4335?style=flat&logoColor=white&logo=googleadmob)

</div>

내 반려동물 사진이 휴대폰 화면 위에 나타나 "그만 보고 여기 봐"라고 알려 주는 스크린 타임 관리 앱입니다. 다른 앱을 강제로 막는 대신, 사용자가 정한 앱의 하루 사용 시간이 한도를 넘으면 반려동물 캐릭터가 다른 앱 위에 잠깐 떠오릅니다. 반려동물과 함께하는 집중 타이머와 앱별 사용 통계도 제공합니다. Android 전용이며 한국어 · 영어를 지원합니다.

| 화면 | 기능 |
|------|------|
| 홈 | 오늘의 사용 시간 요약, 기기를 기울이면 움직이는 반려동물 |
| 타이머 | 집중 시간을 정해 반려동물과 함께 세션 진행, 기록 저장 |
| 통계 | 앱별 사용 시간의 일간 · 주간 막대 차트 |
| 반려동물 | 사진을 골라 잘라서 캐릭터 등록, 활성 반려동물 선택 |
| 앱 선택 · 설정 | 감시할 앱과 하루 한도, 오버레이 표시 시간, 권한 안내 |

## 전체 아키텍처

<p align="center">
  <img src="docs/assets/readme/architecture.svg" alt="여기봐용 전체 아키텍처" width="100%">
</p>

| 흐름 | 설명 |
|------|------|
| 감시 | Background Service가 5초마다 UsageStats로 오늘의 앱별 사용 시간을 읽어 `usage_log_daily`에 기록 |
| 알림 | 감시 중인 앱이 `daily_limit_seconds`를 넘으면 활성 반려동물 오버레이를 띄우고 `popup_history`에 남김 (같은 앱은 10분 간격) |
| 화면 갱신 | Background Service가 `usageUpdate` 이벤트를 보내면 앱의 Provider가 통계를 갱신 |
| 복구 | 제조사 배터리 정책으로 서비스가 멈추는 경우를 대비해 WorkManager가 15분마다 서비스를 다시 시작 |

```text
lib/
├── screens/       홈 · 타이머 · 통계 · 반려동물 · 앱 선택 · 권한 안내 · 설정
├── providers/     app · timer · pet · usage · settings
├── services/      background · usage_tracking · overlay · notification · oem_settings
├── data/          SQLite 스키마, 모델, repository
├── overlay/       오버레이 창 진입점 (overlay_main.dart)
└── l10n/          한국어 · 영어 문구
android/.../MainActivity.kt   제조사 자동 실행 설정 화면을 여는 MethodChannel
```

## 각 기술 설명

### Flutter · Provider

`lib/providers`의 `ChangeNotifier`들이 타이머 · 반려동물 · 사용량 · 설정 상태를 나눠 관리합니다. 타이머는 종료 시각을 저장해 두고 1초마다 남은 시간을 다시 계산하므로, 일시정지 · 재개 후에도 시간이 어긋나지 않습니다. 홈의 반려동물은 `sensors_plus`의 가속도 센서 값으로 기울기에 따라 움직입니다.

### SQLite (sqflite) · SharedPreferences

`data/database/database_service.dart`가 `pets`, `monitored_apps`, `usage_log_daily`, `popup_history`, `timer_sessions` 다섯 테이블을 만듭니다. 사용 기록은 `(package_name, date_string)` 유니크 키로 하루 한 행씩 갱신합니다. 사용량 추적 여부 · 오버레이 표시 시간 같은 설정은 SharedPreferences에 두고, 백그라운드 isolate는 매 검사마다 `reload()`로 다시 읽어 앱에서 바꾼 설정을 서비스 재시작 없이 반영합니다.

### UsageStats API

`usage_stats` 패키지로 Android `UsageStatsManager`의 오늘 앱별 포그라운드 시간을 읽습니다. 사용 기록 접근 권한이 필요하며, 권한 안내 화면에서 시스템 설정으로 이동시킵니다. 감시할 앱 목록은 `device_apps`로 설치된 앱을 불러와 고릅니다.

### flutter_background_service

앱이 꺼져 있어도 동작하는 Android foreground service입니다. 상시 알림을 띄운 채 5초마다 사용량을 조회 · 저장하고 한도를 검사합니다. 한 번의 검사에서는 오버레이를 하나만 띄워 겹치지 않게 합니다.

### flutter_overlay_window

다른 앱 위에 표시 권한을 받아, 등록한 반려동물 사진을 화면 위에 정해진 시간 동안 띄웁니다. 오버레이는 `overlay/overlay_main.dart`의 별도 진입점에서 그려집니다.

### WorkManager

`main.dart`에서 15분 주기 작업을 등록해, 시스템이 Background Service를 종료한 경우 다시 시작합니다.

### Kotlin MethodChannel

`MainActivity.kt`가 `com.cres.yeogibwayong/oem_settings` 채널로 기기 제조사를 알려 주고, 삼성 · 샤오미의 자동 실행 · 배터리 예외 설정 화면을 엽니다. 제조사별 백그라운드 제한을 사용자가 풀 수 있게 안내하는 용도입니다.

### image_picker · image_cropper

반려동물을 등록할 때 갤러리 사진을 고르고 정사각형으로 잘라 앱 저장소에 복사합니다. 경로는 `pets.image_path`에 저장됩니다.

### fl_chart

통계 화면에서 `usage_log_daily`를 일간 · 주간 막대 차트로 그립니다.

### flutter_local_notifications · Google AdMob

foreground service 상시 알림과 로컬 알림을 표시합니다. 광고는 `BannerAdWidget`이 `--dart-define=ADMOB_BANNER_ID`로 받은 배너 단위를 쓰고, 값이 없으면 Google 테스트 광고 ID를 씁니다.
