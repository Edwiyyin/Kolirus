import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_routine.dart';
import '../models/meal_log.dart';
import '../services/database_service.dart';
import 'food_log_provider.dart';

final routineProvider = StateNotifierProvider<RoutineNotifier, List<MealRoutine>>((ref) {
  return RoutineNotifier(ref);
});

class RoutineNotifier extends StateNotifier<List<MealRoutine>> {
  final Ref _ref;
  RoutineNotifier(this._ref) : super([]) {
    loadRoutine(DateTime.now());
  }

  final _db = DatabaseService.instance;

  Future<void> loadRoutine(DateTime date) async {
    final routine = await _db.getMealRoutine(date);
    state = routine;
  }

  Future<void> addEntry(MealRoutine entry) async {
    await _db.insertMealRoutine(entry);
    await loadRoutine(entry.date);
  }

  Future<void> toggleEaten(MealRoutine entry) async {
    final updated = entry.copyWith(isEaten: !entry.isEaten);
    await _db.insertMealRoutine(updated);
    
    if (updated.isEaten) {
      // Log the meal
      final log = MealLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foodItemId: entry.recipeId ?? 'manual',
        foodName: entry.manualEntry ?? 'Planned Meal',
        quantity: 1.0,
        consumedAt: DateTime.now(),
        type: entry.mealType,
        // If it's a manual entry from routine, we don't have full macros here
        // Ideally we'd fetch the recipe if recipeId exists
      );
      await _ref.read(foodLogProvider.notifier).addLog(log);
    }
    
    await loadRoutine(entry.date);
  }

  Future<void> removeEntry(MealRoutine entry) async {
    await _db.deleteMealRoutine(entry.id);
    await loadRoutine(entry.date);
  }
}
