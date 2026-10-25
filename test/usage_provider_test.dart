import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeogibwayong/providers/usage_provider.dart';
import 'package:yeogibwayong/data/models/monitored_app_model.dart';
import 'package:yeogibwayong/data/repositories/usage_repository.dart';

class FakeUsageRepository extends UsageRepository {
  final reads = <String, Completer<List<Map<String, dynamic>>>>{};
  @override
  Future<List<MonitoredAppModel>> getMonitoredApps() async => [];
  @override
  Future<List<Map<String, dynamic>>> getDailyUsageAll(String date) =>
      (reads[date] ??= Completer()).future;
  @override
  Future<List<Map<String, dynamic>>> getWeeklyTotals({
    required String fromDate,
    required String toDate,
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'empty new-day snapshot clears yesterday and removed package values',
    () {
      final usage = UsageProvider(FakeUsageRepository());
      usage.onUsageUpdate({'pkg:a': 80, 'pkg:b': 40});
      usage.onUsageUpdate({'pkg:a': 2});
      expect(usage.todayUsage, {'a': 2});
      usage.onUsageUpdate({'date': '2026-10-26'});
      expect(usage.todayUsage, isEmpty);
      usage.dispose();
    },
  );
  test('startup restores stored today usage', () async {
    final repo = FakeUsageRepository();
    repo.reads['2026-10-25'] = Completer()
      ..complete([
        {'package_name': 'a', 'duration_seconds': 50},
      ]);
    final usage = UsageProvider(repo, now: () => DateTime(2026, 10, 25, 12));
    await usage.load();
    expect(usage.todaySecondsFor('a'), 50);
    usage.dispose();
  });
  test('late statistics result never overwrites the selected date', () async {
    final repo = FakeUsageRepository();
    final usage = UsageProvider(repo);
    final first = usage.loadStats('2026-10-24');
    final second = usage.loadStats('2026-10-25');
    repo.reads['2026-10-25']!.complete([
      {'package_name': 'new'},
    ]);
    await second;
    repo.reads['2026-10-24']!.complete([
      {'package_name': 'old'},
    ]);
    await first;
    expect(usage.dailyStats.single['package_name'], 'new');
    expect(usage.statsLoading, false);
    usage.dispose();
  });
  test(
    'failed statistics read ends loading and exposes retryable error',
    () async {
      final repo = FakeUsageRepository();
      final usage = UsageProvider(repo);
      final load = usage.loadStats('2026-10-25');
      repo.reads['2026-10-25']!.completeError(
        StateError('database unavailable'),
      );
      await load;
      expect(usage.statsLoading, false);
      expect(usage.statsError, isNotNull);
      usage.dispose();
    },
  );
}
