# Play Store 제출 체크리스트 — 여기봐용

## 1. 릴리스 빌드 준비

### 1-1. 서명 키스토어 생성 (최초 1회)
```powershell
keytool -genkey -v `
  -keystore C:\Users\STORY\upload-keystore.jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias upload `
  -dname "CN=Cres, OU=Dev, O=Cres, L=Seoul, S=Seoul, C=KR"
```

### 1-2. android/key.properties 생성 (VCS에 커밋 금지)
```
storePassword=<KEYSTORE_PW>
keyPassword=<KEY_PW>
keyAlias=upload
storeFile=C:/Users/STORY/upload-keystore.jks
```
> 참고: `android/.gitignore`에 `key.properties`가 이미 등록됨.

### 1-3. AdMob 실제 ID 교체
1. AdMob 콘솔(admob.google.com)에서 앱 등록 → App ID 발급
2. `android/app/src/main/AndroidManifest.xml` 안의
   `com.google.android.gms.ads.APPLICATION_ID` 값을 실제 ID로 교체
3. 배너 광고 유닛 ID 발급 후 릴리스 빌드 시 dart-define으로 주입:
   ```powershell
   flutter build appbundle `
     --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXX/YYYY `
     --release
   ```

### 1-4. 릴리스 빌드 명령
```powershell
flutter build appbundle --release
# 결과물: build/app/outputs/bundle/release/app-release.aab
```

---

## 2. Play Console 등록 항목

### 2-1. 앱 기본 정보
| 항목 | 값 |
|------|----|
| 앱 이름 | 여기봐용 |
| 패키지 ID | com.cres.yeogibwayong |
| 카테고리 | 생산성 (Productivity) |
| 부가 카테고리 | 건강 및 피트니스 (Health & Fitness) |
| 타겟 연령 | 18+ (성인) |
| 콘텐츠 등급 | PEGI 3 / Everyone 예상 |

### 2-2. 스토어 등록정보
- **짧은 설명 (80자 이내)**: 펫 캐릭터가 등장해 앱 과사용을 부드럽게 알려주는 생산성 도우미
- **전체 설명**: 앱 사용 시간 한도 초과 또는 타이머 종료 시, 사용자가 설정한 펫 캐릭터가 화면 위에 잠깐 나타나 부드럽게 알려줍니다. 차단 없는 nudge 방식으로 스마트폰 사용 습관을 개선하세요.
- **스크린샷**: 최소 2장 (홈, 타이머, 오버레이 장면 권장)
- **앱 아이콘**: 512×512 PNG

### 2-3. 개인정보처리방침 URL
- **제출 전 필수**: 영구적으로 접근 가능한 URL에 호스팅
- 권장 호스팅: GitHub Pages, Notion 공개 페이지, 개인 도메인
- `lib/screens/settings/settings_screen.dart` 의 `privacyUrl` 상수도 같은 URL로 업데이트

---

## 3. Data Safety 섹션 작성 가이드

### 수집하는 데이터
| 데이터 유형 | 수집 여부 | 공유 여부 | 처리 방식 |
|-------------|-----------|-----------|-----------|
| 위치 정보 | 미수집 | 미공유 | — |
| 개인 식별 정보 | 미수집 | 미공유 | — |
| 금융 정보 | 미수집 | 미공유 | — |
| 건강 정보 | 미수집 | 미공유 | — |
| 이메일/메시지 | 미수집 | 미공유 | — |
| 사진/동영상 | **로컬 수집** (펫 이미지) | 미공유 | 기기 내 저장만, 외부 전송 없음 |
| 앱 활동 (사용 시간) | **로컬 수집** | **AdMob과 공유** | 광고 ID 목적 |
| 기기 또는 기타 식별자 | **AdMob에 의해 수집** | **Google과 공유** | 광고 개인화 목적 |

### 작성 방법 (Play Console UI)
1. **데이터 수집 여부**: "예, 이 앱은 사용자 데이터를 수집합니다" 선택
2. **데이터 유형 체크**:
   - ✅ 앱 활동 → 앱 상호작용 (사용 패턴 – 로컬만)
   - ✅ 기기 또는 기타 식별자 → 광고 ID (AdMob)
3. **데이터 처리 방식**:
   - 앱 활동: 기기에서만 처리, 공유 안 함, 암호화 (SQLite)
   - 광고 ID: Google AdMob과 공유, 광고 목적
4. **보안**: 전송 중 데이터 암호화 여부 → 광고 요청은 HTTPS

---

## 4. 고위험 권한 선언 영상

Play Console 심사 시 아래 두 권한에 대해 **사용 목적 증명 영상** 제출 필요:

### PACKAGE_USAGE_STATS
- **목적**: 사용자가 선택한 앱의 일일 사용 시간을 추적하여 설정 한도 초과 시 펫 알림 제공
- **영상에 포함할 내용**:
  1. 앱 설치 후 최초 실행 → 권한 요청 화면 (설명 문구 포함)
  2. 사용량 설정 화면에서 앱 선택 + 시간 한도 설정
  3. 한도 초과 시 펫 오버레이 등장
  4. 통계 화면에서 사용량 확인

### SYSTEM_ALERT_WINDOW
- **목적**: 펫 캐릭터를 다른 앱 위에 오버레이로 표시 (nudge 알림)
- **영상에 포함할 내용**:
  1. 권한 요청 → 설정 화면으로 이동 → 권한 허용
  2. 다른 앱(예: 브라우저) 사용 중 타이머 완료 → 펫 오버레이 등장
  3. 5초 후 자동 소멸 또는 닫기 버튼으로 닫기

---

## 5. 제출 전 최종 확인

- [ ] `flutter build appbundle --release` 성공 (ProGuard 오류 없음)
- [ ] 릴리스 APK/AAB에서 광고 표시 정상 동작 확인 (실기기)
- [ ] 개인정보처리방침 URL 영구 접근 가능
- [ ] AdMob App ID + Banner Ad Unit ID 실제 ID로 교체
- [ ] `android/key.properties` 로컬에만 존재 (VCS에 없음)
- [ ] Data Safety 섹션 작성 완료
- [ ] 권한 사용 목적 영상 준비
- [ ] 앱 아이콘 + 스크린샷 준비
- [ ] 타겟 연령 18+ 확인 (COPPA 미적용 → AdMob 제한 없음)
- [ ] 콘텐츠 등급 설문 작성
