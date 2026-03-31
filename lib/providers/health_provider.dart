import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_entry.dart';
import '../services/health_service.dart';
import '../services/database_service.dart';

final healthProvider = StateNotifierProvider<HealthNotifier, HealthEntry?>((ref) {
  return HealthNotifier();
});

class HealthNotifier extends StateNotifier<HealthEntry?> {
  HealthNotifier() : super(null) {
    loadTodayData();
  }

  final _healthService = HealthService();
  final _db = DatabaseService.instance;

  Future<void> loadTodayData() async {
    final today = DateTime.now();
    var entry = await _db.getHealthEntryForDate(today);
    
    if (entry == null) {
      final hasPermission = await _healthService.requestPermissions();
      if (hasPermission) {
        entry = await _healthService.fetchTodayHealthData();
        await _db.insertHealthEntry(entry);
      }
    }
    state = entry;
  }

  Future<void> updateManualEntry({double? weight, double? cholesterol, double? bodyMass}) async {
    if (state == null) return;
    
    final updated = HealthEntry(
      id: state!.id,
      date: state!.date,
      weight: weight ?? state!.weight,
      bodyMass: bodyMass ?? state!.bodyMass,
      cholesterol: cholesterol ?? state!.cholesterol,
      steps: state!.steps,
    );

    await _db.insertHealthEntry(updated);
    state = updated;
  }

  Future<void> syncWithGoogleFit() async {
    final entry = await _healthService.fetchTodayHealthData();
    await _db.insertHealthEntry(entry);
    state = entry;
  }
}
