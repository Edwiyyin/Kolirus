import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/diet_constants.dart';
import '../providers/food_log_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/pantry_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';
import '../screens/scanner_screen.dart';
import '../widgets/nutrient_bar.dart';

class AddictionScreen extends ConsumerStatefulWidget {
  const AddictionScreen({super.key});

  @override
  ConsumerState<AddictionScreen> createState() => _AddictionScreenState();
}

class _AddictionScreenState extends ConsumerState<AddictionScreen>
    with SingleTickerProviderStateMixin {
  List<MealLog> _weeklyLogs = [];
  Map<String, int> _foodFrequency = {};
  List<Map<String, dynamic>> _customDiets = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final logs =
    await ref.read(foodLogProvider.notifier).getLogsForRange(start, now);

    final frequency = <String, int>{};
    for (final log in logs) {
      final name = log.foodName.toLowerCase().trim();
      frequency[name] = (frequency[name] ?? 0) + 1;
    }

    final diets = await DatabaseService.instance.getCustomDiets();

    if (mounted) {
      setState(() {
        _weeklyLogs = logs;
        _foodFrequency = frequency;
        _customDiets = diets;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final settings = ref.watch(settingsProvider);
    final pantry = ref.watch(pantryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Addiction & Filter Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.olive,
          labelColor: AppColors.olive,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Habits'),
            Tab(text: 'Pantry Warnings'),
            Tab(text: 'Allergens'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.olive))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildHabitsTab(totals),
          _buildPantryWarningsTab(settings, pantry),
          _buildAllergenTab(settings, pantry),
        ],
      ),
    );
  }

  // ── Habits Tab ────────────────────────────────────────────────────────────

  Widget _buildHabitsTab(Map<String, double> totals) {
    final addictiveNutriments = [
      {
        'label': 'Saturated Fat',
        'value': totals['saturatedFat'] ?? 0,
        'goal': 20.0,
        'unit': 'g',
        'color': Colors.redAccent
      },
      {
        'label': 'Sugar',
        'value': totals['sugar'] ?? 0,
        'goal': 30.0,
        'unit': 'g',
        'color': Colors.orangeAccent
      },
      {
        'label': 'Sodium',
        'value': totals['sodium'] ?? 0,
        'goal': 2300.0,
        'unit': 'mg',
        'color': Colors.yellowAccent
      },
      {
        'label': 'Cholesterol',
        'value': totals['cholesterol'] ?? 0,
        'goal': 300.0,
        'unit': 'mg',
        'color': Colors.deepOrange
      },
    ];

    final topAddictions = _foodFrequency.entries
        .where((e) => e.value >= 3)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Addictive Nutrients',
              style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          const Text(
            'These are nutrients that trigger cravings and habitual overconsumption.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),
          ...addictiveNutriments.map((n) => NutrientBar(
            label: n['label'] as String,
            value: n['value'] as double,
            goal: n['goal'] as double,
            unit: n['unit'] as String,
            color: n['color'] as Color,
          )),

          if (topAddictions.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Frequent Food Warnings',
                style:
                AppTextStyles.heading2.copyWith(color: Colors.redAccent)),
            const SizedBox(height: 4),
            const Text(
              'Foods you ate 3 or more times this week.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 12),
            ...topAddictions.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You ate ${e.key.toTitleCase()} ${e.value}x this week. Try to vary your diet.',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )),
          ],

          const SizedBox(height: 32),
          const Text('Weekly Food Variety', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20)),
            child: _FoodTypeBarChart(frequency: _foodFrequency),
          ),

          const SizedBox(height: 32),
          const Text('7-Day Addictive Load Trend',
              style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20)),
            child: _IntensityChart(weeklyLogs: _weeklyLogs),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Pantry Warnings Tab ───────────────────────────────────────────────────

  Widget _buildPantryWarningsTab(
      Map<String, dynamic> settings, List<FoodItem> pantry) {
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary = List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious =
    List<String>.from(settings['religious_prefs'] ?? []);
    final userQuality =
    List<String>.from(settings['quality_filters'] ?? []);

    final hasAnyFilter = userAllergies.isNotEmpty ||
        userDietary.isNotEmpty ||
        userReligious.isNotEmpty ||
        userQuality.isNotEmpty ||
        _customDiets.isNotEmpty;

    if (!hasAnyFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tune, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'No filters configured',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your allergies, dietary preferences, or ingredient quality filters in Settings to see warnings for pantry items.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final List<_PantryWarning> warnings = [];
    for (final item in pantry) {
      final allergyHits =
      ScannerScreen.detectAllergens(item, userAllergies);
      final dietHits = ScannerScreen.detectDietaryViolations(
          item, userDietary, userReligious);
      final qualityHits =
      ScannerScreen.detectQualityViolations(item, userQuality);
      final customHits = ScannerScreen.detectCustomDietViolations(
          item, _customDiets);

      if (allergyHits.isNotEmpty ||
          dietHits.isNotEmpty ||
          qualityHits.isNotEmpty ||
          customHits.isNotEmpty) {
        warnings.add(_PantryWarning(
          item: item,
          allergyHits: allergyHits,
          dietHits: dietHits,
          qualityHits: qualityHits,
          customHits: customHits,
        ));
      }
    }

    if (pantry.isEmpty) {
      return const Center(
        child: Text('Your pantry is empty.',
            style: TextStyle(color: Colors.white38)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warnings.isEmpty
                  ? AppColors.olive.withOpacity(0.1)
                  : Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: warnings.isEmpty
                    ? AppColors.olive.withOpacity(0.4)
                    : Colors.redAccent.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  warnings.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: warnings.isEmpty
                      ? AppColors.olive
                      : Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    warnings.isEmpty
                        ? 'All ${pantry.length} pantry items pass your active filters.'
                        : '${warnings.length} of ${pantry.length} pantry items flagged by your filters.',
                    style: TextStyle(
                      color: warnings.isEmpty
                          ? AppColors.olive
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (warnings.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('Nothing flagged — your pantry looks good!',
                    style: TextStyle(color: Colors.white38)),
              ),
            )
          else ...[
            Text('${warnings.length} Flagged Items',
                style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            ...warnings.map((w) => _PantryWarningCard(warning: w)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ── Allergen Tab ──────────────────────────────────────────────────────────

  Widget _buildAllergenTab(
      Map<String, dynamic> settings, List<FoodItem> pantry) {
    final userAllergies = List<String>.from(settings['allergies'] ?? []);

    if (userAllergies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_food, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'No allergens configured',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your allergens in Settings & Filters to get warned about dangerous ingredients.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Scan pantry for allergen hits
    final List<_AllergenHit> hits = [];
    for (final item in pantry) {
      final detected =
      ScannerScreen.detectAllergens(item, userAllergies);
      if (detected.isNotEmpty) {
        hits.add(_AllergenHit(item: item, detectedAllergens: detected));
      }
    }

    // Also scan weekly meal logs
    final List<_AllergenLogHit> logHits = [];
    for (final log in _weeklyLogs) {
      // Build a fake FoodItem from the log for scanning
      final fakeItem = FoodItem(
        name: log.foodName,
        ingredientsText: log.foodName,
      );
      final detected =
      ScannerScreen.detectAllergens(fakeItem, userAllergies);
      if (detected.isNotEmpty) {
        logHits.add(
            _AllergenLogHit(log: log, detectedAllergens: detected));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active allergens summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'YOUR ACTIVE ALLERGENS',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: userAllergies.map((a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Text(
                      a.toTitleCase(),
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pantry allergen hits
          Text('Pantry Items With Allergens (${hits.length})',
              style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          if (hits.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.olive.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: AppColors.olive.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.olive, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    pantry.isEmpty
                        ? 'Pantry is empty.'
                        : 'No allergens detected in your ${pantry.length} pantry items.',
                    style: const TextStyle(
                        color: AppColors.olive, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...hits.map((h) => _AllergenHitCard(hit: h)),

          const SizedBox(height: 24),

          // Meal log allergen warnings (this week)
          Text(
              'Meals This Week With Allergens (${logHits.length})',
              style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          const Text(
            'Based on food name matching — may not catch all allergens.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 10),
          if (logHits.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.olive.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: AppColors.olive.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.olive, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'No allergen matches in your recent meals.',
                    style:
                    TextStyle(color: AppColors.olive, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...logHits.map((h) => _AllergenLogCard(hit: h)),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Allergen Models ────────────────────────────────────────────────────────────

class _AllergenHit {
  final FoodItem item;
  final List<String> detectedAllergens;
  _AllergenHit({required this.item, required this.detectedAllergens});
}

class _AllergenLogHit {
  final MealLog log;
  final List<String> detectedAllergens;
  _AllergenLogHit({required this.log, required this.detectedAllergens});
}

class _AllergenHitCard extends StatelessWidget {
  final _AllergenHit hit;
  const _AllergenHitCard({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.item.name.toTitleCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  children: hit.detectedAllergens.map((a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '⚠ ${a.toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hit.item.location.name.toUpperCase(),
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllergenLogCard extends StatelessWidget {
  final _AllergenLogHit hit;
  const _AllergenLogCard({required this.hit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.log.foodName.toTitleCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  children:
                  hit.detectedAllergens.map((a) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      a.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          Text(
            hit.log.type.name,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Pantry Warning Model ────────────────────────────────────────────────────

class _PantryWarning {
  final FoodItem item;
  final List<String> allergyHits;
  final List<String> dietHits;
  final List<String> qualityHits;
  final List<String> customHits;
  _PantryWarning({
    required this.item,
    required this.allergyHits,
    required this.dietHits,
    required this.qualityHits,
    required this.customHits,
  });
}

class _PantryWarningCard extends StatelessWidget {
  final _PantryWarning warning;
  const _PantryWarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.item.name.toTitleCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  warning.item.location.name.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (warning.allergyHits.isNotEmpty)
            _flagRow(
              Icons.warning_amber_rounded,
              Colors.redAccent,
              'Allergen',
              warning.allergyHits.map((a) => a.toUpperCase()).join(', '),
            ),
          if (warning.dietHits.isNotEmpty)
            _flagRow(Icons.block, Colors.orangeAccent, 'Diet',
                warning.dietHits.join(', ')),
          if (warning.qualityHits.isNotEmpty)
            _flagRow(Icons.science_outlined, Colors.tealAccent.shade700,
                'Quality', warning.qualityHits.join(', ')),
          if (warning.customHits.isNotEmpty)
            _flagRow(Icons.tune, Colors.deepOrangeAccent, 'Custom',
                warning.customHits.join(', ')),
        ],
      ),
    );
  }

  Widget _flagRow(
      IconData icon, Color color, String type, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$type: ',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Charts ─────────────────────────────────────────────────────────────────

class _FoodTypeBarChart extends StatelessWidget {
  final Map<String, int> frequency;
  const _FoodTypeBarChart({required this.frequency});

  @override
  Widget build(BuildContext context) {
    if (frequency.isEmpty) {
      return const Center(
          child: Text('No data recorded',
              style: TextStyle(color: Colors.white38)));
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayList = sorted.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (displayList.first.value + 1).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= displayList.length)
                  return const Text('');
                final name = displayList[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    name.length > 6
                        ? '${name.substring(0, 5)}..'
                        : name,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: displayList
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value.toDouble(),
              color: e.value.value >= 3
                  ? Colors.redAccent
                  : AppColors.olive,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ))
            .toList(),
      ),
    );
  }
}

class _IntensityChart extends StatelessWidget {
  final List<MealLog> weeklyLogs;
  const _IntensityChart({required this.weeklyLogs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayLogs = weeklyLogs.where((l) =>
      l.consumedAt.year == day.year &&
          l.consumedAt.month == day.month &&
          l.consumedAt.day == day.day);

      double load = 0;
      for (final l in dayLogs) {
        load += (l.sugar / 30.0) * 30 +
            (l.saturatedFat / 20.0) * 30 +
            (l.sodium / 2300.0) * 20 +
            (l.cholesterol / 300.0) * 20;
      }
      spots.add(FlSpot((6 - i).toDouble(), load.clamp(0, 100)));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const days = ['6d', '5d', '4d', '3d', '2d', 'Yes', 'Tod'];
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const Text('');
                return Text(days[i],
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 9));
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 4,
            belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}