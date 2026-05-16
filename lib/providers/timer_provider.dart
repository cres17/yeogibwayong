import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../data/database/database_service.dart';
import '../services/notification_service.dart';
import '../services/overlay_service.dart';

export '../services/overlay_service.dart';

enum TimerState { idle, running, paused, completed }

class TimerProvider extends ChangeNotifier {
  /// Callback that returns the active pet's image path.
  /// Injected so this provider stays free of PetProvider dependency.
  String? Function()? getActivePetImagePath;

  TimerProvider({this.getActivePetImagePath});

  void updateActivePetCallback(String? Function() callback) {
    getActivePetImagePath = callback;
  }

  TimerState _state = TimerState.idle;
  int _durationSeconds = 0;
  DateTime? _endTime;
  DateTime? _startedAt;
  int _remainingSeconds = 0;
  Timer? _ticker;

  TimerState get state => _state;
  int get durationSeconds => _durationSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isIdle => _state == TimerState.idle;
  bool get isCompleted => _state == TimerState.completed;

  void start(int seconds) {
    assert(seconds > 0);
    _durationSeconds = seconds;
    _startedAt = DateTime.now();
    _endTime = _startedAt!.add(Duration(seconds: seconds));
    _remainingSeconds = seconds;
    _state = TimerState.running;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (_state != TimerState.running) return;
    _ticker?.cancel();
    _remainingSeconds = _endTime!.difference(DateTime.now()).inSeconds;
    if (_remainingSeconds < 0) _remainingSeconds = 0;
    _endTime = null;
    _state = TimerState.paused;
    NotificationService.instance.cancelBackgroundTimerNotification();
    notifyListeners();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    _endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _state = TimerState.running;
    _startTicker();
    notifyListeners();
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    await NotificationService.instance.cancelBackgroundTimerNotification();
    if (_state != TimerState.idle) {
      await _saveSession(wasInterrupted: true);
    }
    _reset();
    notifyListeners();
  }

  /// Called by TimerScreen's WidgetsBindingObserver when app goes to background.
  Future<void> scheduleBackgroundNotification() async {
    if (_state != TimerState.running || _endTime == null) return;
    await NotificationService.instance.scheduleTimerCompleteAt(_endTime!);
  }

  /// Called when the app returns to foreground — cancels the scheduled notification
  /// because the in-app timer handles completion itself.
  Future<void> cancelBackgroundNotification() async {
    await NotificationService.instance.cancelBackgroundTimerNotification();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final remaining = _endTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _ticker?.cancel();
      _remainingSeconds = 0;
      _state = TimerState.completed;
      _saveSession(wasInterrupted: false);
      _triggerOverlay();
      notifyListeners();
    } else {
      _remainingSeconds = remaining;
      notifyListeners();
    }
  }

  void _triggerOverlay() {
    final petPath = getActivePetImagePath?.call();
    if (petPath == null || petPath.isEmpty) return;
    OverlayService.instance.show(
      petImagePath: petPath,
      triggerType: TriggerType.timerComplete,
    );
  }

  Future<void> _saveSession({required bool wasInterrupted}) async {
    final db = await DatabaseService.instance.database;
    await db.insert('timer_sessions', {
      'duration_seconds': _durationSeconds,
      'started_at': _startedAt?.toIso8601String(),
      'completed_at': wasInterrupted ? null : DateTime.now().toIso8601String(),
      'was_interrupted': wasInterrupted ? 1 : 0,
    });
  }

  void _reset() {
    _state = TimerState.idle;
    _durationSeconds = 0;
    _endTime = null;
    _startedAt = null;
    _remainingSeconds = 0;
  }

  void acknowledgeCompletion() {
    _reset();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
