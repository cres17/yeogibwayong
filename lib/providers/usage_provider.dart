import 'package:flutter/foundation.dart';
import '../core/utils/usage_day.dart';
import '../data/repositories/settings_repository.dart';

import '../data/models/monitored_app_model.dart';
import '../data/repositories/usage_repository.dart';

class UsageProvider extends ChangeNotifier {
  final UsageRepository _repo;

  UsageProvider(
    this._repo, {
    SettingsRepository? settings,
    DateTime Function()? now,
  }) : _settings = settings ?? SettingsRepository(),
       _now = now ?? DateTime.now;
  final SettingsRepository _settings;
  final DateTime Function() _now;
  String? _error;
  String? _statsError;
  int _statsRequest = 0;
  int _usageRevision = 0;
  String? get error => _error;
  String? get statsError => _statsError;

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
    final revision = _usageRevision;
    _error = null;
    try {
      _monitoredApps = await _repo.getMonitoredApps();
      final hour = await _settings.getDailyResetHour();
      final rows = await _repo.getDailyUsageAll(UsageDay.key(_now(), hour));
      // A live snapshot received during the read is more recent than this DB read.
      if (revision == _usageRevision) {
        _todayUsage.clear();
        for (final row in rows) {
          _todayUsage[row['package_name'] as String] =
              row['duration_seconds'] as int? ?? 0;
        }
      }
    } catch (_) {
      _error = '사용 기록을 불러오지 못했어요. 아래로 당겨 다시 시도해주세요.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addMonitoredApp(MonitoredAppModel app) async {
    await _repo.upsertMonitoredApp(app);
    await load();
  }

  Future<void> removeMonitoredApp(String packageName) async {
    await _repo.deleteMonitoredApp(packageName);
    _monitoredApps = _monitoredApps
        .where((a) => a.packageName != packageName)
        .toList();
    _todayUsage.remove(packageName);
    notifyListeners();
  }

  /// Called when background service pushes a usage update via invoke().
  /// Payload uses 'pkg:PACKAGE_NAME' keys to carry per-app seconds.
  void onUsageUpdate(Map<String, dynamic> data) {
    _usageRevision++;
    _todayUsage.clear();
    for (final entry in data.entries) {
      if (entry.key.startsWith('pkg:') && entry.value is int) {
        _todayUsage[entry.key.substring(4)] = (entry.value as int).clamp(
          0,
          86400,
        );
      }
    }
    notifyListeners();
  }

  Future<void> loadStats(String dateString) async {
    final request = ++_statsRequest;
    _statsLoading = true;
    _statsError = null;
    notifyListeners();
    try {
      final date = DateTime.parse(dateString);
      final fromString = UsageDay.key(
        DateTime(date.year, date.month, date.day - 6),
      );
      final results = await Future.wait([
        _repo.getDailyUsageAll(dateString),
        _repo.getWeeklyTotals(fromDate: fromString, toDate: dateString),
      ]);
      if (request != _statsRequest) return;
      _dailyStats = results[0];
      _weeklyStats = results[1];
    } catch (_) {
      if (request != _statsRequest) return;
      _dailyStats = [];
      _weeklyStats = [];
      _statsError = '통계를 불러오지 못했어요. 다시 시도해주세요.';
    } finally {
      if (request == _statsRequest) {
        _statsLoading = false;
        notifyListeners();
      }
    }
  }

  int todaySecondsFor(String packageName) => _todayUsage[packageName] ?? 0;

  int? limitSecondsFor(String packageName) {
    final app = _monitoredApps
        .where((a) => a.packageName == packageName)
        .firstOrNull;
    return app?.dailyLimitSeconds;
  }
}
