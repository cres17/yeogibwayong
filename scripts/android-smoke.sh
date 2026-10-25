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
exit "$smoke_status"
