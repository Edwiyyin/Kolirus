import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/meal_log.dart';
import '../models/health_entry.dart';

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
      version: 1,
      onCreate: _createDB,
    );
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
        isCommunityShared $boolType
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
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
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
}
