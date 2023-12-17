// DatabaseHelper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'ItemModel.dart';

class DatabaseHelper {
  late Database _database;

  DatabaseHelper() {
    // Make the constructor asynchronous and await the initialization
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE item_table(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, date INTEGER, isSelected INTEGER, description TEXT, imagePath TEXT)',
        );
      },
      version: 6,
    );
  }

  Future<void> insertItem(ItemModel item) async {
    // Ensure that the database has been initialized before using it
    await _initializeDatabase();
    await _database.insert(
      'item_table',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ItemModel>> getAllItems() async {
    // Ensure that the database has been initialized before using it
    await _initializeDatabase();
    final List<Map<String, dynamic>> maps = await _database.query('item_table');
    return List.generate(maps.length, (i) {
      return ItemModel.fromMap(maps[i]);
    });
  }

  Future<void> deleteItem(ItemModel item) async {
    // Ensure that the database has been initialized before using it
    await _initializeDatabase();
    await _database.delete(
      'item_table',
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteAllItems(List<int> itemIds) async {
    // Ensure that the database has been initialized before using it
    await _initializeDatabase();
    await _database.delete(
      'item_table',
      where: 'id IN (${itemIds.join(', ')})',
    );
  }

  Future<void> updateItem(ItemModel item) async {
    // Ensure that the database has been initialized before using it
    await _initializeDatabase();
    await _database.update(
      'item_table',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
