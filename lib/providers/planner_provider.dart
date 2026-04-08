import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/meal_type.dart';

part 'planner_provider.g.dart';

class MealSlot {
  final String? name;
  final String? recipeId;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  MealSlot({this.name, this.recipeId, this.calories, this.protein, this.carbs, this.fat});

  bool get isEmpty => name == null || name!.isEmpty;
}

@Riverpod(keepAlive: true)
class PlannerTemplate extends _$PlannerTemplate {
  @override
  Map<int, Map<int, Map<MealType, MealSlot>>> build() {
    // Initialize an empty template structure
    // Week -> Day (0-6) -> MealType -> Slot
    return {
      0: List.generate(7, (_) => {
        MealType.breakfast: MealSlot(),
        MealType.lunch: MealSlot(),
        MealType.snack: MealSlot(),
        MealType.dinner: MealSlot(),
      }).asMap(),
    };
  }

  void updateSlot(int wi, int di, MealType meal, MealSlot slot) {
    final newState = Map<int, Map<int, Map<MealType, MealSlot>>>.from(state);
    if (!newState.containsKey(wi)) newState[wi] = {};

    final newWeek = Map<int, Map<MealType, MealSlot>>.from(newState[wi]!);
    final newDay = Map<MealType, MealSlot>.from(newWeek[di]!);

    newDay[meal] = slot;
    newWeek[di] = newDay;
    newState[wi] = newWeek;

    state = newState;
  }

  void clearSlot(int wi, int di, MealType meal) {
    updateSlot(wi, di, meal, MealSlot());
  }
}