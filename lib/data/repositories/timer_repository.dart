import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';

/// Active state and completed history share one transaction. Reopening the app
/// after a process kill cannot insert the same completion twice.
class TimerRepository {
  Future<Map<String, dynamic>?> load() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('active_timer', where: 'id = 1');
    return rows.isEmpty
        ? null
        : jsonDecode(rows.single['payload'] as String) as Map<String, dynamic>;
  }

  Future<void> save(Map<String, dynamic>? state) async {
    final db = await DatabaseService.instance.database;
    if (state == null) {
      await db.delete('active_timer');
    } else {
      await db.insert('active_timer', {
        'id': 1,
        'payload': jsonEncode(state),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> finish(
    Map<String, dynamic> session,
    Map<String, dynamic>? state,
  ) async {
    final db = await DatabaseService.instance.database;
    await db.transaction((txn) async {
      await txn.insert('timer_sessions', session);
      await txn.delete('active_timer');
      if (state != null) {
        await txn.insert('active_timer', {
          'id': 1,
          'payload': jsonEncode(state),
        });
      }
    });
  }
}
