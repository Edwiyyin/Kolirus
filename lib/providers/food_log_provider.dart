import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../models/meal_type.dart';
import '../services/database_service.dart';

final foodLogProvider = StateNotifierProvider<FoodLogNotifier, List<MealLog>>((ref) {
  return FoodLogNotifier();
});

class FoodLogNotifier extends StateNotifier<List<MealLog>> {
  FoodLogNotifier() : super([]) {
    loadLogs(DateTime.now());
  }

  final _db = DatabaseService.instance;

  Future<void> loadLogs(DateTime date) async {
    state = await _db.getMealLogs(date);
  }

  Future<List<MealLog>> getLogsForRange(DateTime start, DateTime end) async {
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
    
    final res = await _db.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [startStr, endStr],
      orderBy: 'consumedAt ASC',
    );
    return res.map((json) => MealLog.fromMap(json)).toList();
  }

  Future<void> addLog(MealLog log) async {
    await _db.insertMealLog(log);
    await loadLogs(DateTime.now());
  }

  Future<void> updateLog(MealLog log) async {
    await _db.insertMealLog(log);
    await loadLogs(DateTime.now());
  }

  Future<void> removeLog(String logId) async {
    await _db.deleteMealLog(logId);
    await loadLogs(DateTime.now());
  }

  Future<void> removeLogByRoutineId(String foodItemId, String foodName) async {
    final toRemove = state.where((l) =>
    l.foodItemId == foodItemId && l.foodName == foodName
    ).toList();
    for (final log in toRemove) {
      if (log.id != null) await _db.deleteMealLog(log.id!);
    }
    await loadLogs(DateTime.now());
  }

  Future<void> addMeal(FoodItem item, double quantity, MealType type) async {
    final ratio = quantity / 100.0;
    final log = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: item.id ?? item.barcode ?? 'unknown',
      foodName: item.name,
      quantity: quantity,
      consumedAt: DateTime.now(),
      type: type,
      calories: item.calories * ratio,
      protein: item.protein * ratio,
      carbs: item.carbs * ratio,
      fat: item.fat * ratio,
      saturatedFat: item.saturatedFat * ratio,
      sodium: item.sodium * ratio,
      cholesterol: item.cholesterol * ratio,
      fiber: item.fiber * ratio,
      sugar: item.sugar * ratio,
      potassium: (item.potassium) * ratio,
      magnesium: (item.magnesium) * ratio,
      vitaminC: (item.vitaminC) * ratio,
      vitaminD: (item.vitaminD) * ratio,
      calcium: (item.calcium) * ratio,
      iron: (item.iron) * ratio,
      price: (item.price ?? 0) * ratio,
    );
    await addLog(log);
  }

  Map<String, double> getDailyTotals() {
    double calories = 0, protein = 0, carbs = 0, fat = 0, sugar = 0,
        saturatedFat = 0, sodium = 0, cholesterol = 0, fiber = 0,
        potassium = 0, magnesium = 0, vitaminC = 0, vitaminD = 0,
        calcium = 0, iron = 0, price = 0;
    for (var log in state) {
      calories += log.calories;
      protein += log.protein;
      carbs += log.carbs;
      fat += log.fat;
      sugar += log.sugar;
      saturatedFat += log.saturatedFat;
      sodium += log.sodium;
      cholesterol += log.cholesterol;
      fiber += log.fiber;
      potassium += log.potassium;
      magnesium += log.magnesium;
      vitaminC += log.vitaminC;
      vitaminD += log.vitaminD;
      calcium += log.calcium;
      iron += log.iron;
      price += log.price ?? 0;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
      'saturatedFat': saturatedFat,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'fiber': fiber,
      'potassium': potassium,
      'magnesium': magnesium,
      'vitaminC': vitaminC,
      'vitaminD': vitaminD,
      'calcium': calcium,
      'iron': iron,
      'price': price,
    };
  }
}
