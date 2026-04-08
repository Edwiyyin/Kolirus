import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final waterProvider =
StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier();
});

class WaterState {
  final double todayMl;       // total ml consumed today
  final double goalMl;        // daily goal in ml
  final List<WaterEntry> entries;

  const WaterState({
    this.todayMl = 0,
    this.goalMl = 2000,
    this.entries = const [],
  });

  double get progress => (todayMl / goalMl).clamp(0, 1);
  int get glasses => (todayMl / 250).round(); // 250 ml per glass
}

class WaterEntry {
  final String id;
  final DateTime timestamp;
  final double ml;

  WaterEntry({required this.id, required this.timestamp, required this.ml});

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'ml': ml,
  };

  factory WaterEntry.fromMap(Map<String, dynamic> m) => WaterEntry(
    id: m['id'],
    timestamp: DateTime.parse(m['timestamp']),
    ml: (m['ml'] as num).toDouble(),
  );
}

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier() : super(const WaterState()) {
    _load();
  }

  final _db = DatabaseService.instance;

  Future<void> _load() async {
    final goalStr = await _db.getSetting('water_goal_ml');
    final goal = double.tryParse(goalStr ?? '') ?? 2000;

    final now = DateTime.now();
    final startOfDay =
    DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay =
    DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final rows = await _db.query(
      'water_logs',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'timestamp ASC',
    );

    final entries = rows.map(WaterEntry.fromMap).toList();
    final total = entries.fold(0.0, (s, e) => s + e.ml);

    state = WaterState(todayMl: total, goalMl: goal, entries: entries);
  }

  Future<void> addWater(double ml) async {
    final entry = WaterEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      ml: ml,
    );
    await _db.insert('water_logs', entry.toMap());
    await _load();
  }

  Future<void> removeLastEntry() async {
    if (state.entries.isEmpty) return;
    final last = state.entries.last;
    await _db.delete('water_logs', where: 'id = ?', whereArgs: [last.id]);
    await _load();
  }

  Future<void> setGoal(double ml) async {
    await _db.saveSetting('water_goal_ml', ml.toString());
    await _load();
  }
}