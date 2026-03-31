import 'package:flutter/material.dart';

enum MealType { Breakfast, Lunch, Dinner, Snack }

class MealRoutine {
  final String id;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final MealType mealType;
  final String? recipeId;
  final String? manualEntry;
  final String? time;

  MealRoutine({
    required this.id,
    required this.dayOfWeek,
    required this.mealType,
    this.recipeId,
    this.manualEntry,
    this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'mealType': mealType.index,
      'recipeId': recipeId,
      'manualEntry': manualEntry,
      'time': time,
    };
  }

  factory MealRoutine.fromMap(Map<String, dynamic> map) {
    return MealRoutine(
      id: map['id'],
      dayOfWeek: map['dayOfWeek'],
      mealType: MealType.values[map['mealType']],
      recipeId: map['recipeId'],
      manualEntry: map['manualEntry'],
      time: map['time'],
    );
  }
}
