import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/dietary_rules.dart';
import '../providers/food_log_provider.dart';
import '../providers/settings_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../widgets/nutrient_bar.dart';

class AddictionScreen extends ConsumerStatefulWidget {
  const AddictionScreen({super.key});

  @override
  ConsumerState<AddictionScreen> createState() => _AddictionScreenState();
}

class _AddictionScreenState extends ConsumerState<AddictionScreen> {
  List<MealLog> _weeklyLogs = [];
  Map<String, int> _foodFrequency = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final logs = await ref.read(foodLogProvider.notifier).getLogsForRange(start, now);
    
    final frequency = <String, int>{};
    for (var log in logs) {
      final name = log.foodName.toLowerCase().trim();
      frequency[name] = (frequency[name] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        _weeklyLogs = logs;
        _foodFrequency = frequency;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final settings = ref.watch(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary = List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(settings['religious_prefs'] ?? []);

    final addictiveNutriments = [
      {'label': 'Saturated Fat', 'value': totals['saturatedFat'] ?? 0, 'goal': 20.0, 'unit': 'g', 'color': Colors.redAccent},
      {'label': 'Sugar', 'value': totals['sugar'] ?? 0, 'goal': 30.0, 'unit': 'g', 'color': Colors.orangeAccent},
      {'label': 'Sodium', 'value': totals['sodium'] ?? 0, 'goal': 2300.0, 'unit': 'mg', 'color': Colors.yellowAccent},
      {'label': 'Cholesterol', 'value': totals['cholesterol'] ?? 0, 'goal': 300.0, 'unit': 'mg', 'color': Colors.deepOrange},
    ];

    // Check for violations in current daily logs
    final dailyLogs = ref.watch(foodLogProvider);
    final List<String> currentViolations = [];
    for (var log in dailyLogs) {
      final item = FoodItem(name: log.foodName, ingredientsText: log.foodName);
      final allergens = DietaryRules.detectAllergies(item, userAllergies);
      // Pass settings as 4th arg for OFF quality checks
      final violations = DietaryRules.detectViolations(item, userDietary, userReligious, settings);
      
      if (allergens.isNotEmpty) {
        currentViolations.add('${log.foodName}: Contains ${allergens.join(", ")}');
      }
      if (violations.isNotEmpty) {
        currentViolations.add('${log.foodName}: ${violations.join(", ")}');
      }
    }

    final topAddictions = _foodFrequency.entries.where((e) => e.value >= 3).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: Text('Addiction Tracker'.toTitleCase())),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.olive))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentViolations.isNotEmpty) ...[
              Text('Dietary Warnings'.toTitleCase(), style: AppTextStyles.heading2.copyWith(color: AppColors.danger)),
              const SizedBox(height: 12),
              ...currentViolations.map((v) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],

            Text('Daily Addictive Nutriments'.toTitleCase(), style: AppTextStyles.heading2),
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
              Text('Frequent Food Warnings'.toTitleCase(), style: AppTextStyles.heading2.copyWith(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ...topAddictions.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You ate ${e.key.toTitleCase()} ${e.value} times this week. Try to vary your diet!',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 32),
            Text('Weekly Food Variety'.toTitleCase(), style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
              child: _FoodTypeBarChart(frequency: _foodFrequency),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _FoodTypeBarChart extends StatelessWidget {
  final Map<String, int> frequency;
  const _FoodTypeBarChart({required this.frequency});

  @override
  Widget build(BuildContext context) {
    if (frequency.isEmpty) return const Center(child: Text('No data recorded'));
    
    final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
                int index = value.toInt();
                if (index >= 0 && index < displayList.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      displayList[index].key.length > 6 
                        ? '${displayList[index].key.substring(0, 5)}..' 
                        : displayList[index].key,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: displayList.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value.toDouble(),
              color: e.value.value >= 3 ? Colors.redAccent : AppColors.olive,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )).toList(),
      ),
    );
  }
}
