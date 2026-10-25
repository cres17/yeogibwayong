import 'package:usage_stats/usage_stats.dart';
import '../core/utils/usage_day.dart';
import '../core/utils/usage_events.dart';

class UsageTrackingService {
  UsageTrackingService._();
  static final UsageTrackingService instance = UsageTrackingService._();

  // Prefixes considered "system" — filtered from the installed-apps list
  // and from usage queries so they don't pollute monitored-apps data.
  static const _systemPrefixes = ['com.android.', 'android'];

  static const _systemPackages = {
    'com.google.android.gms',
    'com.google.android.gsf',
    'com.google.android.packageinstaller',
    'com.google.android.permissioncontroller',
    'com.google.android.providers.media.module',
    'com.google.android.webview',
  };

  static bool isSystemPackage(String packageName) {
    if (_systemPackages.contains(packageName)) return true;
    for (final prefix in _systemPrefixes) {
      if (packageName.startsWith(prefix)) return true;
    }
    return false;
  }

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
