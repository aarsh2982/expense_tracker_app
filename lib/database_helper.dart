import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/item_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expense_tracker.db');

    // Delete existing database to start fresh
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
            category TEXT NOT NULL,
            dateTime INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // Insert an item with error handling
  Future<int> insertItem(Item item) async {
    try {
      final db = await database;
      return await db.insert(
        'items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to insert item: $e');
    }
  }

  // Get all items with optional filtering and sorting
  Future<List<Item>> getItems({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    String orderBy = 'dateTime DESC',
  }) async {
    try {
      final db = await database;

      // Build where clause
      List<String> whereConditions = [];
      List<dynamic> whereArgs = [];

      if (type != null) {
        whereConditions.add('type = ?');
        whereArgs.add(type);
      }

      if (category != null) {
        whereConditions.add('category = ?');
        whereArgs.add(category);
      }

      if (startDate != null) {
        whereConditions.add('dateTime >= ?');
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereConditions.add('dateTime <= ?');
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      String? whereClause =
          whereConditions.isEmpty ? null : whereConditions.join(' AND ');

      List<Map<String, dynamic>> maps = await db.query(
        'items',
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );

      return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Failed to get items: $e');
    }
  }

  // Get total income with optional date range
  Future<double> getIncome({DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await database;

      String dateCondition = '';
      List<dynamic> args = [];

      if (startDate != null || endDate != null) {
        List<String> conditions = [];
        if (startDate != null) {
          conditions.add('dateTime >= ?');
          args.add(startDate.millisecondsSinceEpoch);
        }
        if (endDate != null) {
          conditions.add('dateTime <= ?');
          args.add(endDate.millisecondsSinceEpoch);
        }
        dateCondition = 'AND ${conditions.join(' AND ')}';
      }

      final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM items WHERE type = 'income' $dateCondition",
        args,
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total income: $e');
    }
  }

  // Get total expenses with optional date range
  Future<double> getTotalExpense(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await database;

      String dateCondition = '';
      List<dynamic> args = [];

      if (startDate != null || endDate != null) {
        List<String> conditions = [];
        if (startDate != null) {
          conditions.add('dateTime >= ?');
          args.add(startDate.millisecondsSinceEpoch);
        }
        if (endDate != null) {
          conditions.add('dateTime <= ?');
          args.add(endDate.millisecondsSinceEpoch);
        }
        dateCondition = 'AND ${conditions.join(' AND ')}';
      }

      final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM items WHERE type = 'expense' $dateCondition",
        args,
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw DatabaseException('Failed to get total expense: $e');
    }
  }

  // Update an item with error handling
  Future<int> updateItem(Item item) async {
    try {
      final db = await database;
      return await db.update(
        'items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update item: $e');
    }
  }

  // Delete an item with error handling
  Future<int> deleteItem(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'items',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete item: $e');
    }
  }

  // Get items grouped by category
  Future<Map<String, double>> getCategoryTotals(String type) async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT category, SUM(amount) as total 
        FROM items 
        WHERE type = ? 
        GROUP BY category
      ''', [type]);

      return Map.fromEntries(
        result.map((row) => MapEntry(
              row['category'] as String,
              (row['total'] as num).toDouble(),
            )),
      );
    } catch (e) {
      throw DatabaseException('Failed to get category totals: $e');
    }
  }
}

// Custom exception for database operations
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
