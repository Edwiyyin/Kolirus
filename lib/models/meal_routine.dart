import 'package:flutter/material.dart';
import 'meal_type.dart';

class MealRoutine {
  final String id;
  final DateTime date;
  final MealType mealType;
  final String? recipeId;
  final String? manualEntry;
  final String? time;
  final bool isEaten;

  MealRoutine({
    required this.id,
    required this.date,
    required this.mealType,
    this.recipeId,
    this.manualEntry,
    this.time,
    this.isEaten = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mealType': mealType.index,
      'recipeId': recipeId,
      'manualEntry': manualEntry,
      'time': time,
      'isEaten': isEaten ? 1 : 0,
    };
  }

  factory MealRoutine.fromMap(Map<String, dynamic> map) {
    return MealRoutine(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mealType: MealType.values[map['mealType'] ?? 0],
      recipeId: map['recipeId'],
      manualEntry: map['manualEntry'],
      time: map['time'],
      isEaten: map['isEaten'] == 1,
    );
  }

  MealRoutine copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    String? recipeId,
    String? manualEntry,
    String? time,
    bool? isEaten,
  }) {
    return MealRoutine(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      manualEntry: manualEntry ?? this.manualEntry,
      time: time ?? this.time,
      isEaten: isEaten ?? this.isEaten,
    );
  }
}
