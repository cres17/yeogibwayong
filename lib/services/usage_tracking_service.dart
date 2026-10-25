import 'package:usage_stats/usage_stats.dart';
import '../core/utils/usage_day.dart';
import '../core/utils/usage_events.dart';

class UsageTrackingService {
  UsageTrackingService._();
  static final UsageTrackingService instance = UsageTrackingService._();

  // Exact infrastructure packages only. Chrome (com.android.chrome) and other
  // launchable preinstalled apps must remain selectable and count toward limits.
  static const _systemPackages = {
    'android',
    'com.android.systemui',
    'com.android.settings',
    'com.android.launcher',
    'com.android.launcher3',
    'com.google.android.apps.nexuslauncher',
    'com.cres.yeogibwayong',
    'com.google.android.gms',
    'com.google.android.gsf',
    'com.google.android.packageinstaller',
    'com.google.android.permissioncontroller',
    'com.google.android.providers.media.module',
    'com.google.android.webview',
  };

  static bool isSystemPackage(String packageName) =>
      _systemPackages.contains(packageName);

  Future<UsageSnapshot> snapshot({int dailyResetHour = 0}) async {
    final now = DateTime.now();
    final start = UsageDay.start(now, dailyResetHour);
    // Include prior events to account for sessions crossing the reset boundary.
    final events = await UsageStats.queryEvents(
      start.subtract(const Duration(days: 1)),
      now,
    );
    final parsed = <AppUsageEvent>[];
    for (final event in events) {
      final timestamp = int.tryParse(event.timeStamp ?? '');
      final type = int.tryParse(event.eventType ?? '');
      if (timestamp == null || type == null) continue;
      parsed.add(
        AppUsageEvent(
          DateTime.fromMillisecondsSinceEpoch(timestamp),
          type,
          event.packageName,
        ),
      );
    }
    final result = summarizeUsage(parsed, start, now);
    return UsageSnapshot({
      for (final entry in result.seconds.entries)
        if (!isSystemPackage(entry.key) && entry.key != 'com.cres.yeogibwayong')
          entry.key: entry.value,
    }, result.foregroundPackage);
  }

  Future<Map<String, int>> getAllTodayUsage({int dailyResetHour = 0}) async =>
      (await snapshot(dailyResetHour: dailyResetHour)).seconds;

  /// Checks whether the PACKAGE_USAGE_STATS permission is granted.
  Future<bool> hasPermission() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the Usage Access settings screen so the user can grant the
  /// PACKAGE_USAGE_STATS permission manually.
  Future<void> requestPermission() async {
    await UsageStats.grantUsagePermission();
  }
}
