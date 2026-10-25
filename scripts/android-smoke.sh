#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/verification/runtime
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell appops set com.cres.yeogibwayong GET_USAGE_STATS allow
adb shell appops set com.cres.yeogibwayong SYSTEM_ALERT_WINDOW allow
adb shell pm grant com.cres.yeogibwayong android.permission.POST_NOTIFICATIONS
adb logcat -c
# The integration runner exercises real SQLite, platform channels and overlay.
set +e
flutter test integration_test/app_smoke_test.dart -d emulator-5554 > docs/verification/runtime/integration.log 2>&1
smoke_status=$?
set -e
cat docs/verification/runtime/integration.log
adb logcat -d > docs/verification/runtime/logcat.txt
adb exec-out screencap -p > docs/verification/runtime/screen.png
if [ "$smoke_status" -ne 0 ]; then exit "$smoke_status"; fi
# Also launch the optimized app: integration tests exercise a debug build.
adb install -r build/app/outputs/flutter-apk/app-x86_64-release.apk
adb shell am force-stop com.cres.yeogibwayong
adb logcat -c
adb shell am start -W -n com.cres.yeogibwayong/.MainActivity
sleep 8
adb shell pidof com.cres.yeogibwayong > docs/verification/runtime/release-pid.txt
adb logcat -d > docs/verification/runtime/release-logcat.txt
adb exec-out screencap -p > docs/verification/runtime/release-home.png
if grep -E 'FATAL EXCEPTION|Startup failed:|Unhandled Exception' docs/verification/runtime/release-logcat.txt; then
  exit 1
fi
