import 'package:flutter_test/flutter_test.dart';
import 'package:yeogibwayong/providers/timer_provider.dart';
import 'package:yeogibwayong/data/repositories/timer_repository.dart';

class MemoryTimerRepository extends TimerRepository {
  Map<String, dynamic>? active;
  final sessions = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> load() async =>
      active == null ? null : Map.of(active!);
  @override
  Future<void> save(Map<String, dynamic>? state) async {
    if (fail) throw StateError('disk full');
    active = state == null ? null : Map.of(state);
  }

  @override
  Future<void> finish(
    Map<String, dynamic> session,
    Map<String, dynamic>? state,
  ) async {
    if (fail) throw StateError('disk full');
    sessions.add(Map.of(session));
    active = state == null ? null : Map.of(state);
  }
}

void main() {
  late MemoryTimerRepository store;
  late DateTime now;
  late TimerProvider timer;
  late List<DateTime> scheduled;
  late int overlays;
  TimerProvider create() => TimerProvider(
    repository: store,
    now: () => now,
    scheduleNotification: (at) async {
      scheduled.add(at);
    },
    cancelNotification: () async {},
    getActivePetImagePath: () => '/pet.png',
    showPet: (_) async {
      overlays++;
    },
  );
  setUp(() {
    store = MemoryTimerRepository();
    now = DateTime(2026, 10, 25, 12);
    scheduled = [];
    overlays = 0;
    timer = create();
  });
  tearDown(() => timer.dispose());

  test('rejects invalid lengths and double starts', () async {
    await timer.start(0);
    expect(timer.isIdle, true);
    await timer.start(-1);
    expect(timer.isIdle, true);
    await timer.start(30);
    await timer.start(60);
    expect(timer.durationSeconds, 30);
    expect(scheduled, hasLength(1));
  });
  test('rounds remaining time up instead of completing early', () async {
    await timer.start(5);
    now = now.add(const Duration(milliseconds: 4900));
    await timer.refresh();
    expect(timer.remainingSeconds, 1);
    expect(timer.isRunning, true);
    now = now.add(const Duration(milliseconds: 100));
    await timer.refresh();
    expect(timer.isCompleted, true);
    expect(store.sessions, hasLength(1));
  });
  test(
    'pause preserves remaining time and resume schedules new deadline',
    () async {
      await timer.start(30);
      now = now.add(const Duration(seconds: 10));
      await timer.pause();
      now = now.add(const Duration(hours: 1));
      await timer.refresh();
      expect(timer.remainingSeconds, 20);
      await timer.resume();
      expect(scheduled.last, now.add(const Duration(seconds: 20)));
    },
  );
  test('restarts recover running state from durable snapshot', () async {
    await timer.start(60);
    timer.dispose();
    now = now.add(const Duration(seconds: 20));
    timer = create();
    await timer.initialize();
    expect(timer.isRunning, true);
    expect(timer.remainingSeconds, 40);
  });
  test(
    'expired restart completes once; repeated refresh/cancel never duplicates history',
    () async {
      await timer.start(10);
      timer.dispose();
      now = now.add(const Duration(minutes: 5));
      timer = create();
      await timer.initialize();
      await timer.refresh();
      await timer.cancel();
      expect(timer.isCompleted, true);
      expect(store.sessions, hasLength(1));
      expect(
        store.sessions.single['completed_at'],
        DateTime(2026, 10, 25, 12, 0, 10).toIso8601String(),
      );
      timer.dispose();
      timer = create();
      await timer.initialize();
      expect(timer.isCompleted, true);
      expect(store.sessions, hasLength(1));
      await timer.acknowledgeCompletion();
      expect(timer.isIdle, true);
      expect(store.active, null);
    },
  );
  test('paused restart stays paused', () async {
    await timer.start(60);
    await timer.pause();
    timer.dispose();
    now = now.add(const Duration(days: 1));
    timer = create();
    await timer.initialize();
    expect(timer.isPaused, true);
    expect(timer.remainingSeconds, 60);
  });
  test('cancel records interruption exactly once', () async {
    await timer.start(60);
    await timer.cancel();
    await timer.cancel();
    expect(store.sessions, hasLength(1));
    expect(store.sessions.single['was_interrupted'], 1);
    expect(store.active, null);
    expect(timer.isIdle, true);
  });
  test('storage failure preserves state and permits retry', () async {
    store.fail = true;
    await timer.start(30);
    expect(timer.isIdle, true);
    expect(timer.error, isNotNull);
    expect(scheduled, isEmpty);
    store.fail = false;
    await timer.start(30);
    expect(timer.isRunning, true);
    now = now.add(const Duration(seconds: 30));
    store.fail = true;
    await timer.refresh();
    expect(timer.isRunning, true);
    expect(store.sessions, isEmpty);
    store.fail = false;
    await timer.refresh();
    expect(timer.isCompleted, true);
    expect(store.sessions, hasLength(1));
  });
  test(
    'background completion keeps scheduled alert and does not open overlay',
    () async {
      await timer.start(10);
      await timer.setForeground(false);
      now = now.add(const Duration(seconds: 10));
      await timer.refresh();
      expect(timer.isCompleted, true);
      expect(overlays, 0);
    },
  );
}
