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
      version: 6, // Incremented for recipe columns
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
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE meal_routine (
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
      await db.execute('ALTER TABLE food_items ADD COLUMN ingredientsText TEXT');
      await db.execute('ALTER TABLE scan_history ADD COLUMN ingredientsText TEXT');
    }
    if (oldVersion < 6) {
      // Add missing columns to recipes table
      await db.execute('ALTER TABLE recipes ADD COLUMN prepTime INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recipes ADD COLUMN cookTime INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE recipes ADD COLUMN servings INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE recipes ADD COLUMN category TEXT DEFAULT "Lunch"');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const floatType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE food_items (
        id $idType,
        name $textType,
        barcode $textTypeNullable,
        brand $textTypeNullable,
        imageUrl $textTypeNullable,
        nutriScore $textTypeNullable,
        allergens $textType,
        ingredientsText $textTypeNullable,
        location $intType,
        expiryDate $textTypeNullable,
        addedDate $textType,
        calories $floatType,
        protein $floatType,
        carbs $floatType,
        fat $floatType,
        saturatedFat $floatType,
        sodium $floatType,
        cholesterol $floatType,
        fiber $floatType,
        sugar $floatType
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes (
        id $idType,
        name $textType,
        description $textTypeNullable,
        ingredients $textType,
        instructions $textType,
        imageUrl $textTypeNullable,
        isCommunityShared $boolType,
        prepTime INTEGER NOT NULL DEFAULT 0,
        cookTime INTEGER NOT NULL DEFAULT 0,
        servings INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT 'Lunch'
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_logs (
        id $idType,
        foodItemId $textType,
        foodName $textType,
        quantity $floatType,
        consumedAt $textType,
        type $intType,
        calories $floatType,
        protein $floatType,
        carbs $floatType,
        fat $floatType,
        saturatedFat $floatType,
        sodium $floatType,
        cholesterol $floatType,
        fiber $floatType,
        sugar $floatType
      )
    ''');

    await db.execute('''
      CREATE TABLE health_entries (
        id $idType,
        date $textType,
        weight $floatType,
        bodyMass $floatType,
        cholesterol $floatType,
        steps $intType
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
        isEaten INTEGER NOT NULL
      )
    ''');
  }

  Future _createScanHistoryTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const floatType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE scan_history (
        id $idType,
        name $textType,
        barcode $textTypeNullable,
        brand $textTypeNullable,
        imageUrl $textTypeNullable,
        nutriScore $textTypeNullable,
        allergens $textType,
        ingredientsText $textTypeNullable,
        location $intType,
        expiryDate $textTypeNullable,
        addedDate $textType,
        calories $floatType,
        protein $floatType,
        carbs $floatType,
        fat $floatType,
        saturatedFat $floatType,
        sodium $floatType,
        cholesterol $floatType,
        fiber $floatType,
        sugar $floatType
      )
    ''');
  }

  // Food Items (Pantry)
  Future<void> insertFoodItem(FoodItem item) async {
    final db = await instance.database;
    await db.insert('food_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FoodItem>> getPantryItems() async {
    final db = await instance.database;
    final result = await db.query('food_items');
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  Future<void> deleteFoodItem(String id) async {
    final db = await instance.database;
    await db.delete('food_items', where: 'id \u003d ?', whereArgs: [id]);
  }

  // Scan History
  Future<void> insertScanHistory(FoodItem item) async {
    final db = await instance.database;
    await db.insert('scan_history', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FoodItem>> getScanHistory() async {
    final db = await instance.database;
    final result = await db.query('scan_history', orderBy: 'addedDate DESC', limit: 50);
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  // Recipes
  Future<void> insertRecipe(Recipe recipe) async {
    final db = await instance.database;
    await db.insert('recipes', recipe.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Recipe>> getRecipes() async {
    final db = await instance.database;
    final result = await db.query('recipes');
    return result.map((json) => Recipe.fromMap(json)).toList();
  }

  // Meal Logs
  Future<void> insertMealLog(MealLog log) async {
    final db = await instance.database;
    await db.insert('meal_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MealLog>> getMealLogs(DateTime date) async {
    final db = await instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    
    final result = await db.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
    return result.map((json) => MealLog.fromMap(json)).toList();
  }

  Future<void> deleteMealLog(String id) async {
    final db = await instance.database;
    await db.delete('meal_logs', where: 'id \u003d ?', whereArgs: [id]);
  }

  // Health Entries
  Future<void> insertHealthEntry(HealthEntry entry) async {
    final db = await instance.database;
    await db.insert('health_entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HealthEntry?> getHealthEntryForDate(DateTime date) async {
    final db = await instance.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    
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
    final result = await db.query('health_entries', orderBy: 'date ASC');
    return result.map((json) => HealthEntry.fromMap(json)).toList();
  }

  // Shopping List
  Future<void> insertShoppingItem(Map<String, dynamic> item) async {
    final db = await instance.database;
    await db.insert('shopping_list', item, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getShoppingList() async {
    final db = await instance.database;
    return await db.query('shopping_list');
  }

  Future<void> deleteShoppingItem(String id) async {
    final db = await instance.database;
    await db.delete('shopping_list', where: 'id \u003d ?', whereArgs: [id]);
  }

  // User Settings
  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert('user_settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final result = await db.query('user_settings', where: 'key \u003d ?', whereArgs: [key]);
    if (result.isNotEmpty) {
      return result.first['value'] as String;
    }
    return null;
  }

  // Meal Routine
  Future<void> insertMealRoutine(MealRoutine routine) async {
    final db = await instance.database;
    await db.insert('meal_routine', routine.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MealRoutine>> getMealRoutine(DateTime date) async {
    final db = await instance.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
    final result = await db.query('meal_routine', where: 'date LIKE ?', whereArgs: ['$dateStr%']);
    return result.map((json) => MealRoutine.fromMap(json)).toList();
  }

  Future<void> deleteMealRoutine(String id) async {
    final db = await instance.database;
    await db.delete('meal_routine', where: 'id \u003d ?', whereArgs: [id]);
  }
}
