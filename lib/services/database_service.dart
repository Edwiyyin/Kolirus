import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/meal_log.dart';
import '../models/health_entry.dart';
import '../models/meal_routine.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kolirus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createScanHistoryTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_list (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          isCompleted INTEGER NOT NULL,
          category TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meal_routine (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          mealType INTEGER NOT NULL,
          recipeId TEXT,
          manualEntry TEXT,
          time TEXT,
          isEaten INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE food_items ADD COLUMN ingredientsText TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE scan_history ADD COLUMN ingredientsText TEXT'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE recipes ADD COLUMN prepTime INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN cookTime INTEGER DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN servings INTEGER DEFAULT 1'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT "Lunch"'); } catch (_) {}
    }
    if (oldVersion < 7) {
      // Add nutrition columns to recipes
      try { await db.execute('ALTER TABLE recipes ADD COLUMN calories REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN protein REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN carbs REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN fat REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN saturatedFat REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN sodium REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN cholesterol REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN fiber REAL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE recipes ADD COLUMN sugar REAL DEFAULT 0'); } catch (_) {}
    }
    if (oldVersion < 8) {
      // Add macro columns to meal_routine for manual entries
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN calories REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN protein REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN carbs REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN fat REAL'); } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        barcode TEXT,
        brand TEXT,
        imageUrl TEXT,
        nutriScore TEXT,
        allergens TEXT NOT NULL,
        ingredientsText TEXT,
        location INTEGER NOT NULL,
        expiryDate TEXT,
        addedDate TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        saturatedFat REAL NOT NULL,
        sodium REAL NOT NULL,
        cholesterol REAL NOT NULL,
        fiber REAL NOT NULL,
        sugar REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        imageUrl TEXT,
        isCommunityShared INTEGER NOT NULL,
        prepTime INTEGER NOT NULL DEFAULT 0,
        cookTime INTEGER NOT NULL DEFAULT 0,
        servings INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT 'Lunch',
        calories REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        saturatedFat REAL NOT NULL DEFAULT 0,
        sodium REAL NOT NULL DEFAULT 0,
        cholesterol REAL NOT NULL DEFAULT 0,
        fiber REAL NOT NULL DEFAULT 0,
        sugar REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_logs (
        id TEXT PRIMARY KEY,
        foodItemId TEXT NOT NULL,
        foodName TEXT NOT NULL,
        quantity REAL NOT NULL,
        consumedAt TEXT NOT NULL,
        type INTEGER NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        saturatedFat REAL NOT NULL,
        sodium REAL NOT NULL,
        cholesterol REAL NOT NULL,
        fiber REAL NOT NULL,
        sugar REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE health_entries (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        bodyMass REAL NOT NULL,
        cholesterol REAL NOT NULL,
        steps INTEGER NOT NULL
      )
    ''');

    await _createScanHistoryTable(db);

    await db.execute('''
      CREATE TABLE shopping_list (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        category TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE meal_routine (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        mealType INTEGER NOT NULL,
        recipeId TEXT,
        manualEntry TEXT,
        time TEXT,
        isEaten INTEGER NOT NULL,
        calories REAL,
        protein REAL,
        carbs REAL,
        fat REAL
      )
    ''');
  }

  Future _createScanHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scan_history (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        barcode TEXT,
        brand TEXT,
        imageUrl TEXT,
        nutriScore TEXT,
        allergens TEXT NOT NULL,
        ingredientsText TEXT,
        location INTEGER NOT NULL,
        expiryDate TEXT,
        addedDate TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        saturatedFat REAL NOT NULL,
        sodium REAL NOT NULL,
        cholesterol REAL NOT NULL,
        fiber REAL NOT NULL,
        sugar REAL NOT NULL
      )
    ''');
  }

  // Food Items (Pantry)
  Future<void> insertFoodItem(FoodItem item) async {
    final db = await instance.database;
    await db.insert('food_items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FoodItem>> getPantryItems() async {
    final db = await instance.database;
    final result = await db.query('food_items');
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  Future<void> deleteFoodItem(String id) async {
    final db = await instance.database;
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
  }

  // Scan History
  Future<void> insertScanHistory(FoodItem item) async {
    final db = await instance.database;
    await db.insert('scan_history', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FoodItem>> getScanHistory() async {
    final db = await instance.database;
    final result =
    await db.query('scan_history', orderBy: 'addedDate DESC', limit: 50);
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  // Recipes
  Future<void> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    await db.insert('recipes', recipe.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await instance.database;
    final result = await db.query('recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  // Meal Logs
  Future<void> insertMealLog(MealLog log) async {
    final db = await instance.database;
    await db.insert('meal_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MealLog>> getMealLogs(DateTime date) async {
    final db = await instance.database;
    final startOfDay =
    DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
    DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
    return result.map((json) => MealLog.fromMap(json)).toList();
  }

  Future<void> deleteMealLog(String id) async {
    final db = await instance.database;
    await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  // Health Entries
  Future<void> insertHealthEntry(HealthEntry entry) async {
    final db = await instance.database;
    await db.insert('health_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HealthEntry?> getHealthEntryForDate(DateTime date) async {
    final db = await instance.database;
    final dateStr =
    DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

    final result = await db.query(
      'health_entries',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
    );
    if (result.isNotEmpty) {
      return HealthEntry.fromMap(result.first);
    }
    return null;
  }

  Future<List<HealthEntry>> getAllHealthEntries() async {
    final db = await instance.database;
    final result =
    await db.query('health_entries', orderBy: 'date ASC');
    return result.map((json) => HealthEntry.fromMap(json)).toList();
  }

  // Shopping List
  Future<void> insertShoppingItem(Map<String, dynamic> item) async {
    final db = await instance.database;
    await db.insert('shopping_list', item,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    final db = await instance.database;
    return await db.query('shopping_list');
  }

  Future<void> deleteShoppingItem(String id) async {
    final db = await instance.database;
    await db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  // User Settings
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('user_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final result =
    await db.query('user_settings', where: 'key = ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // Meal Routine
  Future<void> insertMealRoutine(MealRoutine routine) async {
    final db = await instance.database;
    await db.insert('meal_routine', routine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MealRoutine>> getMealRoutine(DateTime date) async {
    final db = await instance.database;
    final dateStr =
    DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    final result = await db.query('meal_routine',
        where: 'date LIKE ?', whereArgs: ['$dateStr%']);
    return result.map((json) => MealRoutine.fromMap(json)).toList();
  }

  Future<void> deleteMealRoutine(String id) async {
    final db = await instance.database;
    await db.delete('meal_routine', where: 'id = ?', whereArgs: [id]);
  }
}
