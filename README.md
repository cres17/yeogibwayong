# 여기봐용

타이머, 반려동물 캐릭터, 앱 사용 통계를 묶은 Flutter 집중 습관 앱입니다. 다른 앱을 강제로 차단하기보다 알림과 화면 위 캐릭터로 사용 시간을 돌아보게 합니다.

## 주요 기능

- 반려동물 테마의 집중 타이머와 세션 기록
- Android 앱 사용량 조회와 통계
- 다른 앱 위에 표시하는 캐릭터 오버레이
- 로컬 알림과 백그라운드 서비스
- 반려동물 관리, 온보딩, 권한 안내, 설정
- 한국어·영어 화면 문구
- AdMob 배너 연동

## 기술 스택

Flutter/Dart, Provider, SQLite(sqflite), shared_preferences를 사용합니다. 사용량 조회는 usage_stats, 오버레이는 flutter_overlay_window, 백그라운드 처리는 flutter_background_service와 workmanager, 통계 화면은 fl_chart에 연결됩니다.

## 실행 환경

- [pubspec.yaml](pubspec.yaml)의 Dart `^3.11.5`를 지원하는 Flutter SDK
- Android Studio/Android SDK와 Android 기기 또는 에뮬레이터
- 사용 기록 접근·다른 앱 위에 표시·알림 등 기능별 권한

현재 저장소에는 Android 프로젝트가 포함되어 있습니다. iOS 앱 프로젝트와 동일한 사용량 추적·오버레이 구현은 제공하지 않습니다.

## 로컬 실행

```bash
git clone https://github.com/cres17/yeogibwayong.git
cd yeogibwayong
flutter pub get
flutter run
```

앱의 권한 안내에 따라 시스템 설정에서 사용 기록 접근과 다른 앱 위에 표시를 허용합니다. 일부 Android 제조사의 배터리 제한 때문에 백그라운드 동작에는 추가 설정이 필요할 수 있습니다. 실제 사용량·오버레이·알림 동작은 Android 실기기에서 확인하세요.

## 광고와 배포 설정

[BannerAdWidget](lib/widgets/banner_ad_widget.dart)은 `ADMOB_BANNER_ID`를 컴파일 시 읽습니다. 값을 전달하지 않으면 Google 테스트 광고 ID를 사용합니다.

본인 광고 단위를 사용하는 빌드 예시:

```bash
flutter build apk --release \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-본인광고단위
```

예시 값을 실제 배너 단위 ID로 바꾸세요. 배너 ID만 지정한다고 출시 설정이 모두 완료되는 것은 아닙니다. 앱 ID·서명·권한·정책 관련 항목은 [Play Store 체크리스트](PLAY_STORE_CHECKLIST.md)를 함께 확인합니다.

## 구조

| 경로 | 역할 |
|---|---|
| [lib/providers](lib/providers) | 타이머·반려동물·사용량·설정 상태 |
| [lib/data](lib/data) | SQLite 모델·저장소 |
| [lib/services](lib/services) | 사용량 조회·백그라운드·알림·오버레이 |
| [lib/screens](lib/screens) | 타이머·통계·권한 안내 등 화면 |
| [lib/overlay](lib/overlay) | 오버레이 진입점 |
| [lib/l10n](lib/l10n) | 한국어·영어 번역 |
| [assets/images/pets](assets/images/pets) | 반려동물 이미지 |

## 개발 확인

```bash
flutter analyze
flutter test
```

정적 검사와 widget 테스트 외에 기기별 권한 허용·거부, 백그라운드 유지, 알림 표시, 오버레이 종료를 따로 확인해야 합니다.
