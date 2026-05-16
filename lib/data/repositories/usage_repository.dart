import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/monitored_app_model.dart';

class UsageRepository {
  Future<Database> get _db => DatabaseService.instance.database;

  // monitored_apps -----------------------------------------------------------

  Future<List<MonitoredAppModel>> getMonitoredApps() async {
    final db = await _db;
    final rows = await db.query('monitored_apps', orderBy: 'app_name ASC');
    return rows.map(MonitoredAppModel.fromMap).toList();
  }

  Future<int> upsertMonitoredApp(MonitoredAppModel app) async {
    final db = await _db;
    return db.insert(
      'monitored_apps',
      app.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMonitoredApp(String packageName) async {
    final db = await _db;
    await db.delete('monitored_apps',
        where: 'package_name = ?', whereArgs: [packageName]);
  }

  // usage_log_daily ----------------------------------------------------------

  Future<void> upsertDailyUsage({
    required String packageName,
    required String dateString,
    required int durationSeconds,
  }) async {
    final db = await _db;
    await db.rawInsert(
      '''INSERT OR REPLACE INTO usage_log_daily
         (package_name, date_string, duration_seconds)
         VALUES (?, ?, ?)''',
      [packageName, dateString, durationSeconds],
    );
  }

  Future<int> getDailyUsage({
    required String packageName,
    required String dateString,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'usage_log_daily',
      columns: ['duration_seconds'],
      where: 'package_name = ? AND date_string = ?',
      whereArgs: [packageName, dateString],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return rows.first['duration_seconds'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> getWeeklyUsage({
    required String packageName,
    required String fromDate,
    required String toDate,
  }) async {
    final db = await _db;
    return db.query(
      'usage_log_daily',
      where: 'package_name = ? AND date_string BETWEEN ? AND ?',
      whereArgs: [packageName, fromDate, toDate],
      orderBy: 'date_string ASC',
    );
  }

  /// Returns all usage rows for [dateString], sorted by duration descending.
  Future<List<Map<String, dynamic>>> getDailyUsageAll(String dateString) async {
    final db = await _db;
    return db.query(
      'usage_log_daily',
      where: 'date_string = ?',
      whereArgs: [dateString],
      orderBy: 'duration_seconds DESC',
    );
  }

  /// Returns one row per day in [fromDate..toDate] with total seconds summed.
  Future<List<Map<String, dynamic>>> getWeeklyTotals({
    required String fromDate,
    required String toDate,
  }) async {
    final db = await _db;
    return db.rawQuery(
      '''SELECT date_string, SUM(duration_seconds) AS total_seconds
         FROM usage_log_daily
         WHERE date_string BETWEEN ? AND ?
         GROUP BY date_string
         ORDER BY date_string ASC''',
      [fromDate, toDate],
    );
  }

  // popup_history ------------------------------------------------------------

  Future<void> insertPopupHistory({
    required String triggerType,
    String? packageName,
    int? petId,
  }) async {
    final db = await _db;
    await db.insert('popup_history', {
      'trigger_type': triggerType,
      'package_name': packageName,
      'pet_id': petId,
      'shown_at': DateTime.now().toIso8601String(),
    });
  }
}
