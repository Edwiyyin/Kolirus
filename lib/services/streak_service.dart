import '../services/database_service.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';

class StreakService {
  static final StreakService instance = StreakService._();
  StreakService._();

  final _db = DatabaseService.instance;

  // ── Healthy Food Streak ────────────────────────────────────────────────────
  // A day is "healthy" if avg NutriScore is A/B OR fiber >= 15g AND sugar <= 30g AND saturatedFat <= 10g
  Future<int> getHealthyFoodStreak() async {
    final logs = await _getAllLogsGroupedByDay();
    return _computeStreak(logs.keys.toList()..sort(), (day) {
      final dayLogs = logs[day]!;
      return _isDayHealthy(dayLogs);
    });
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
    // Must have eaten something (> 500 kcal) and meet thresholds
    return totalCalories > 500 && totalFiber >= 10 && totalSugar <= 40 && totalSatFat <= 15;
  }

  // ── No Waste Streak ────────────────────────────────────────────────────────
  // A day is "no waste" if no pantry item expired that day (expiryDate == that day but item still in pantry)
  Future<int> getNoWasteStreak() async {
    final allItems = await _db.getPantryItems();
    final now = DateTime.now();

    // Group expired items by expiry date
    final expiredDays = <String>{};
    for (final item in allItems) {
      if (item.expiryDate != null && item.expiryDate!.isBefore(now)) {
        expiredDays.add(_dayKey(item.expiryDate!));
      }
    }

    // Count consecutive days backwards from yesterday with no waste
    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if (expiredDays.contains(_dayKey(day))) break;
      streak++;
    }
    return streak;
  }

  // ── Addiction Streak ───────────────────────────────────────────────────────
  // A day is "clean" if saturatedFat <= 20g AND sugar <= 30g AND sodium <= 2300mg AND cholesterol <= 300mg
  Future<int> getAddictionCleanStreak() async {
    final logs = await _getAllLogsGroupedByDay();
    return _computeStreak(logs.keys.toList()..sort(), (day) {
      final dayLogs = logs[day]!;
      return _isDayClean(dayLogs);
    });
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

  // ── Internal helpers ───────────────────────────────────────────────────────

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

  int _computeStreak(List<String> sortedDays, bool Function(String) isGood) {
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    int streak = 0;

    for (int i = 0; i <= 365; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final key = _dayKey(day);

      // Skip today if no logs yet (don't break streak for an incomplete day)
      if (key == todayKey && !sortedDays.contains(key)) continue;
      if (!sortedDays.contains(key)) break;
      if (!isGood(key)) break;
      streak++;
    }
    return streak;
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}