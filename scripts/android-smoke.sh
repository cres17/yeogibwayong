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
flutter drive --no-dds --no-start-paused --timeout=240 --screenshot=docs/verification/runtime/driver-screens --driver=test_driver/integration_test.dart --target=integration_test/app_smoke_test.dart -d emulator-5554 > docs/verification/runtime/integration.log 2>&1
smoke_status=$?
set -e
cat docs/verification/runtime/integration.log
adb logcat -d > docs/verification/runtime/logcat.txt
adb exec-out screencap -p > docs/verification/runtime/screen.png
# Also launch the optimized app: integration tests exercise a debug build.
# Capture package-replacement receivers too: they can fail before the Activity.
adb logcat -c
adb install -r build/app/outputs/flutter-apk/app-x86_64-release.apk
sleep 2
adb shell am start -S -W -n com.cres.yeogibwayong/.MainActivity
sleep 8
release_pid=$(adb shell pidof com.cres.yeogibwayong | tr -d '\r')
printf '%s\n' "$release_pid" > docs/verification/runtime/release-pid.txt
if [ -z "$release_pid" ]; then exit 1; fi
adb logcat -d > docs/verification/runtime/release-logcat.txt
adb logcat -d --pid="$release_pid" > docs/verification/runtime/release-app-logcat.txt
adb exec-out screencap -p > docs/verification/runtime/release-screen.png
# A receiver may crash one PID and WorkManager may create another; inspect the
# entire crash buffer and verify the Activity is actually resumed as well.
adb logcat -d -b crash > docs/verification/runtime/release-crash.txt
adb shell dumpsys activity activities > docs/verification/runtime/release-activity.txt
if grep -q 'Process: com.cres.yeogibwayong' docs/verification/runtime/release-crash.txt; then
  cat docs/verification/runtime/release-crash.txt
  exit 1
fi
if ! grep -E 'mResumedActivity:.*com.cres.yeogibwayong|topResumedActivity=.*com.cres.yeogibwayong' docs/verification/runtime/release-activity.txt; then
  exit 1
fi
if grep -E 'FATAL EXCEPTION|Startup failed:|Unhandled Exception|Could not resolve main entrypoint' docs/verification/runtime/release-app-logcat.txt; then
  exit 1
fi

exit "$smoke_status"
