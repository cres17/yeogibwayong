# 프로젝트 지침서 (CatTimer + PetGuardian 통합)

작성일: 2026-05-14
상태: 코드 작성 전 검토 단계

---

## 1. 프로젝트 정의

### 1.1 컨셉
- **기본 모드(CatTimer)**: 사용자가 수동으로 타이머를 설정하고, 시간 경과 시 고양이/펫 이미지가 화면에 표시됨
- **고도화 모드(PetGuardian)**: 사용자가 특정 앱(인스타, 틱톡 등)을 선택해두면, 누적 사용 시간 도달 시 펫이 자동으로 등장
- **단일 앱으로 통합 개발**: 기본은 타이머, 사용자가 설정에서 앱 감지 모드 활성화 가능

### 1.2 핵심 동작 원칙
- **차단(blocking) 기능 없음**: 사용자의 앱 사용을 강제로 막지 않음
- **펫은 "화면 보호기" 방식으로 등장**: 잠깐 나타나서 알림/시각적 환기만 주고, 자연스럽게 사라지거나 사용자가 닫음
- **사용 시간 제한(앱 잠금)도 없음**: 단순히 펫이 등장하여 사용자 자제를 유도하는 nudge 방식

### 1.3 차별점 (기존 디지털 웰빙 앱 대비)
- 차단 없이 부드러운 행동 유도 (nudge)
- 사용자 맞춤형 펫 이미지로 정서적 애착 형성

---

## 2. 범위 결정 (사용자 확정 사항)

| 항목 | 결정 | 비고 |
|------|------|------|
| 프로젝트 전략 | CatTimer 기반 + PetGuardian 확장 | 단일 통합 앱 |
| 최우선 플랫폼 | **Android 우선** | iOS는 Phase 2 |
| iOS 대응 | 추후 별도 진행 | Windows 개발 환경상 iOS 빌드는 Mac 필요 |
| 차단 정책 | 차단/잠금 없음 | 펫 노출만으로 nudge |
| 화면 표시 | **다른 앱 위 오버레이** | `SYSTEM_ALERT_WINDOW` 권한 필요 |
| 배포 목표 | **Google Play Store 실배포** | 정책 검토 필수 |
| 개발 환경 | Windows + Android | iOS 빌드는 추후 |

---

## 3. MVP(v1.0) 기능 범위

사용자가 선택한 MVP 포함 기능:

1. **기본 타이머 + 펫 팝업** (CatTimer 기능)
2. **특정 앱 감지** (Android `UsageStats` API 기반)
3. **사용 시간 통계 + 설정**
4. **펫 커스터마이징** (사용자 사진 업로드)

MVP에서 **제외**되는 기능 (Phase 2 이후):
- 인터랙티브 미니게임 4종 (밥/물/쓰다듬기/놀아주기)
- iOS 지원
- 카테고리별 제한, 부모 통제 모드
- 클라우드 백업, 소셜 공유

---

## 4. 기술 스택 (확정)

| 항목 | 선택 | 버전 | 비고 |
|------|------|------|------|
| 프레임워크 | Flutter | 3.16+ | |
| 언어 | Dart | 3.0+ | |
| 상태 관리 | Provider | 6.0+ | 단순 구조. 복잡도 증가 시 Riverpod로 마이그레이션 검토 |
| 로컬 DB | sqflite (SQLite) | 2.3+ | 통계 데이터 누적 필요 |
| 간단 설정 저장 | shared_preferences | 2.0+ | 설정값(토글, 선택값) |
| 앱 사용량 추적 | usage_stats | 1.0+ | Android `PACKAGE_USAGE_STATS` 권한 필요 |
| 백그라운드 | workmanager + Foreground Service | 0.5+ | 1초 폴링은 배터리 부담 → 인터벌 조정 필요 |
| 오버레이 표시 | 네이티브 플러그인 또는 `flutter_overlay_window` | 최신 | `SYSTEM_ALERT_WINDOW` 권한 |
| 알림 | flutter_local_notifications | 16.0+ | |
| 이미지 처리 | image_picker, image_cropper | 0.8+ / 5.0+ | 펫 사진 등록 |
| 차트 | fl_chart | 0.64+ | 통계 화면 |
| 권한 처리 | permission_handler | 11.0+ | 다중 권한 일괄 관리 |
| 광고 | google_mobile_ads | 4.0+ | AdMob 배너 광고 |
| 다국어 | flutter_localizations + intl | - | 한국어 우선, 영어 확장 대비 |

> **변경 사항**: 원 설계 문서의 `flutter_linter: ^2.0.0`은 존재하지 않는 패키지. 대신 `flutter_lints: ^3.0.0` 사용.

---

## 5. 아키텍처

### 5.1 패턴
- **MVVM + Provider** (단순함 우선)
- 추후 복잡도 증가 시 Riverpod 또는 Bloc 도입 검토

### 5.2 디렉토리 구조 (확정안)
```
lib/
├── main.dart
├── app.dart                         # MaterialApp 진입점
├── core/
│   ├── constants.dart
│   ├── theme.dart
│   └── utils/
│       ├── time_formatter.dart
│       └── logger.dart
├── data/
│   ├── models/
│   │   ├── timer_model.dart
│   │   ├── app_usage_model.dart
│   │   ├── pet_model.dart
│   │   └── settings_model.dart
│   ├── database/
│   │   └── database_service.dart    # SQLite
│   └── repositories/
│       ├── usage_repository.dart
│       ├── pet_repository.dart
│       └── settings_repository.dart
├── providers/
│   ├── timer_provider.dart
│   ├── usage_provider.dart
│   ├── pet_provider.dart
│   └── settings_provider.dart
├── services/
│   ├── usage_tracking_service.dart  # UsageStats 폴링
│   ├── overlay_service.dart         # 오버레이 표시 (Android 네이티브 브리지)
│   ├── notification_service.dart
│   └── background_service.dart      # Foreground Service
├── screens/
│   ├── home/
│   ├── timer/
│   ├── app_selection/               # 감지 대상 앱 선택
│   ├── pet_management/
│   ├── statistics/
│   ├── settings/
│   └── pet_popup/                   # 펫 등장 화면
├── widgets/
│   └── (공용 위젯)
└── android/                          # 네이티브 코드
    └── app/src/main/
        ├── AndroidManifest.xml
        └── kotlin/
            └── OverlayService.kt    # 오버레이 네이티브 구현
assets/
├── images/pets/                      # 기본 펫 이미지
└── sounds/
```

---

## 6. Android 권한 및 정책 (중요)

### 6.1 필수 권한
```xml
<!-- 사용량 통계 (수동 허용 필요, 일반 권한 아님) -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />

<!-- 다른 앱 위 오버레이 -->
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />

<!-- 백그라운드 서비스 (Foreground Service) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />  <!-- Android 14+ -->

<!-- 배터리 최적화 제외 요청 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

<!-- 알림 (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- 부팅 시 자동 시작 -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- 진동 -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- 이미지 선택 (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### 6.2 권한 처리 전략
- 첫 실행 시 온보딩 화면에서 권한별 안내 → 설정 화면으로 유도
- **PACKAGE_USAGE_STATS**: 일반 런타임 권한이 아니므로 `Settings.ACTION_USAGE_ACCESS_SETTINGS` 인텐트로 이동
- **SYSTEM_ALERT_WINDOW**: Android 6.0+에서 `Settings.ACTION_MANAGE_OVERLAY_PERMISSION` 인텐트
- **배터리 최적화 제외**: `Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

### 6.3 Google Play 정책 리스크 (반드시 검토)
- `SYSTEM_ALERT_WINDOW`, `PACKAGE_USAGE_STATS`, 백그라운드 서비스 사용 시 Play Console에서 **고위험 권한**으로 분류
- 심사 시 다음을 명확히 제출해야 함:
  - 권한 사용 목적의 영상 데모
  - 데이터 안전 섹션(Data safety) 정확한 작성
  - 개인정보처리방침(Privacy Policy) URL
- `FOREGROUND_SERVICE_SPECIAL_USE`는 Android 14+에서 사용 목적 명시 필수
- Family Policy 적용 시(자녀용 앱으로 분류 시) 더 엄격한 심사

---

## 7. 핵심 기술 리스크 및 대응

| 리스크 | 영향 | 대응 |
|--------|------|------|
| `usage_stats` 패키지 유지보수 | 빌드/동작 실패 가능 | pub.dev 최신 상태 확인 후 채택. 필요 시 네이티브 직접 구현 |
| 1초 폴링의 배터리 소모 | 사용자 이탈, OS 강제 종료 | 폴링 주기 5~10초로 조정, 또는 `UsageEvents` API로 이벤트 기반 전환 |
| 백그라운드 작업 OS 종료 | 추적 누락 | Foreground Service + 알림 상시 표시 |
| 오버레이 표시 후 화면 보호기 닫기 인터랙션 | UX 혼란 | 자동 사라짐(예: 5초) + 닫기 버튼 |
| 일부 제조사(샤오미 등) 자동 시작 제한 | 백그라운드 미동작 | 사용자 안내 문서 + `Autostart` 설정 유도 |
| `flutter_overlay_window` 패키지 한계 | Flutter UI 일부 미지원 | 복잡한 UI는 네이티브 View로 구현 |
| 펫 이미지 업로드 시 PII | 개인정보 이슈 | 모든 이미지는 로컬 저장, 외부 전송 없음 명시 |

---

## 8. 데이터 모델 (요약)

### 8.1 SharedPreferences 키
- `selected_pet_id`, `notification_enabled`, `sound_enabled`, `vibration_enabled`, `overlay_duration_seconds`, `onboarding_done`

### 8.2 SQLite 테이블
- `pets` (id, name, type, image_path, is_default, created_at)
- `monitored_apps` (id, package_name, app_name, daily_limit_seconds, is_enabled)
- `usage_log_daily` (id, package_name, date_string, duration_seconds) — UNIQUE(package_name, date_string)
- `usage_log_hourly` (id, package_name, hour_timestamp, duration_seconds)
- `popup_history` (id, trigger_type, package_name, pet_id, shown_at) — 통계용

---

## 9. UI/UX 핵심 화면

1. **온보딩**: 권한 안내 → 권한 부여 → 첫 펫 선택
2. **홈**: 현재 타이머 상태 + 오늘 사용량 요약
3. **타이머 설정**: 분/시간 선택
4. **앱 선택**: 설치된 앱 목록 → 감지할 앱 체크
5. **펫 관리**: 기본 펫 갤러리 + 사용자 사진 업로드 (crop 포함)
6. **통계**: 일/주/월 차트 (fl_chart)
7. **설정**: 권한 상태, 알림/소리/진동, 오버레이 표시 시간
8. **펫 팝업 화면**: 전체화면 또는 오버레이로 표시되는 펫 등장 씬

---

## 10. 개발 단계 (제안)

| 단계 | 내용 | 비고 |
|------|------|------|
| 0 | 환경 셋업, 권한 요청 흐름 PoC | 가장 먼저 권한이 막히면 모두 막힘 |
| 1 | 기본 타이머 + 펫 팝업 (CatTimer 동작) | |
| 2 | SQLite, 통계 누적 | |
| 3 | UsageStats 통합, 앱 선택 화면 | |
| 4 | 오버레이 표시 (네이티브) | 핵심 기술 챌린지 |
| 5 | 펫 커스터마이징 (image_picker/cropper) | |
| 6 | 통계 차트, 설정 화면 | |
| 7 | 온보딩, 권한 안내 UX 다듬기 | |
| 8 | QA, 다양한 기기 테스트 | 샤오미/화웨이 등 |
| 9 | Play Console 등록, 정책 문서 작성, 심사 | |

---

## 11. 추가 결정 사항 (확정)

### 11.1 확정된 항목
| 항목 | 결정 |
|------|------|
| 펫 등장 트리거 | **즉시 등장** (누적 시간 도달 시 사용 도중 오버레이) |
| 오버레이 표시 시간 | **사용자 설정 가능** (권장 범위 3~30초, 기본값 5초) |
| 펫 이미지 공급 | **기본 강아지/고양이 밈 패키지 + 사용자 업로드** |
| 수익화 | **완전 무료 + 하단 배너 광고 (AdMob), 인앱결제 없음** |
| 다국어 | **한국어 MVP, 영어 추후** (i18n 구조는 처음부터 도입) |

---

## 부록: 원 설계 문서 대비 주요 변경 사항

| 원 문서 항목 | 변경 후 | 이유 |
|--------------|---------|------|
| `flutter_linter: ^2.0.0` | `flutter_lints: ^3.0.0` | 패키지 이름 오류 |
| 1초 폴링 | 5~10초 폴링 또는 UsageEvents 기반 | 배터리 소모 |
| 차단/제한 시스템 | 제거 (nudge만) | 사용자 정책 결정 |
| 4종 미니게임 | Phase 2로 이동 | MVP 범위 축소 |
| iOS 동시 지원 | Android 우선, iOS 추후 | 개발 환경(Windows) 및 iOS 기술 제약 |
| Provider 우선 | Provider 유지, 복잡도 증가 시 재검토 | 학습 곡선 |
| 디렉토리 구조 | `data/`, `core/` 계층 추가 | 확장성 |
