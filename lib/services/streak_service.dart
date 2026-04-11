import '../services/database_service.dart';
import '../models/meal_log.dart';

class StreakService {
  static final StreakService instance = StreakService._();
  StreakService._();

  final _db = DatabaseService.instance;

  // ── Healthy Food Streak ─────────────────────────────────────────────────────
  Future<int> getHealthyFoodStreak() async {
    final grouped = await _getAllLogsGroupedByDay();
    return _computeStreak(grouped, _isDayHealthy);
  }

  bool _isDayHealthy(List<MealLog> logs) {
    if (logs.isEmpty) return false;
    double totalFiber = 0, totalSugar = 0, totalSatFat = 0, totalCalories = 0;
    for (final l in logs) {
      totalFiber += l.fiber;
      totalSugar += l.sugar;
      totalSatFat += l.saturatedFat;
      totalCalories += l.calories;
    }
    return totalCalories > 300 &&
        totalFiber >= 8 &&
        totalSugar <= 40 &&
        totalSatFat <= 15;
  }

  // ── No Waste Streak ─────────────────────────────────────────────────────────
  Future<int> getNoWasteStreak() async {
    final allItems = await _db.getPantryItems();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final wasteDays = <String>{};
    for (final item in allItems) {
      if (item.expiryDate != null && item.expiryDate!.isBefore(today)) {
        wasteDays.add(_dayKey(item.expiryDate!));
      }
    }

    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      if (wasteDays.contains(_dayKey(day))) break;
      streak++;
    }

    if (streak == 365 || wasteDays.isEmpty) {
      if (allItems.isEmpty) return 1;
      final oldest = allItems
          .map((i) => i.addedDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysSinceStart = today
          .difference(DateTime(oldest.year, oldest.month, oldest.day))
          .inDays;
      return daysSinceStart.clamp(1, 365);
    }

    return streak;
  }

  // ── Addiction Clean Streak ──────────────────────────────────────────────────
  Future<int> getAddictionCleanStreak() async {
    final grouped = await _getAllLogsGroupedByDay();
    return _computeStreak(grouped, _isDayClean);
  }

  bool _isDayClean(List<MealLog> logs) {
    if (logs.isEmpty) return false;
    double satFat = 0, sugar = 0, sodium = 0, cholesterol = 0;
    for (final l in logs) {
      satFat += l.saturatedFat;
      sugar += l.sugar;
      sodium += l.sodium;
      cholesterol += l.cholesterol;
    }
    return satFat <= 20 && sugar <= 30 && sodium <= 2300 && cholesterol <= 300;
  }

  // ── Water Streak ─────────────────────────────────────────────────────────────
  // A day is "hydrated" if water intake >= 1500ml (customizable threshold)
  Future<int> getWaterStreak({double goalMl = 1500}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    for (int i = 0; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      final startStr = DateTime(day.year, day.month, day.day).toIso8601String();
      final endStr = DateTime(day.year, day.month, day.day, 23, 59, 59).toIso8601String();

      final rows = await _db.query(
        'water_logs',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [startStr, endStr],
      );

      final totalMl = rows.fold(0.0, (sum, r) => sum + ((r['ml'] as num?)?.toDouble() ?? 0));

      // Skip today if no logs yet — don't break the streak
      if (i == 0 && totalMl == 0) continue;

      if (totalMl < goalMl) break;
      streak++;
    }
    return streak;
  }

  // ── Calorie Streak ───────────────────────────────────────────────────────────
  // A day is "on-target" if calories logged are between minKcal and maxKcal
  Future<int> getCalorieStreak({
    double minKcal = 1200,
    double maxKcal = 2500,
  }) async {
    final grouped = await _getAllLogsGroupedByDay();
    return _computeStreak(grouped, (logs) {
      if (logs.isEmpty) return false;
      final total = logs.fold(0.0, (s, l) => s + l.calories);
      return total >= minKcal && total <= maxKcal;
    });
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<Map<String, List<MealLog>>> _getAllLogsGroupedByDay() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365));
    final res = await _db.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [
        DateTime(start.year, start.month, start.day).toIso8601String(),
        DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String(),
      ],
      orderBy: 'consumedAt ASC',
    );
    final logs = res.map((j) => MealLog.fromMap(j)).toList();

    final grouped = <String, List<MealLog>>{};
    for (final log in logs) {
      final key = _dayKey(log.consumedAt);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  int _computeStreak(
      Map<String, List<MealLog>> grouped,
      bool Function(List<MealLog>) isGood,
      ) {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    int streak = 0;

    for (int i = 0; i <= 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final key = _dayKey(day);
      final logsForDay = grouped[key] ?? [];

      if (key == todayKey && logsForDay.isEmpty) continue;
      if (logsForDay.isEmpty) break;
      if (!isGood(logsForDay)) break;

      streak++;
    }
    return streak;
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}