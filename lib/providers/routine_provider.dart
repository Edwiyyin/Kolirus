import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_routine.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
import 'food_log_provider.dart';

// State holds ALL loaded entries across all dates
class RoutineState {
  final Map<String, List<MealRoutine>> byDate; // key: 'yyyy-MM-dd'

  const RoutineState({this.byDate = const {}});

  List<MealRoutine> forDate(DateTime date) {
    final key = _dayKey(date);
    return byDate[key] ?? [];
  }

  RoutineState copyWith(String key, List<MealRoutine> entries) {
    final newMap = Map<String, List<MealRoutine>>.from(byDate);
    newMap[key] = entries;
    return RoutineState(byDate: newMap);
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final routineProvider =
StateNotifierProvider<RoutineNotifier, RoutineState>((ref) {
  return RoutineNotifier(ref);
});

class RoutineNotifier extends StateNotifier<RoutineState> {
  final Ref _ref;
  RoutineNotifier(this._ref) : super(const RoutineState()) {
    loadRoutine(DateTime.now());
  }

  final _db = DatabaseService.instance;

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadRoutine(DateTime date) async {
    final key = _dayKey(date);
    final entries = await _db.getMealRoutine(date);
    state = state.copyWith(key, entries);
  }

  Future<void> addEntry(MealRoutine entry) async {
    await _db.insertMealRoutine(entry);
    await loadRoutine(entry.date);
  }

  Future<void> updateEntry(MealRoutine entry) async {
    await _db.insertMealRoutine(entry);
    await loadRoutine(entry.date);
  }

  Future<void> toggleEaten(MealRoutine entry) async {
    final updated = entry.copyWith(isEaten: !entry.isEaten);
    await _db.insertMealRoutine(updated);

    if (updated.isEaten) {
      double calories = 0,
          protein = 0,
          carbs = 0,
          fat = 0,
          saturatedFat = 0,
          sodium = 0,
          cholesterol = 0,
          fiber = 0,
          sugar = 0;

      if (entry.recipeId != null) {
        final recipes = await _db.getRecipes();
        final recipe = recipes.where((r) => r.id == entry.recipeId).isNotEmpty
            ? recipes.firstWhere((r) => r.id == entry.recipeId)
            : null;
        if (recipe != null) {
          calories = recipe.calories;
          protein = recipe.protein;
          carbs = recipe.carbs;
          fat = recipe.fat;
          saturatedFat = recipe.saturatedFat;
          sodium = recipe.sodium;
          cholesterol = recipe.cholesterol;
          fiber = recipe.fiber;
          sugar = recipe.sugar;
        }
      } else if (entry.calories != null) {
        calories = entry.calories ?? 0;
        protein = entry.protein ?? 0;
        carbs = entry.carbs ?? 0;
        fat = entry.fat ?? 0;
      }

      final log = MealLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foodItemId: entry.recipeId ?? 'routine',
        foodName: entry.manualEntry ?? 'Planned Meal',
        quantity: 1.0,
        consumedAt: DateTime.now(),
        type: entry.mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        saturatedFat: saturatedFat,
        sodium: sodium,
        cholesterol: cholesterol,
        fiber: fiber,
        sugar: sugar,
      );
      await _ref.read(foodLogProvider.notifier).addLog(log);
    } else {
      await _ref.read(foodLogProvider.notifier).removeLogByRoutineId(
        entry.recipeId ?? 'routine',
        entry.manualEntry ?? 'Planned Meal',
      );
    }

    await loadRoutine(entry.date);
  }

  Future<void> removeEntry(MealRoutine entry) async {
    await _db.deleteMealRoutine(entry.id);
    await loadRoutine(entry.date);
  }
}