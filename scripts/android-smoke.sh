#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Android smoke failed at line $LINENO: $BASH_COMMAND" >&2' ERR
mkdir -p docs/verification/runtime
# Flutter drive can briefly interrupt the adb transport while disconnecting.
# Retry reads only; installs and app assertions must still fail normally.
adb_read() {
  local attempt
  for attempt in 1 2 3; do
    if timeout 20 adb "$@"; then return 0; fi
    echo "Retrying adb read ($attempt/3): $*" >&2
    sleep 2
  done
  return 1
}
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell appops set com.cres.yeogibwayong GET_USAGE_STATS allow
adb shell appops set com.cres.yeogibwayong SYSTEM_ALERT_WINDOW allow
adb shell pm grant com.cres.yeogibwayong android.permission.POST_NOTIFICATIONS
adb logcat -c
# The integration runner exercises real SQLite, platform channels and overlay.
set +e
flutter drive --no-dds --no-start-paused --keep-app-running --timeout=240 --screenshot=docs/verification/runtime/driver-screens --driver=test_driver/integration_test.dart --target=integration_test/app_smoke_test.dart -d emulator-5554 > docs/verification/runtime/integration.log 2>&1
smoke_status=$?
set -e
cat docs/verification/runtime/integration.log
adb_read logcat -d > docs/verification/runtime/logcat.txt || echo 'Debug logcat unavailable' >&2
adb_read exec-out screencap -p > docs/verification/runtime/screen.png || echo 'Debug screenshot unavailable' >&2
# Also launch the optimized app with the same saved timer/notification data.
# --keep-app-running prevents Flutter drive from uninstalling the test app.
# Capture package-replacement receivers too: they can fail before the Activity.
timeout 30 adb wait-for-device
adb logcat -c
adb install -r build/app/outputs/flutter-apk/app-x86_64-release.apk
sleep 2
adb shell am start -S -W -n com.cres.yeogibwayong/.MainActivity
sleep 8
release_pid=$(adb shell pidof com.cres.yeogibwayong | tr -d '\r')
printf '%s\n' "$release_pid" > docs/verification/runtime/release-pid.txt
if [ -z "$release_pid" ]; then exit 1; fi
adb_read logcat -d > docs/verification/runtime/release-logcat.txt
adb_read logcat -d --pid="$release_pid" > docs/verification/runtime/release-app-logcat.txt
adb_read exec-out screencap -p > docs/verification/runtime/release-screen.png || echo 'Release screenshot unavailable' >&2
# A receiver may crash one PID and WorkManager may create another; inspect the
# entire crash buffer and verify the Activity is actually resumed as well.
adb_read logcat -d -b crash > docs/verification/runtime/release-crash.txt
adb_read shell dumpsys activity activities > docs/verification/runtime/release-activity.txt
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
