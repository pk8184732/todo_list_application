import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'tasks.db'),
      version: 2, // Increment version if schema changes
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE tasks("
              "id INTEGER PRIMARY KEY AUTOINCREMENT, "
              "title TEXT, "
              "description TEXT, "
              "imagePath TEXT, "
              "isComplete INTEGER)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Handle schema changes here
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN isComplete INTEGER",
          );
        }
      },
    );
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    try {
      return await db.insert(
        'tasks',
        task,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print("Error inserting task: $e");
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    try {
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print("Error deleting task: $e");
      rethrow;
    }
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    try {
      return await db.update(
        'tasks',
        task,
        where: 'id = ?',
        whereArgs: [task['id']],
      );
    } catch (e) {
      print("Error updating task: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    try {
      return await db.query('tasks');
    } catch (e) {
      print("Error retrieving tasks: $e");
      rethrow;
    }
  }
}





