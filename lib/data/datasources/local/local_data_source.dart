import 'package:chatterg/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._internal();
  factory LocalDataSource() => _instance;
  LocalDataSource._internal();

  static Database? _database;
  static const String _dbName = 'user_data.db';
  static const String _tableName = 'user';
  static const int _dbVersion = 1;

  static const String _colId = 'id';
  static const String _colName = 'name';
  static const String _colEmail = 'email';
  static const String _colUuid = 'uuid';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $_colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colName TEXT NOT NULL,
        $_colEmail TEXT NOT NULL,
        $_colUuid TEXT NOT NULL UNIQUE
      )
    ''');
    // Insert initial empty data row if needed, or handle upsert logic
    await db.insert(
      _tableName,
      {
        _colName: '',
        _colEmail: '',
        _colUuid: '', // Ensure this is unique or handle conflicts
      },
      // Use replace to handle potential initial setup conflicts or updates
      // Or manage a single row with a fixed ID like 1
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Saves or updates the single user data row.
  // Assumes there's only one user profile to store.
  Future<void> saveData(Map<String, User> data) async {
    final db = await database;
    // Check if required keys exist
    if (data.containsKey(_colName) &&
        data.containsKey(_colEmail) &&
        data.containsKey(_colUuid)) {
      // Attempt to update the first row, or insert if it doesn't exist.
      // Using a fixed ID (e.g., 1) is often simpler for single-row data.
      // Let's try updating based on UUID or insert if not present.
      // For simplicity, let's just replace the *first* record found or insert.
      // A more robust way would be to use WHERE clause with a fixed ID or the UUID.

      final List<Map<String, dynamic>> existing = await db.query(
        _tableName,
        limit: 1,
      );

      final Map<String, dynamic> dataToSave = {
        _colName: data[_colName] ?? '',
        _colEmail: data[_colEmail] ?? '',
        _colUuid: data[_colUuid] ?? '',
      };

      if (existing.isNotEmpty) {
        // Update the first row found
        await db.update(
          _tableName,
          dataToSave,
          where: '$_colId = ?', // Update the row with the specific ID
          whereArgs: [existing.first[_colId]],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Insert if table was somehow empty
        await db.insert(
          _tableName,
          dataToSave,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } else {
      // Handle error: Required data fields are missing
      // Optionally throw an exception or log an error
      print("Error: Missing required fields in data map for saveData.");
    }
  }

  Future<Map<String, dynamic>> getData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      limit: 1, // Assuming only one user data row exists
    );

    if (maps.isNotEmpty) {
      // Remove the internal 'id' column before returning
      final result = Map<String, dynamic>.from(maps.first);
      result.remove(_colId);
      return result;
    } else {
      // Return default empty data if no record found
      return {
        _colName: '',
        _colEmail: '',
        _colUuid: '',
      };
    }
  }

  // Optional: Method to close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Optional: Clear data (useful for logout)
  Future<void> clearData() async {
    final db = await database;
    // Update the first row to empty strings
    final List<Map<String, dynamic>> existing = await db.query(
      _tableName,
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        _tableName,
        {
          _colName: '',
          _colEmail: '',
          _colUuid: '',
        },
        where: '$_colId = ?',
        whereArgs: [existing.first[_colId]],
      );
    }
    // Or, alternatively delete all rows and re-insert the empty one:
    // await db.delete(_tableName);
    // await db.insert(_tableName, {_colName: '', _colEmail: '', _colUuid: ''});
  }
}
