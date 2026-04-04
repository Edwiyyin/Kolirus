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
      version: 11,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createScanHistoryTable(db);
    if (oldVersion < 3) {
      await db.execute('CREATE TABLE IF NOT EXISTS shopping_list (id TEXT PRIMARY KEY, name TEXT NOT NULL, isCompleted INTEGER NOT NULL, category TEXT)');
      await db.execute('CREATE TABLE IF NOT EXISTS user_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    }
    if (oldVersion < 4) await db.execute('CREATE TABLE IF NOT EXISTS meal_routine (id TEXT PRIMARY KEY, date TEXT NOT NULL, mealType INTEGER NOT NULL, recipeId TEXT, manualEntry TEXT, time TEXT, isEaten INTEGER NOT NULL)');
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
      final columns = ['calories', 'protein', 'carbs', 'fat', 'saturatedFat', 'sodium', 'cholesterol', 'fiber', 'sugar'];
      for (var col in columns) {
        try { await db.execute('ALTER TABLE recipes ADD COLUMN $col REAL DEFAULT 0'); } catch (_) {}
      }
    }
    if (oldVersion < 8) {
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN calories REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN protein REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN carbs REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meal_routine ADD COLUMN fat REAL'); } catch (_) {}
    }
    if (oldVersion < 9) {
      final tables = ['food_items', 'scan_history', 'meal_logs'];
      final nutrients = ['potassium', 'magnesium', 'vitaminC', 'vitaminD', 'calcium', 'iron'];
      for (var table in tables) {
        for (var n in nutrients) {
          try { await db.execute('ALTER TABLE $table ADD COLUMN $n REAL DEFAULT 0'); } catch (_) {}
        }
        try { await db.execute('ALTER TABLE $table ADD COLUMN price REAL'); } catch (_) {}
      }
    }
    if (oldVersion < 10) {
      try { await db.execute('ALTER TABLE health_entries ADD COLUMN height REAL DEFAULT 0'); } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receipts (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          imageUrl TEXT,
          totalAmount REAL,
          items TEXT
        )
      ''');
    }
    if (oldVersion < 11) {
      try { await db.execute('ALTER TABLE shopping_list ADD COLUMN quantity REAL DEFAULT 1'); } catch (_) {}
      try { await db.execute('ALTER TABLE shopping_list ADD COLUMN recipeId TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE shopping_list ADD COLUMN notes TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE shopping_list ADD COLUMN listId TEXT DEFAULT "default"'); } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS shopping_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL
        )
      ''');
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
        calories REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL, fat REAL NOT NULL,
        saturatedFat REAL NOT NULL, sodium REAL NOT NULL, cholesterol REAL NOT NULL,
        fiber REAL NOT NULL, sugar REAL NOT NULL, potassium REAL NOT NULL DEFAULT 0,
        magnesium REAL NOT NULL DEFAULT 0, vitaminC REAL NOT NULL DEFAULT 0,
        vitaminD REAL NOT NULL DEFAULT 0, calcium REAL NOT NULL DEFAULT 0,
        iron REAL NOT NULL DEFAULT 0, price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL, imageUrl TEXT, isCommunityShared INTEGER NOT NULL,
        prepTime INTEGER NOT NULL DEFAULT 0, cookTime INTEGER NOT NULL DEFAULT 0,
        servings INTEGER NOT NULL DEFAULT 1, category TEXT NOT NULL DEFAULT 'Lunch',
        calories REAL NOT NULL DEFAULT 0, protein REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0, fat REAL NOT NULL DEFAULT 0,
        saturatedFat REAL NOT NULL DEFAULT 0, sodium REAL NOT NULL DEFAULT 0,
        cholesterol REAL NOT NULL DEFAULT 0, fiber REAL NOT NULL DEFAULT 0,
        sugar REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_logs (
        id TEXT PRIMARY KEY, foodItemId TEXT NOT NULL, foodName TEXT NOT NULL,
        quantity REAL NOT NULL, consumedAt TEXT NOT NULL, type INTEGER NOT NULL,
        calories REAL NOT NULL, protein REAL NOT NULL, carbs REAL NOT NULL,
        fat REAL NOT NULL, saturatedFat REAL NOT NULL, sodium REAL NOT NULL,
        cholesterol REAL NOT NULL, fiber REAL NOT NULL, sugar REAL NOT NULL,
        potassium REAL NOT NULL DEFAULT 0, magnesium REAL NOT NULL DEFAULT 0,
        vitaminC REAL NOT NULL DEFAULT 0, vitaminD REAL NOT NULL DEFAULT 0,
        calcium REAL NOT NULL DEFAULT 0, iron REAL NOT NULL DEFAULT 0, price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE health_entries (
        id TEXT PRIMARY KEY, date TEXT NOT NULL, weight REAL NOT NULL,
        bodyMass REAL NOT NULL, height REAL NOT NULL DEFAULT 0,
        cholesterol REAL NOT NULL, steps INTEGER NOT NULL
      )
    ''');

    await _createScanHistoryTable(db);

    await db.execute('''
      CREATE TABLE shopping_list (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, isCompleted INTEGER NOT NULL,
        category TEXT, quantity REAL DEFAULT 1, recipeId TEXT, notes TEXT,
        listId TEXT DEFAULT 'default'
      )
    ''');
    
    await db.execute('CREATE TABLE shopping_groups (id TEXT PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('CREATE TABLE user_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');

    await db.execute('''
      CREATE TABLE meal_routine (
        id TEXT PRIMARY KEY, date TEXT NOT NULL, mealType INTEGER NOT NULL,
        recipeId TEXT, manualEntry TEXT, time TEXT, isEaten INTEGER NOT NULL,
        calories REAL, protein REAL, carbs REAL, fat REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE receipts (
        id TEXT PRIMARY KEY, date TEXT NOT NULL, imageUrl TEXT, totalAmount REAL, items TEXT
      )
    ''');
  }

  Future _createScanHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scan_history (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, barcode TEXT, brand TEXT,
        imageUrl TEXT, nutriScore TEXT, allergens TEXT NOT NULL,
        ingredientsText TEXT, location INTEGER NOT NULL, expiryDate TEXT,
        addedDate TEXT NOT NULL, calories REAL NOT NULL, protein REAL NOT NULL,
        carbs REAL NOT NULL, fat REAL NOT NULL, saturatedFat REAL NOT NULL,
        sodium REAL NOT NULL, cholesterol REAL NOT NULL, fiber REAL NOT NULL,
        sugar REAL NOT NULL, potassium REAL NOT NULL DEFAULT 0,
        magnesium REAL NOT NULL DEFAULT 0, vitaminC REAL NOT NULL DEFAULT 0,
        vitaminD REAL NOT NULL DEFAULT 0, calcium REAL NOT NULL DEFAULT 0,
        iron REAL NOT NULL DEFAULT 0, price REAL
      )
    ''');
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy, limit: limit);
  }

  Future<void> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Specialized methods
  Future<void> insertFoodItem(FoodItem item) => insert('food_items', item.toMap());
  Future<List<FoodItem>> getPantryItems() async {
    final res = await query('food_items');
    return res.map((json) => FoodItem.fromMap(json)).toList();
  }
  Future<void> deleteFoodItem(String id) => delete('food_items', where: 'id = ?', whereArgs: [id]);
  Future<void> insertScanHistory(FoodItem item) => insert('scan_history', item.toMap());
  Future<List<FoodItem>> getScanHistory() async {
    final res = await query('scan_history', orderBy: 'addedDate DESC', limit: 50);
    return res.map((json) => FoodItem.fromMap(json)).toList();
  }
  Future<void> insertRecipe(Recipe recipe) => insert('recipes', recipe.toMap());
  Future<List<Recipe>> getRecipes() async {
    final res = await query('recipes');
    return res.map((json) => Recipe.fromMap(json)).toList();
  }
  Future<void> insertMealLog(MealLog log) => insert('meal_logs', log.toMap());
  Future<List<MealLog>> getMealLogs(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final res = await query('meal_logs', where: 'consumedAt BETWEEN ? AND ?', whereArgs: [startOfDay, endOfDay]);
    return res.map((json) => MealLog.fromMap(json)).toList();
  }
  Future<void> deleteMealLog(String id) => delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  Future<void> insertHealthEntry(HealthEntry entry) => insert('health_entries', entry.toMap());
  Future<HealthEntry?> getHealthEntryForDate(DateTime date) async {
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    final result = await query('health_entries', where: 'date LIKE ?', whereArgs: ['$dateStr%']);
    return result.isNotEmpty ? HealthEntry.fromMap(result.first) : null;
  }
  Future<List<HealthEntry>> getAllHealthEntries() async {
    final result = await query('health_entries', orderBy: 'date ASC');
    return result.map((json) => HealthEntry.fromMap(json)).toList();
  }
  Future<void> saveSetting(String key, String value) => insert('user_settings', {'key': key, 'value': value});
  Future<String?> getSetting(String key) async {
    final res = await query('user_settings', where: 'key = ?', whereArgs: [key]);
    return res.isNotEmpty ? res.first['value'] as String : null;
  }
  Future<void> insertMealRoutine(MealRoutine routine) => insert('meal_routine', routine.toMap());
  Future<List<MealRoutine>> getMealRoutine(DateTime date) async {
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    return (await query('meal_routine', where: 'date LIKE ?', whereArgs: ['$dateStr%'])).map((j) => MealRoutine.fromMap(j)).toList();
  }
  Future<void> deleteMealRoutine(String id) => delete('meal_routine', where: 'id = ?', whereArgs: [id]);
}
