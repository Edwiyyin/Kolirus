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

  Future<void> addLog(MealLog log) async {
    await _db.insertMealLog(log);
    await loadLogs(DateTime.now());
  }

  Future<void> removeLog(String logId) async {
    await _db.deleteMealLog(logId);
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
    );

    await addLog(log);
  }

  Map<String, double> getDailyTotals() {
    double calories = 0, protein = 0, carbs = 0, fat = 0, sugar = 0;
    for (var log in state) {
      calories += log.calories;
      protein += log.protein;
      carbs += log.carbs;
      fat += log.fat;
      sugar += log.sugar;
    }
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sugar': sugar,
    };
  }
}
