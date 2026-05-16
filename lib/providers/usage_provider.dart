import 'package:flutter/foundation.dart';

import '../data/models/monitored_app_model.dart';
import '../data/repositories/usage_repository.dart';

class UsageProvider extends ChangeNotifier {
  final UsageRepository _repo;

  UsageProvider(this._repo);

  List<MonitoredAppModel> _monitoredApps = [];
  // packageName → seconds used today (populated by background service via DB)
  final Map<String, int> _todayUsage = {};
  bool _loading = false;

  // Statistics state ---------------------------------------------------------
  // Daily: packageName → durationSeconds for the selected date
  List<Map<String, dynamic>> _dailyStats = [];
  // Weekly: dateString → totalSeconds for the last 7 days
  List<Map<String, dynamic>> _weeklyStats = [];
  bool _statsLoading = false;

  List<MonitoredAppModel> get monitoredApps => _monitoredApps;
  Map<String, int> get todayUsage => Map.unmodifiable(_todayUsage);
  bool get loading => _loading;
  List<Map<String, dynamic>> get dailyStats => _dailyStats;
  List<Map<String, dynamic>> get weeklyStats => _weeklyStats;
  bool get statsLoading => _statsLoading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _monitoredApps = await _repo.getMonitoredApps();
    _loading = false;
    notifyListeners();
  }

  Future<void> addMonitoredApp(MonitoredAppModel app) async {
    await _repo.upsertMonitoredApp(app);
    await load();
  }

  Future<void> removeMonitoredApp(String packageName) async {
    await _repo.deleteMonitoredApp(packageName);
    _monitoredApps =
        _monitoredApps.where((a) => a.packageName != packageName).toList();
    _todayUsage.remove(packageName);
    notifyListeners();
  }

  /// Called when background service pushes a usage update via invoke().
  /// Payload uses 'pkg:PACKAGE_NAME' keys to carry per-app seconds.
  void onUsageUpdate(Map<String, dynamic> data) {
    bool changed = false;
    for (final entry in data.entries) {
      if (entry.key.startsWith('pkg:')) {
        final pkg = entry.key.substring(4);
        final seconds = entry.value as int?;
        if (seconds != null) {
          _todayUsage[pkg] = seconds;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> loadStats(String dateString) async {
    _statsLoading = true;
    notifyListeners();

    final date = DateTime.parse(dateString);
    final fromDate =
        date.subtract(const Duration(days: 6));
    final fromString =
        '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';

    final results = await Future.wait([
      _repo.getDailyUsageAll(dateString),
      _repo.getWeeklyTotals(fromDate: fromString, toDate: dateString),
    ]);

    _dailyStats = results[0];
    _weeklyStats = results[1];
    _statsLoading = false;
    notifyListeners();
  }

  int todaySecondsFor(String packageName) => _todayUsage[packageName] ?? 0;

  int? limitSecondsFor(String packageName) {
    final app = _monitoredApps
        .where((a) => a.packageName == packageName)
        .firstOrNull;
    return app?.dailyLimitSeconds;
  }
}
