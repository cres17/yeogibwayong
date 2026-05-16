class TimeFormatter {
  TimeFormatter._();

  static String formatMMSS(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatHHMM(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '$h시간 ${m.toString().padLeft(2, '0')}분';
    if (m > 0) return '$m분';
    return '$totalSeconds초';
  }

  static String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '$h시간 ${m.toString().padLeft(2, '0')}분';
    if (m > 0) return '$m분 ${s.toString().padLeft(2, '0')}초';
    return '$s초';
  }

  static String formatLimitMinutes(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '$h시간' : '$h시간 $m분';
    }
    return '$minutes분';
  }

  static String formatCountdown(Duration remaining) {
    final m = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (remaining.inHours > 0) return '${remaining.inHours}:$m:$s';
    return '$m:$s';
  }
}
