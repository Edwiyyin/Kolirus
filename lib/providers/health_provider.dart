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
    var entry = await _db.getHealthEntryForDate(todayDate);
    
    if (entry == null) {
      final hasPermission = await _healthService.requestPermissions();
      if (hasPermission) {
        entry = await _healthService.fetchTodayHealthData();
        await _db.insertHealthEntry(entry);
      } else {
        // Create an empty entry if no permission
        entry = HealthEntry(date: DateTime(todayDate.year, todayDate.month, todayDate.day));
        await _db.insertHealthEntry(entry);
      }
    }

    // Load all history for charts/tracking
    final history = await _db.getAllHealthEntries();
    
    state = HealthState(today: entry, history: history);
  }

  Future<void> updateManualEntry({double? weight, double? cholesterol, double? bodyMass, DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    var existing = await _db.getHealthEntryForDate(normalizedDate);
    
    final updated = HealthEntry(
      id: existing?.id ?? normalizedDate.millisecondsSinceEpoch.toString(),
      date: normalizedDate,
      weight: weight ?? existing?.weight ?? 0.0,
      bodyMass: bodyMass ?? existing?.bodyMass ?? 0.0,
      cholesterol: cholesterol ?? existing?.cholesterol ?? 0.0,
      steps: existing?.steps ?? 0,
    );

    await _db.insertHealthEntry(updated);
    await loadData();
  }

  Future<void> syncWithGoogleFit() async {
    final entry = await _healthService.fetchTodayHealthData();
    await _db.insertHealthEntry(entry);
    await loadData();
  }
}
