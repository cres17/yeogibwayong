import 'package:sqflite/sqflite.dart';

import '../database/database_service.dart';
import '../models/pet_model.dart';

class PetRepository {
  Future<Database> get _db => DatabaseService.instance.database;

  Future<List<PetModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('pets', orderBy: 'id ASC');
    return rows.map(PetModel.fromMap).toList();
  }

  Future<PetModel?> getActive() async {
    final db = await _db;
    final rows = await db.query('pets', where: 'is_active = 1', limit: 1);
    return rows.isEmpty ? null : PetModel.fromMap(rows.first);
  }

  Future<int> insert(PetModel pet) async {
    final db = await _db;
    return db.insert('pets', pet.toMap());
  }

  Future<void> setActive(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('pets', {'is_active': 0});
      await txn.update(
        'pets',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> updateImagePath(int id, String imagePath) async {
    final db = await _db;
    await db.update(
      'pets',
      {'image_path': imagePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }
}
