import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/repositories/timer_repository.dart';
import '../services/notification_service.dart';
import '../services/overlay_service.dart';

enum TimerState { idle, running, paused, completed }

class TimerProvider extends ChangeNotifier {
  TimerProvider({
    this.getActivePetImagePath,
    TimerRepository? repository,
    DateTime Function()? now,
    Future<void> Function(DateTime)? scheduleNotification,
    Future<void> Function()? cancelNotification,
    Future<void> Function(String)? showPet,
  }) : _repository = repository ?? TimerRepository(),
       _now = now ?? DateTime.now,
       _scheduleNotification =
           scheduleNotification ??
           NotificationService.instance.scheduleTimerCompleteAt,
       _cancelNotification =
           cancelNotification ??
           NotificationService.instance.cancelBackgroundTimerNotification,
       _showPet =
           showPet ??
           ((path) => OverlayService.instance.show(
             petImagePath: path,
             triggerType: TriggerType.timerComplete,
           ));

  final TimerRepository _repository;
  final DateTime Function() _now;
  final Future<void> Function(DateTime) _scheduleNotification;
  final Future<void> Function() _cancelNotification;
  final Future<void> Function(String) _showPet;
  String? Function()? getActivePetImagePath;
  TimerState _state = TimerState.idle;
  int _durationSeconds = 0;
  DateTime? _endTime;
  DateTime? _startedAt;
  int _remainingSeconds = 0;
  Timer? _ticker;
  bool _busy = false;
  bool _disposed = false;
  bool _foreground = true;
  String? _error;

  TimerState get state => _state;
  int get durationSeconds => _durationSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isIdle => _state == TimerState.idle;
  bool get isCompleted => _state == TimerState.completed;
  bool get busy => _busy;
  String? get error => _error;

  void updateActivePetCallback(String? Function() callback) =>
      getActivePetImagePath = callback;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Map<String, dynamic> _snapshot() => {
    'state': _state.name,
    'duration': _durationSeconds,
    'remaining': _remainingSeconds,
    'startedAt': _startedAt?.toIso8601String(),
    'endTime': _endTime?.toIso8601String(),
  };

  void _restore(Map<String, dynamic> data) {
    _state = TimerState.values.byName(data['state'] as String);
    _durationSeconds = data['duration'] as int;
    _remainingSeconds = data['remaining'] as int;
    _startedAt = DateTime.tryParse(data['startedAt'] as String? ?? '');
    _endTime = DateTime.tryParse(data['endTime'] as String? ?? '');
  }

  /// Serialize transitions and preserve the previous state on storage failure.
  Future<void> _change(Future<void> Function() operation) async {
    if (_busy || _disposed) return;
    _busy = true;
    _error = null;
    final before = _snapshot();
    _notify();
    try {
      await operation();
    } catch (error) {
      _restore(before);
      _error = '타이머를 저장하지 못했어요. 다시 시도해주세요.';
      debugPrint('Timer transition failed: $error');
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> initialize() async {
    await _change(() async {
      final data = await _repository.load();
      if (data != null) _restore(data);
    });
    await refresh();
    if (isRunning) {
      _startTicker();
      await _schedule();
    }
  }

  Future<void> start(int seconds) => _change(() async {
    if (!isIdle || seconds <= 0 || seconds > 86400) return;
    _durationSeconds = seconds;
    _remainingSeconds = seconds;
    _startedAt = _now();
    _endTime = _startedAt!.add(Duration(seconds: seconds));
    _state = TimerState.running;
    await _repository.save(_snapshot());
    _startTicker();
    await _schedule();
  });

  int _remaining() =>
      ((_endTime!.difference(_now()).inMilliseconds / 1000).ceil()).clamp(
        0,
        _durationSeconds,
      );

  Future<void> pause() async {
    await refresh();
    await _change(() async {
      if (!isRunning) return;
      _remainingSeconds = _remaining();
      _state = TimerState.paused;
      _endTime = null;
      await _repository.save(_snapshot());
      _ticker?.cancel();
      await _cancelAlert();
    });
  }

  Future<void> resume() => _change(() async {
    if (!isPaused) return;
    _endTime = _now().add(Duration(seconds: _remainingSeconds));
    _state = TimerState.running;
    await _repository.save(_snapshot());
    _startTicker();
    await _schedule();
  });

  Future<void> cancel() async {
    await refresh();
    await _change(() async {
      if (!isRunning && !isPaused) return;
      await _repository.finish(_session(interrupted: true), null);
      _reset();
      await _cancelAlert();
    });
  }

  Map<String, dynamic> _session({required bool interrupted}) => {
    'duration_seconds': _durationSeconds,
    'started_at': _startedAt!.toIso8601String(),
    'completed_at': interrupted ? null : _endTime!.toIso8601String(),
    'was_interrupted': interrupted ? 1 : 0,
  };

  Future<void> refresh() async {
    if (!isRunning || _busy || _disposed) return;
    _remainingSeconds = _remaining();
    if (_remainingSeconds > 0) {
      _notify();
      return;
    }
    await _change(() async {
      _state = TimerState.completed;
      await _repository.finish(_session(interrupted: false), _snapshot());
      _ticker?.cancel();
      if (_foreground) {
        await _cancelAlert();
        final path = getActivePetImagePath?.call();
        if (path != null && path.isNotEmpty) {
          try {
            await _showPet(path);
          } catch (error) {
            debugPrint('Pet reminder unavailable: $error');
          }
        }
      }
    });
  }

  Future<void> setForeground(bool foreground) async {
    _foreground = foreground;
    await refresh();
    if (foreground && isCompleted) await _cancelAlert();
  }

  Future<void> _schedule() async {
    try {
      await _scheduleNotification(_endTime!);
    } catch (_) {
      _error = '타이머는 진행 중이에요. 백그라운드 알림을 예약하지 못했어요.';
    }
  }

  Future<void> _cancelAlert() async {
    try {
      await _cancelNotification();
    } catch (_) {
      _error = '예약 알림을 취소하지 못했어요. 알림 설정을 확인해주세요.';
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(refresh()),
    );
  }

  void _reset() {
    _ticker?.cancel();
    _state = TimerState.idle;
    _durationSeconds = 0;
    _endTime = null;
    _startedAt = null;
    _remainingSeconds = 0;
  }

  Future<void> acknowledgeCompletion() => _change(() async {
    if (!isCompleted) return;
    await _repository.save(null);
    _reset();
  });

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
