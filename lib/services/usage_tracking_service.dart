import 'package:usage_stats/usage_stats.dart';

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

  /// Returns the package name of the app currently in the foreground,
  /// or null if it cannot be determined.
  /// Uses the last MOVE_TO_FOREGROUND event (eventType == 1) within the
  /// past 10 seconds to detect real-time foreground changes.
  Future<String?> getForegroundApp() async {
    try {
      final now = DateTime.now();
      final tenSecondsAgo = now.subtract(const Duration(seconds: 10));

      final events = await UsageStats.queryEvents(tenSecondsAgo, now);
      if (events.isEmpty) return null;

      // Walk backwards to find the most recent MOVE_TO_FOREGROUND event.
      for (final event in events.reversed) {
        // eventType 1 == MOVE_TO_FOREGROUND
        if (event.eventType == '1') {
          final pkg = event.packageName;
          if (pkg != null && pkg.isNotEmpty && !isSystemPackage(pkg)) {
            return pkg;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns total foreground seconds for [packageName] today.
  /// "Today" is defined relative to [dailyResetHour] (0–23, default midnight).
  Future<int> getTodayUsageSeconds(
    String packageName, {
    int dailyResetHour = 0,
  }) async {
    try {
      final now = DateTime.now();
      final resetToday = DateTime(now.year, now.month, now.day, dailyResetHour);
      // If we haven't yet passed today's reset time, roll back to yesterday's.
      final start = now.isBefore(resetToday)
          ? resetToday.subtract(const Duration(days: 1))
          : resetToday;

      final stats = await UsageStats.queryAndAggregateUsageStats(start, now);

      final stat = stats[packageName];
      if (stat == null) return 0;

      final ms = int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0;
      return ms ~/ 1000;
    } catch (_) {
      return 0;
    }
  }

  /// Returns usage seconds for every non-system app active today.
  Future<Map<String, int>> getAllTodayUsage({int dailyResetHour = 0}) async {
    try {
      final now = DateTime.now();
      final resetToday = DateTime(now.year, now.month, now.day, dailyResetHour);
      final start = now.isBefore(resetToday)
          ? resetToday.subtract(const Duration(days: 1))
          : resetToday;

      final stats = await UsageStats.queryAndAggregateUsageStats(start, now);

      final result = <String, int>{};
      for (final entry in stats.entries) {
        final pkg = entry.key;
        if (isSystemPackage(pkg)) continue;
        final ms = int.tryParse(entry.value.totalTimeInForeground ?? '0') ?? 0;
        if (ms > 0) result[pkg] = ms ~/ 1000;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

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
