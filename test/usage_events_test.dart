import 'package:flutter_test/flutter_test.dart';
import 'package:yeogibwayong/core/utils/usage_day.dart';
import 'package:yeogibwayong/core/utils/usage_events.dart';

void main() {
  final midnight = DateTime(2026, 10, 25);
  AppUsageEvent event(int seconds, int type, [String? app = 'app.a']) =>
      AppUsageEvent(midnight.add(Duration(seconds: seconds)), type, app);
  test('custom reset and month rollover use the same day key', () {
    expect(UsageDay.key(DateTime(2026, 11, 1, 3), 4), '2026-10-31');
    expect(UsageDay.key(DateTime(2026, 11, 1, 4), 4), '2026-11-01');
  });
  test('clips an ongoing session crossing midnight to today', () {
    final result = summarizeUsage(
      [event(-300, 1)],
      midnight,
      midnight.add(const Duration(seconds: 60)),
    );
    expect(result.seconds, {'app.a': 60});
    expect(result.foregroundPackage, 'app.a');
  });
  test(
    'switches apps without double counting and includes current session',
    () {
      final result = summarizeUsage(
        [event(0, 1), event(10, 1, 'app.b'), event(10, 2)],
        midnight,
        midnight.add(const Duration(seconds: 30)),
      );
      expect(result.seconds, {'app.a': 10, 'app.b': 20});
      expect(result.foregroundPackage, 'app.b');
    },
  );
  test('screen off and lock end foreground usage', () {
    for (final type in [15, 17, 26]) {
      final result = summarizeUsage(
        [event(0, 1), event(10, type)],
        midnight,
        midnight.add(const Duration(seconds: 500)),
      );
      expect(result.seconds['app.a'], 10);
      expect(result.foregroundPackage, null);
    }
  });
  test('empty events do not invent usage', () {
    final result = summarizeUsage(
      [],
      midnight,
      midnight.add(const Duration(hours: 1)),
    );
    expect(result.seconds, isEmpty);
    expect(result.foregroundPackage, null);
  });
  test('sorts events and ignores future events', () {
    final result = summarizeUsage(
      [event(10, 2), event(0, 1), event(90, 1)],
      midnight,
      midnight.add(const Duration(seconds: 30)),
    );
    expect(result.seconds, {'app.a': 10});
    expect(result.foregroundPackage, null);
  });
}
