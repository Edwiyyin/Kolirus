import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/food_log_provider.dart';
import '../providers/health_provider.dart';
import '../providers/water_provider.dart';
import '../models/health_entry.dart';
import '../models/meal_log.dart';
import '../utils/constants.dart';
import '../widgets/nutrient_bar.dart';
import 'addiction_screen.dart';
import '../services/database_service.dart';

enum StatsPeriod { day, week, month }

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedNutrient = 'calories';
  StatsPeriod _period = StatsPeriod.week;
  bool _showBMI = false;

  // Logs tab
  DateTime _logsDate = DateTime.now();
  List<MealLog> _logsForDate = [];
  bool _logsLoading = false;

  // Water stats
  List<Map<String, dynamic>> _waterHistory = [];

  // Period intake summary
  Map<String, double> _periodTotals = {};
  bool _periodLoading = false;

  final Map<String, Map<String, dynamic>> _nutrientMeta = {
    'calories': {'label': 'Calories (kcal)', 'goal': 2000.0, 'unit': 'kcal'},
    'protein':  {'label': 'Protein (g)',      'goal': 150.0,  'unit': 'g'},
    'carbs':    {'label': 'Carbs (g)',         'goal': 250.0,  'unit': 'g'},
    'fat':      {'label': 'Fat (g)',           'goal': 70.0,   'unit': 'g'},
    'fiber':    {'label': 'Fiber (g)',         'goal': 30.0,   'unit': 'g'},
    'sugar':    {'label': 'Sugar (g)',         'goal': 50.0,   'unit': 'g'},
    'sodium':   {'label': 'Sodium (mg)',       'goal': 2300.0, 'unit': 'mg'},
    'potassium':{'label': 'Potassium (mg)',    'goal': 3500.0, 'unit': 'mg'},
    'magnesium':{'label': 'Magnesium (mg)',   'goal': 400.0,  'unit': 'mg'},
    'vitaminC': {'label': 'Vitamin C (mg)',    'goal': 90.0,   'unit': 'mg'},
    'calcium':  {'label': 'Calcium (mg)',      'goal': 1000.0, 'unit': 'mg'},
    'iron':     {'label': 'Iron (mg)',         'goal': 18.0,   'unit': 'mg'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLogsForDate(_logsDate);
    _loadWaterHistory();
    _loadPeriodTotals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogsForDate(DateTime date) async {
    setState(() => _logsLoading = true);
    final start =
    DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
    DateTime(date.year, date.month, date.day, 23, 59, 59)
        .toIso8601String();
    final res = await DatabaseService.instance.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'consumedAt ASC',
    );
    if (mounted) {
      setState(() {
        _logsForDate = res.map((j) => MealLog.fromMap(j)).toList();
        _logsDate = date;
        _logsLoading = false;
      });
    }
  }

  Future<void> _loadWaterHistory() async {
    final days = _period == StatsPeriod.day
        ? 1
        : _period == StatsPeriod.week
        ? 7
        : 30;
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start =
      DateTime(day.year, day.month, day.day).toIso8601String();
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59)
          .toIso8601String();
      final rows = await DatabaseService.instance.query(
        'water_logs',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [start, end],
      );
      final totalMl = rows.fold(
          0.0, (s, r) => s + ((r['ml'] as num?)?.toDouble() ?? 0));
      result.add({'date': day, 'ml': totalMl});
    }
    if (mounted) setState(() => _waterHistory = result);
  }

  Future<void> _loadPeriodTotals() async {
    setState(() => _periodLoading = true);
    final days = _period == StatsPeriod.day
        ? 1
        : _period == StatsPeriod.week
        ? 7
        : 30;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1))
        .toIso8601String();
    final end =
    DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final res = await DatabaseService.instance.query(
      'meal_logs',
      where: 'consumedAt BETWEEN ? AND ?',
      whereArgs: [start, end],
    );

    final Map<String, double> totals = {};
    for (final row in res) {
      for (final key in [
        'calories', 'protein', 'carbs', 'fat', 'fiber',
        'sugar', 'sodium', 'potassium', 'magnesium',
        'vitaminC', 'calcium', 'iron', 'cholesterol', 'saturatedFat',
      ]) {
        totals[key] =
            (totals[key] ?? 0) + ((row[key] as num?)?.toDouble() ?? 0);
      }
    }

    if (mounted) {
      setState(() {
        _periodTotals = totals;
        _periodLoading = false;
      });
    }
  }

  void _changePeriod(StatsPeriod p) {
    setState(() => _period = p);
    _loadWaterHistory();
    _loadPeriodTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Analytics'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.olive,
          labelColor: AppColors.olive,
          unselectedLabelColor: Colors.white38,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Daily Logs'),
            Tab(text: 'Nutrition'),
            Tab(text: 'Water'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLogsTab(),
          _buildNutritionTab(),
          _buildWaterTab(),
        ],
      ),
    );
  }

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final todayTotals =
    ref.watch(foodLogProvider.notifier).getDailyTotals();
    final healthState = ref.watch(healthProvider);
    final history = healthState.history;
    final health = healthState.today;

    double bmi = 0;
    if (health != null && health.weight > 0 && health.height > 0) {
      bmi = health.weight /
          ((health.height / 100) * (health.height / 100));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Addiction shortcut
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddictionScreen())),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.olive.withOpacity(0.3),
                  AppColors.card
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.olive.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.olive, size: 30),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Addiction & Filter Tracker',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white)),
                        Text('Monitor habits and pantry violations',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
          ),

          // Period selector
          _PeriodSelector(current: _period, onChanged: _changePeriod),
          const SizedBox(height: 20),

          // ── Period intake summary ──────────────────────────────────────
          _buildPeriodSummary(),
          const SizedBox(height: 24),

          // Weight / BMI
          Row(
            children: [
              _StatCard(
                label: 'Weight',
                value: '${health?.weight ?? 0}',
                unit: 'kg',
                color: AppColors.olive,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'BMI',
                value: bmi.toStringAsFixed(1),
                unit: '',
                color: _getBMIColor(bmi),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_chart, color: AppColors.olive),
                  label: const Text('Log Weight',
                      style: TextStyle(color: AppColors.olive)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.olive),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      _showWeightLogDialog(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.history, color: Colors.white54),
                  label: const Text('History',
                      style: TextStyle(color: Colors.white54)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      _showWeightHistory(context, ref, history),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_showBMI ? 'BMI Progress' : 'Weight Progress',
                  style: AppTextStyles.heading2),
              GestureDetector(
                onTap: () =>
                    setState(() => _showBMI = !_showBMI),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.olive.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.olive.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showBMI
                            ? Icons.monitor_weight_outlined
                            : Icons.calculate_outlined,
                        color: AppColors.olive,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showBMI ? 'Show Weight' : 'Show BMI',
                        style: const TextStyle(
                            color: AppColors.olive, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_showBMI)
            _BMIGaugeWidget(bmi: bmi, history: history)
          else
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20)),
              child: _HistoryChart(
                history: history,
                valueExtractor: (e) => e.weight,
                color: AppColors.olive,
              ),
            ),

          const SizedBox(height: 24),
          const Text("Today's Gauges", style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          ..._nutrientMeta.entries.map((e) {
            final val = todayTotals[e.key] ?? 0;
            return NutrientBar(
              label: e.value['label'],
              value: val,
              goal: e.value['goal'],
              unit: e.value['unit'],
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary() {
    final label = _period == StatsPeriod.day
        ? "Today's"
        : _period == StatsPeriod.week
        ? '7-Day'
        : '30-Day';

    if (_periodLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.olive),
      );
    }

    final cal = _periodTotals['calories'] ?? 0;
    final protein = _periodTotals['protein'] ?? 0;
    final carbs = _periodTotals['carbs'] ?? 0;
    final fat = _periodTotals['fat'] ?? 0;
    final fiber = _periodTotals['fiber'] ?? 0;
    final sugar = _periodTotals['sugar'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label Intake Summary', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.olive.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // Big calorie number
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cal.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.olive),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6, left: 4),
                    child: Text('kcal',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Macro row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _periodMacro(
                      'Protein', '${protein.toInt()}g', Colors.blue.shade300),
                  _periodMacro(
                      'Carbs', '${carbs.toInt()}g', Colors.amber),
                  _periodMacro(
                      'Fat', '${fat.toInt()}g', Colors.redAccent),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _periodMacro('Fiber', '${fiber.toInt()}g',
                      Colors.green.shade400),
                  _periodMacro(
                      'Sugar', '${sugar.toInt()}g', Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periodMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  // ── DAILY LOGS TAB ────────────────────────────────────────────────────────

  Widget _buildLogsTab() {
    final totalCals =
    _logsForDate.fold(0.0, (s, l) => s + l.calories);
    final totalProtein =
    _logsForDate.fold(0.0, (s, l) => s + l.protein);
    final totalCarbs =
    _logsForDate.fold(0.0, (s, l) => s + l.carbs);
    final totalFat = _logsForDate.fold(0.0, (s, l) => s + l.fat);
    final totalFiber =
    _logsForDate.fold(0.0, (s, l) => s + l.fiber);
    final totalSodium =
    _logsForDate.fold(0.0, (s, l) => s + l.sodium);
    final totalSugar =
    _logsForDate.fold(0.0, (s, l) => s + l.sugar);

    return Column(
      children: [
        // Date navigation
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.olive),
                onPressed: () => _loadLogsForDate(
                    _logsDate.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _logsDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.olive,
                            onPrimary: Colors.black,
                            surface: AppColors.card,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) _loadLogsForDate(picked);
                  },
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(_logsDate),
                        style: const TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        DateFormat('d MMMM yyyy').format(_logsDate),
                        style: const TextStyle(
                            color: AppColors.beige, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _logsDate.day == DateTime.now().day
                      ? Colors.white24
                      : AppColors.olive,
                ),
                onPressed: _logsDate.day == DateTime.now().day
                    ? null
                    : () => _loadLogsForDate(
                    _logsDate.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),

        // Summary bar
        if (_logsForDate.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 10),
            color: AppColors.card,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _miniStat('${totalCals.toInt()}', 'kcal',
                      AppColors.olive),
                  _miniStat('${totalProtein.toInt()}g', 'prot',
                      Colors.blue.shade300),
                  _miniStat('${totalCarbs.toInt()}g', 'carbs',
                      Colors.amber),
                  _miniStat('${totalFat.toInt()}g', 'fat',
                      Colors.redAccent),
                  _miniStat(
                      '${totalFiber.toInt()}g', 'fiber', Colors.green.shade400),
                  _miniStat('${totalSugar.toInt()}g', 'sugar',
                      Colors.orange),
                  _miniStat('${totalSodium.toInt()}mg', 'sodium',
                      Colors.yellowAccent),
                ],
              ),
            ),
          ),

        // Logs list
        Expanded(
          child: _logsLoading
              ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.olive))
              : _logsForDate.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 48, color: Colors.white12),
                const SizedBox(height: 12),
                Text(
                  'No meals logged on\n${DateFormat('d MMM yyyy').format(_logsDate)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white38),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _logsForDate.length,
            itemBuilder: (context, i) {
              final log = _logsForDate[i];
              return _MealLogCard(log: log);
            },
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String value, String label, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      );

  // ── NUTRITION TREND TAB ───────────────────────────────────────────────────

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(current: _period, onChanged: _changePeriod),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nutrient Trend', style: AppTextStyles.heading2),
              DropdownButton<String>(
                value: _selectedNutrient,
                dropdownColor: AppColors.card,
                underline: Container(),
                items: _nutrientMeta.entries
                    .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value['label'],
                      style: const TextStyle(fontSize: 12)),
                ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedNutrient = val!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20)),
            child: _NutrientTrendChart(
              nutrient: _selectedNutrient,
              period: _period,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── WATER TAB ─────────────────────────────────────────────────────────────

  Widget _buildWaterTab() {
    final water = ref.watch(waterProvider);
    final maxMl = _waterHistory.isEmpty
        ? water.goalMl
        : _waterHistory
        .map((d) => d['ml'] as double)
        .reduce((a, b) => a > b ? a : b);
    final avgMl = _waterHistory.isEmpty
        ? 0.0
        : _waterHistory.fold(
        0.0, (s, d) => s + (d['ml'] as double)) /
        _waterHistory.length;
    final daysHit = _waterHistory
        .where((d) => (d['ml'] as double) >= water.goalMl)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(current: _period, onChanged: _changePeriod),
          const SizedBox(height: 20),

          Row(
            children: [
              _WaterStatCard(
                  label: 'Today',
                  value: '${water.todayMl.toInt()} ml',
                  color: AppColors.olive),
              const SizedBox(width: 12),
              _WaterStatCard(
                  label: 'Avg / Day',
                  value: '${avgMl.toInt()} ml',
                  color: Colors.blue.shade400),
              const SizedBox(width: 12),
              _WaterStatCard(
                  label: 'Goal Days',
                  value: '$daysHit / ${_waterHistory.length}',
                  color: Colors.amber),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Water Intake History', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20)),
            child: _waterHistory.isEmpty
                ? const Center(
                child: Text('No water data yet',
                    style: TextStyle(color: Colors.white38)))
                : BarChart(
              BarChartData(
                maxY: (maxMl * 1.3).clamp(
                    water.goalMl * 1.3, double.infinity),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i < 0 ||
                            i >= _waterHistory.length)
                          return const Text('');
                        final d = _waterHistory[i]['date']
                        as DateTime;
                        return Text(
                          DateFormat(_period ==
                              StatsPeriod.month
                              ? 'd'
                              : 'E')
                              .format(d),
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                barGroups:
                _waterHistory.asMap().entries.map((e) {
                  final ml = e.value['ml'] as double;
                  final hitGoal = ml >= water.goalMl;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: ml,
                        color: hitGoal
                            ? AppColors.olive
                            : Colors.blue.shade300
                            .withOpacity(0.7),
                        width: _period == StatsPeriod.month
                            ? 8
                            : 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: water.goalMl,
                      color: AppColors.olive.withOpacity(0.4),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) =>
                        '${water.goalMl.toInt()} ml goal',
                        style: const TextStyle(
                            color: AppColors.olive,
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Daily Breakdown', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          ..._waterHistory.reversed.take(10).map((d) {
            final ml = (d['ml'] as double).toInt();
            final date = d['date'] as DateTime;
            final hitGoal = ml >= water.goalMl;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hitGoal
                      ? AppColors.olive.withOpacity(0.4)
                      : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hitGoal ? Icons.check_circle : Icons.water_drop,
                    color: hitGoal
                        ? AppColors.olive
                        : Colors.blue.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('EEE, d MMM').format(date),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Text('$ml ml',
                      style: TextStyle(
                          color: hitGoal
                              ? AppColors.olive
                              : Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _getBMIColor(double bmi) {
    if (bmi <= 0) return Colors.white38;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppColors.olive;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showWeightLogDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Log Weight',
              style: TextStyle(color: AppColors.beige)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today,
                    color: AppColors.olive, size: 18),
                title: Text(
                  DateFormat('EEE, d MMM yyyy').format(selectedDate),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                ),
                trailing:
                const Icon(Icons.edit, color: Colors.white38, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null)
                    setDialogState(() => selectedDate = date);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: TextStyle(color: AppColors.olive),
                  suffixText: 'kg',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive),
              onPressed: () async {
                final val = double.tryParse(weightCtrl.text);
                if (val != null && val > 0) {
                  await ref
                      .read(healthProvider.notifier)
                      .updateManualEntry(
                      weight: val, date: selectedDate);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeightHistory(BuildContext context, WidgetRef ref,
      List<HealthEntry> history) {
    final withWeight = history
        .where((e) => e.weight > 0)
        .toList()
        .reversed
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Weight History', style: AppTextStyles.heading2),
            ),
            Expanded(
              child: withWeight.isEmpty
                  ? const Center(
                  child: Text('No weight entries yet',
                      style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                controller: sc,
                itemCount: withWeight.length,
                itemBuilder: (ctx, i) {
                  final entry = withWeight[i];
                  return ListTile(
                    leading: const Icon(
                        Icons.monitor_weight_outlined,
                        color: AppColors.olive),
                    title: Text(
                        '${entry.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        DateFormat('EEE, d MMM yyyy')
                            .format(entry.date),
                        style: const TextStyle(
                            color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit,
                          color: AppColors.olive, size: 18),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditWeightDialog(
                            context, ref, entry);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWeightDialog(
      BuildContext context, WidgetRef ref, HealthEntry entry) {
    final ctrl = TextEditingController(
        text: entry.weight.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Edit ${DateFormat('d MMM yyyy').format(entry.date)}',
            style: const TextStyle(color: AppColors.beige)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            labelStyle: TextStyle(color: AppColors.olive),
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive),
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                await ref
                    .read(healthProvider.notifier)
                    .updateManualEntry(
                    weight: val, date: entry.date);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _MealLogCard extends StatelessWidget {
  final MealLog log;
  const _MealLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.olive.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(
              _mealIcon(log.type.name),
              color: AppColors.olive,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.foodName.toTitleCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text(
                  '${log.type.name.toTitleCase()} · ${DateFormat('HH:mm').format(log.consumedAt)}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _tag('P: ${log.protein.toInt()}g',
                        Colors.blue.shade300),
                    _tag('C: ${log.carbs.toInt()}g', Colors.amber),
                    _tag('F: ${log.fat.toInt()}g', Colors.redAccent),
                    if (log.fiber > 0)
                      _tag('Fb: ${log.fiber.toInt()}g',
                          Colors.green.shade400),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${log.calories.toInt()}',
                  style: const TextStyle(
                      color: AppColors.olive,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Text('kcal',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 10)),
  );

  IconData _mealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.wb_cloudy_outlined;
      case 'dinner':
        return Icons.nights_stay_outlined;
      default:
        return Icons.apple;
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final StatsPeriod current;
  final ValueChanged<StatsPeriod> onChanged;
  const _PeriodSelector(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PeriodBtn('Day', StatsPeriod.day, current, onChanged),
          _PeriodBtn('Week', StatsPeriod.week, current, onChanged),
          _PeriodBtn('Month', StatsPeriod.month, current, onChanged),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final StatsPeriod period;
  final StatsPeriod current;
  final ValueChanged<StatsPeriod> onChanged;
  const _PeriodBtn(this.label, this.period, this.current, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final isSelected = current == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.olive
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _WaterStatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatCard(
      {required this.label,
        required this.value,
        required this.unit,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.white54)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(width: 4),
                Text(unit,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BMIGaugeWidget extends StatelessWidget {
  final double bmi;
  final List<HealthEntry> history;
  const _BMIGaugeWidget({required this.bmi, required this.history});

  String _bmiCategory(double bmi) {
    if (bmi <= 0) return 'No data';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0) return Colors.white38;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppColors.olive;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _bmiColor(bmi);
    final category = _bmiCategory(bmi);
    final pct =
    bmi <= 0 ? 0.0 : ((bmi - 10) / 30.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const Text('BMI',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 17,
                      child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(8))))),
                  Expanded(
                      flex: 13,
                      child: Container(
                          height: 16, color: AppColors.olive)),
                  Expanded(
                      flex: 10,
                      child:
                      Container(height: 16, color: Colors.orange)),
                  Expanded(
                      flex: 20,
                      child: Container(
                          height: 16,
                          decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.horizontal(
                                  right: Radius.circular(8))))),
                ],
              ),
              if (bmi > 0)
                Positioned(
                  left: MediaQuery.of(context).size.width * pct * 0.72,
                  top: -4,
                  child: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text('18.5',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text('25',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text('30',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
              Text('40',
                  style: TextStyle(
                      color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Under',
                  style: TextStyle(color: Colors.blue, fontSize: 9)),
              Text('Healthy',
                  style: TextStyle(
                      color: AppColors.olive, fontSize: 9)),
              Text('Over',
                  style:
                  TextStyle(color: Colors.orange, fontSize: 9)),
              Text('Obese',
                  style: TextStyle(color: Colors.red, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 16),
          if (history
              .where((e) => e.bodyMass > 0 || e.weight > 0)
              .isNotEmpty)
            SizedBox(
              height: 100,
              child: _HistoryChart(
                history: history,
                valueExtractor: (e) {
                  if (e.bodyMass > 0) return e.bodyMass;
                  if (e.weight > 0 && e.height > 0) {
                    return e.weight /
                        ((e.height / 100) * (e.height / 100));
                  }
                  return 0;
                },
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<HealthEntry> history;
  final double Function(HealthEntry) valueExtractor;
  final Color color;
  const _HistoryChart(
      {required this.history,
        required this.valueExtractor,
        required this.color});

  @override
  Widget build(BuildContext context) {
    final nonZero =
    history.where((e) => valueExtractor(e) > 0).toList();
    if (nonZero.isEmpty) {
      return const Center(
          child: Text('No data yet.',
              style: TextStyle(color: Colors.white38)));
    }
    final spots = nonZero
        .asMap()
        .entries
        .map((e) =>
        FlSpot(e.key.toDouble(), valueExtractor(e.value)))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    if (v.toInt() < 0 ||
                        v.toInt() >= nonZero.length) {
                      return const Text('');
                    }
                    return Text(
                        DateFormat('MM/dd')
                            .format(nonZero[v.toInt()].date),
                        style: const TextStyle(fontSize: 8));
                  })),
          leftTitles: const AxisTitles(
              sideTitles:
              SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1))),
        ],
      ),
    );
  }
}

class _NutrientTrendChart extends ConsumerStatefulWidget {
  final String nutrient;
  final StatsPeriod period;
  const _NutrientTrendChart(
      {required this.nutrient, required this.period});

  @override
  ConsumerState<_NutrientTrendChart> createState() =>
      _NutrientTrendChartState();
}

class _NutrientTrendChartState
    extends ConsumerState<_NutrientTrendChart> {
  List<FlSpot> _spots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_NutrientTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nutrient != widget.nutrient ||
        oldWidget.period != widget.period) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final days = widget.period == StatsPeriod.day
        ? 1
        : widget.period == StatsPeriod.week
        ? 7
        : 30;
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start =
      DateTime(day.year, day.month, day.day).toIso8601String();
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59)
          .toIso8601String();
      final res = await DatabaseService.instance.query(
        'meal_logs',
        where: 'consumedAt BETWEEN ? AND ?',
        whereArgs: [start, end],
      );
      final total = res.fold(
          0.0,
              (s, r) =>
          s +
              ((r[widget.nutrient] as num?)?.toDouble() ?? 0));
      spots.add(FlSpot((days - 1 - i).toDouble(), total));
    }

    if (mounted) setState(() {
      _spots = spots;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child:
          CircularProgressIndicator(color: AppColors.olive));
    }
    if (_spots.every((s) => s.y == 0)) {
      return const Center(
          child: Text('No data for this period',
              style: TextStyle(color: Colors.white38)));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true)),
          leftTitles: AxisTitles(
              sideTitles:
              SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots,
            isCurved: true,
            color: AppColors.olive,
            barWidth: 4,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.olive,
                    strokeColor: Colors.transparent,
                  ),
            ),
            belowBarData: BarAreaData(
                show: true,
                color: AppColors.olive.withOpacity(0.05)),
          ),
        ],
      ),
    );
  }
}