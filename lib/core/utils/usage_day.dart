class UsageDay {
  static DateTime start(DateTime now, int resetHour) {
    final today = DateTime(
      now.year,
      now.month,
      now.day,
      resetHour.clamp(0, 23),
    );
    return now.isBefore(today)
        ? DateTime(now.year, now.month, now.day - 1, resetHour.clamp(0, 23))
        : today;
  }

  static String key(DateTime now, [int resetHour = 0]) {
    final date = start(now, resetHour);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
