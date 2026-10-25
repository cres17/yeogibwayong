/// Single foreground-app accounting. Split-screen simultaneous activity is not
/// counted twice. Callers provide a lookback to seed sessions crossing midnight.
class AppUsageEvent {
  const AppUsageEvent(this.time, this.type, this.package);
  final DateTime time;
  final int type;
  final String? package;
}

class UsageSnapshot {
  const UsageSnapshot(this.seconds, this.foregroundPackage);
  final Map<String, int> seconds;
  final String? foregroundPackage;
}

UsageSnapshot summarizeUsage(
  List<AppUsageEvent> events,
  DateTime start,
  DateTime end,
) {
  final sorted = [...events]..sort((a, b) => a.time.compareTo(b.time));
  final milliseconds = <String, int>{};
  String? active;
  DateTime? since;
  void flush(DateTime until) {
    if (active == null || since == null) return;
    final from = since.isBefore(start) ? start : since;
    final to = until.isAfter(end) ? end : until;
    if (to.isAfter(from)) {
      milliseconds[active] =
          (milliseconds[active] ?? 0) + to.difference(from).inMilliseconds;
    }
  }

  for (final event in sorted) {
    if (event.time.isAfter(end)) break;
    if (event.type == 1 && event.package != null) {
      flush(event.time);
      active = event.package;
      since = event.time;
    } else if ((event.type == 2 && event.package == active) ||
        event.type == 15 ||
        event.type == 17 ||
        event.type == 26) {
      // ACTIVITY_PAUSED, SCREEN_NON_INTERACTIVE, KEYGUARD_SHOWN, DEVICE_SHUTDOWN.
      flush(event.time);
      active = null;
      since = null;
    }
  }
  flush(end);
  return UsageSnapshot({
    for (final e in milliseconds.entries) e.key: e.value ~/ 1000,
  }, active);
}
