import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_entry.dart';
import '../services/health_service.dart';
import '../services/database_service.dart';

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});

class HealthState {
  final HealthEntry? today;
  final List<HealthEntry> history;

  HealthState({this.today, this.history = const []});
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(HealthState()) {
    loadData();
  }

  final _healthService = HealthService();
  final _db = DatabaseService.instance;

  Future<void> loadData() async {
    final todayDate = DateTime.now();
    final normalizedToday = DateTime(todayDate.year, todayDate.month, todayDate.day);
    
    // 1. Get all history
    var history = await _db.getAllHealthEntries();
    
    // 2. Get today's entry from database
    var entry = await _db.getHealthEntryForDate(normalizedToday);
    
    // 3. If missing from DB, try to fetch from Health Service or create empty
    if (entry == null) {
      try {
        entry = await _healthService.fetchTodayHealthData().timeout(const Duration(seconds: 1));
      } catch (e) {
        entry = HealthEntry(date: normalizedToday);
      }
    }

    // 4. PERSISTENCE LOGIC: If values are 0, carry over the most recent non-zero values from ANY past date
    double finalHeight = entry.height;
    double finalWeight = entry.weight;
    double finalBMI = entry.bodyMass;
    double finalCholesterol = entry.cholesterol;

    // Iterate through history backwards to find the latest valid data
    for (var pastEntry in history.reversed) {
      // Don't carry over from today's own record if it's the one we are trying to fix
      if (DateUtils.isSameDay(pastEntry.date, normalizedToday)) continue;

      if (finalHeight == 0 && pastEntry.height > 0) finalHeight = pastEntry.height;
      if (finalWeight == 0 && pastEntry.weight > 0) finalWeight = pastEntry.weight;
      if (finalBMI == 0 && pastEntry.bodyMass > 0) finalBMI = pastEntry.bodyMass;
      if (finalCholesterol == 0 && pastEntry.cholesterol > 0) finalCholesterol = pastEntry.cholesterol;

      // Optimization: stop if we have height and weight
      if (finalHeight > 0 && finalWeight > 0) break;
    }

    // Create the "Official" today entry with carried over values
    final officialToday = HealthEntry(
      id: entry.id,
      date: normalizedToday,
      height: finalHeight,
      weight: finalWeight,
      bodyMass: finalBMI,
      cholesterol: finalCholesterol,
      steps: entry.steps,
    );

    // Save it to DB so it exists for future queries
    await _db.insertHealthEntry(officialToday);
    
    // Reload history to ensure it includes the corrected today entry
    final updatedHistory = await _db.getAllHealthEntries();

    state = HealthState(today: officialToday, history: updatedHistory);
  }

  Future<void> updateManualEntry({double? weight, double? cholesterol, double? bodyMass, double? height, DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    var existing = await _db.getHealthEntryForDate(normalizedDate);
    
    // Calculate BMI if height and weight are available
    double calculatedBMI = bodyMass ?? existing?.bodyMass ?? 0.0;
    double currentWeight = weight ?? existing?.weight ?? 0.0;
    double currentHeight = height ?? existing?.height ?? 0.0;

    if (currentWeight > 0 && currentHeight > 0) {
      calculatedBMI = currentWeight / ((currentHeight / 100) * (currentHeight / 100));
    }

    final updated = HealthEntry(
      id: existing?.id ?? normalizedDate.toIso8601String().split('T')[0],
      date: normalizedDate,
      weight: currentWeight,
      bodyMass: calculatedBMI,
      height: currentHeight,
      cholesterol: cholesterol ?? existing?.cholesterol ?? 0.0,
      steps: existing?.steps ?? 0,
    );

    await _db.insertHealthEntry(updated);
    await loadData();
  }

  Future<void> syncWithGoogleFit() async {
    try {
      final entry = await _healthService.fetchTodayHealthData();
      await _db.insertHealthEntry(entry);
      await loadData();
    } catch (_) {}
  }
}
