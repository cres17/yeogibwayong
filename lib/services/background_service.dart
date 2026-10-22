import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'usage_tracking_service.dart';

// Returns the singleton service handle (used to check isRunning / startService).
FlutterBackgroundService getBackgroundService() => FlutterBackgroundService();

Future<void> startUsageBackgroundService() async {
  final service = getBackgroundService();
  final running = await service.isRunning();
  if (!running) await service.startService();
}

Future<void> stopUsageBackgroundService() async {
  final service = getBackgroundService();
  final running = await service.isRunning();
  if (running) service.invoke(ServiceEvents.stopService);
}

// ─── Isolate 2 entry point ────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  // Required so that platform channels work in this isolate.
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Show the persistent foreground notification (Android 8+ requirement).
  // flutter_background_service sets the initial title/content via configure(),
  // but we refresh it here so the channel is definitely initialised.
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    await _showForegroundNotification();
  }

  // Open DB independently — each isolate keeps its own connection.
  final dbPath = await getDatabasesPath();
  final db = await openDatabase(p.join(dbPath, 'yeogibwayong.db'));

  Timer? pollingTimer;

  // Main isolate can send stopService to shut us down cleanly.
  service.on(ServiceEvents.stopService).listen((_) async {
    pollingTimer?.cancel();
    await db.close();
    await service.stopSelf();
  });

  // 5-second polling loop.
  // _BgState carries mutable state across ticks without globals.
  final state = _BgState();
  pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    // A slow tick (UsageStats query, DB) must not overlap the next one,
    // otherwise both pass the cooldown check and show duplicate overlays.
    if (state.checking) return;
    state.checking = true;
    try {
      await _checkUsage(service, db, state);
    } finally {
      state.checking = false;
    }
  });
}

Future<void> _showForegroundNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  await plugin.show(
    1001,
    '여기봐용 실행 중',
    '앱 사용 시간을 모니터링하고 있습니다.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'foreground_service',
        '백그라운드 서비스',
        channelDescription: '앱 사용량 추적 서비스',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

// Mutable state shared across polling ticks within Isolate 2.
class _BgState {
  // True while a polling tick is running.
  bool checking = false;

  // packageName → last overlay-shown time (in-isolate cooldown)
  final Map<String, DateTime> lastShown = {};
  static const cooldownMinutes = 10;

  bool canShow(String packageName) {
    final last = lastShown[packageName];
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= cooldownMinutes;
  }

  void markShown(String packageName) {
    lastShown[packageName] = DateTime.now();
  }
}

Future<void> _checkUsage(
  ServiceInstance service,
  Database db,
  _BgState state,
) async {
  try {
    final tracker = UsageTrackingService.instance;

    // Skip if permission not granted (avoids SecurityException).
    if (!await tracker.hasPermission()) return;

    final prefs = await SharedPreferences.getInstance();
    // SharedPreferences caches values per isolate. Settings changed in the
    // main isolate are only visible here after reloading from the platform.
    await prefs.reload();
    if (prefs.getBool(PrefKeys.usageTrackingEnabled) != true) return;

    final dailyResetHour = prefs.getInt(PrefKeys.dailyResetHour) ?? 0;
    final overlayDurationSeconds =
        (prefs.getInt(PrefKeys.overlayDurationSeconds) ?? 5).clamp(3, 30);
    final today = _todayString(dailyResetHour);

    // Fetch all today's usage from UsageStats API.
    final allUsage = await tracker.getAllTodayUsage(
      dailyResetHour: dailyResetHour,
    );

    // Upsert each non-zero entry into usage_log_daily.
    for (final entry in allUsage.entries) {
      await db.rawInsert(
        '''INSERT OR REPLACE INTO usage_log_daily
           (package_name, date_string, duration_seconds)
           VALUES (?, ?, ?)''',
        [entry.key, today, entry.value],
      );
    }

    // Notify main isolate with the full map so UsageProvider can update UI.
    final updatePayload = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
    };
    for (final entry in allUsage.entries) {
      updatePayload['pkg:${entry.key}'] = entry.value;
    }
    service.invoke(ServiceEvents.usageUpdate, updatePayload);

    // Check monitored apps for limit violations.
    final monitored = await db.query('monitored_apps', where: 'is_enabled = 1');
    if (monitored.isEmpty) return;

    // Resolve active pet image path from DB.
    String? petImagePath;
    final petRows = await db.query('pets', where: 'is_active = 1', limit: 1);
    if (petRows.isNotEmpty) {
      petImagePath = petRows.first['image_path'] as String?;
    }
    if (petImagePath == null || petImagePath.isEmpty) return;

    // Check each monitored app.
    for (final row in monitored) {
      final packageName = row['package_name'] as String;
      final limitSeconds = row['daily_limit_seconds'] as int;
      final usedSeconds = allUsage[packageName] ?? 0;

      if (usedSeconds >= limitSeconds && state.canShow(packageName)) {
        final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (!overlayGranted) continue;

        await FlutterOverlayWindow.showOverlay(
          height: 240,
          width: 240,
          alignment: OverlayAlignment.center,
          flag: OverlayFlag.defaultFlag,
          overlayTitle: '여기봐용',
          overlayContent: '펫이 나타났어요!',
        );
        await FlutterOverlayWindow.shareData({
          OverlayDataKeys.petImagePath: petImagePath,
          OverlayDataKeys.triggerType: TriggerType.usageExceeded,
          OverlayDataKeys.packageName: packageName,
          OverlayDataKeys.displaySeconds: overlayDurationSeconds,
        });

        state.markShown(packageName);

        // Log popup in DB.
        final petId = petRows.isNotEmpty ? petRows.first['id'] as int? : null;
        await db.insert('popup_history', {
          'trigger_type': TriggerType.usageExceeded,
          'package_name': packageName,
          'pet_id': petId,
          'shown_at': DateTime.now().toIso8601String(),
        });

        // Only show one overlay per tick to avoid stacking.
        break;
      }
    }
  } catch (_) {
    // Swallow errors — polling must never crash the service.
  }
}

/// Returns the current "day" string (YYYY-MM-DD) accounting for custom reset hour.
String _todayString(int dailyResetHour) {
  final now = DateTime.now();
  final resetToday = DateTime(now.year, now.month, now.day, dailyResetHour);
  final effectiveDate = now.isBefore(resetToday)
      ? resetToday.subtract(const Duration(days: 1))
      : now;
  return '${effectiveDate.year.toString().padLeft(4, '0')}-'
      '${effectiveDate.month.toString().padLeft(2, '0')}-'
      '${effectiveDate.day.toString().padLeft(2, '0')}';
}

// ─── Called from main isolate (main.dart) ────────────────────────────────────

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'foreground_service',
      initialNotificationTitle: '여기봐용 실행 중',
      initialNotificationContent: '앱 사용 시간을 모니터링하고 있습니다.',
      foregroundServiceNotificationId: 1001,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}
