import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _timerBackgroundId = 2003;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    await _createChannels();
  }

  Future<void> _createChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'foreground_service',
        '백그라운드 서비스',
        importance: Importance.low,
        showBadge: false,
      ),
      AndroidNotificationChannel(
        'timer_complete',
        '타이머 완료',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'usage_exceeded',
        '사용 시간 초과',
        importance: Importance.high,
      ),
    ];

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final ch in channels) {
      await androidPlugin?.createNotificationChannel(ch);
    }
  }

  Future<bool> _notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.notificationEnabled) ?? true;
  }

  Future<NotificationDetails> _alertDetails({
    required String channelId,
    required String channelName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getBool(PrefKeys.soundEnabled) ?? true;
    final vibrationEnabled = prefs.getBool(PrefKeys.vibrationEnabled) ?? true;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        // Android channel alert settings are immutable after first creation.
        '${channelId}_${soundEnabled ? "sound" : "silent"}_${vibrationEnabled ? "vibrate" : "still"}',
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
      ),
    );
  }

  Future<void> showTimerComplete() async {
    if (!await _notificationsEnabled()) return;

    await _plugin.show(
      2001,
      '타이머 완료',
      '여기봐용이 기다리고 있어요.',
      await _alertDetails(channelId: 'timer_complete', channelName: '타이머 완료'),
    );
  }

  Future<void> showUsageExceeded(String appName) async {
    if (!await _notificationsEnabled()) return;

    await _plugin.show(
      2002,
      '$appName 사용 시간 초과',
      '여기봐용이 주의를 돌려달라고 해요.',
      await _alertDetails(channelId: 'usage_exceeded', channelName: '사용 시간 초과'),
    );
  }

  /// Schedules a notification to fire at [endTime] while the timer runs in the
  /// background. Call [cancelBackgroundTimerNotification] when the app resumes.
  Future<void> scheduleTimerCompleteAt(DateTime endTime) async {
    await _plugin.cancel(_timerBackgroundId);
    if (!await _notificationsEnabled()) return;

    if (!endTime.isAfter(DateTime.now())) return;
    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);
    await _plugin.zonedSchedule(
      _timerBackgroundId,
      '타이머 완료',
      '여기봐용이 기다리고 있어요.',
      scheduledDate,
      await _alertDetails(channelId: 'timer_complete', channelName: '타이머 완료'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelBackgroundTimerNotification() =>
      _plugin.cancel(_timerBackgroundId);

  Future<void> cancelAll() => _plugin.cancelAll();
}
