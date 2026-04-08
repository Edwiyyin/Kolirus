import '../services/database_service.dart';
import '../models/meal_log.dart';

class StreakService {
  static final StreakService instance = StreakService._();
  StreakService._();

  final _db = DatabaseService.instance;

  // ── Healthy Food Streak ─────────────────────────────────────────────────────
  // A day is "healthy" if calories > 300 AND fiber >= 8g AND sugar <= 40g AND saturatedFat <= 15g
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
  // Counts consecutive days going backwards from today where no item expired
  // while still in the pantry (i.e. was not consumed before expiry).
  // If pantry has no expired items at all, counts days since app start (up to 365).
  Future<int> getNoWasteStreak() async {
    final allItems = await _db.getPantryItems();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a set of days where waste happened (item expired while still in pantry)
    final wasteDays = <String>{};
    for (final item in allItems) {
      if (item.expiryDate != null && item.expiryDate!.isBefore(today)) {
        wasteDays.add(_dayKey(item.expiryDate!));
      }
    }

    // Walk backwards from yesterday counting clean days
    int streak = 0;
    for (int i = 1; i <= 365; i++) {
      final day = today.subtract(Duration(days: i));
      if (wasteDays.contains(_dayKey(day))) break;
      streak++;
    }

    // If no waste ever, return days since the first pantry item was added
    // (or a sensible default of 1 so the user sees progress immediately)
    if (streak == 365 || wasteDays.isEmpty) {
      // Find oldest item addedDate to compute real streak
      if (allItems.isEmpty) return 1;
      final oldest = allItems
          .map((i) => i.addedDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysSinceStart = today.difference(
        DateTime(oldest.year, oldest.month, oldest.day),
      ).inDays;
      return daysSinceStart.clamp(1, 365);
    }

    return streak;
  }

  // ── Addiction Clean Streak ──────────────────────────────────────────────────
  // A day is "clean" if saturatedFat <= 20g AND sugar <= 30g AND sodium <= 2300mg AND cholesterol <= 300mg
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

  /// Walk backwards from today counting consecutive qualifying days.
  /// Today is included only if it already has logs (partial day is OK if it passes).
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

      // Skip today entirely if no logs yet — don't break the streak
      if (key == todayKey && logsForDay.isEmpty) continue;

      // If we have no logs for a past day, streak is broken
      if (logsForDay.isEmpty) break;

      // If the day doesn't meet the threshold, streak is broken
      if (!isGood(logsForDay)) break;

      streak++;
    }
    return streak;
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}