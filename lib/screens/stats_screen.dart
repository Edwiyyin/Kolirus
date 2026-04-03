import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/food_log_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_entry.dart';
import '../utils/constants.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final healthState = ref.watch(healthProvider);
    final health = healthState.today;
    final history = healthState.history;

    final calories = totals['calories'] ?? 0;
    const double calorieGoal = 2000;
    final protein = totals['protein'] ?? 0;
    final carbs = totals['carbs'] ?? 0;
    final fat = totals['fat'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calorie ring summary
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: (calories / calorieGoal).clamp(0, 1),
                    strokeWidth: 10,
                    backgroundColor: AppColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${calories.toInt()}',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.beige)),
                    const Text('kcal today',
                        style: TextStyle(color: AppColors.olive, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('biometrics', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _HealthStatCard(
                    title: 'steps',
                    value: '${health?.steps ?? 0}',
                    icon: Icons.directions_walk,
                    color: AppColors.accent,
                  )),
              const SizedBox(width: 12),
              Expanded(
                  child: _HealthStatCard(
                    title: 'weight',
                    value: '${health?.weight ?? 0} kg',
                    icon: Icons.monitor_weight,
                    color: AppColors.accent,
                    onTap: () => _showWeightDialog(context, ref),
                  )),
              const SizedBox(width: 12),
              Expanded(
                  child: _HealthStatCard(
                    title: 'BMI',
                    value: '${health?.bodyMass.toStringAsFixed(1) ?? 0}',
                    icon: Icons.accessibility_new,
                    color: AppColors.accent,
                  )),
            ],
          ),

          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('weight progress', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _WeightChart(history: history),
            ),
          ],

          const SizedBox(height: 24),
          const Text('macros', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: protein > 0 ? protein : 1,
                          title: 'P',
                          color: AppColors.accent,
                          radius: 50,
                          titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: carbs > 0 ? carbs : 1,
                          title: 'C',
                          color: AppColors.accent.withOpacity(0.6),
                          radius: 45,
                          titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: fat > 0 ? fat : 1,
                          title: 'F',
                          color: AppColors.accent.withOpacity(0.3),
                          radius: 40,
                          titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _MacroLegend(),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('nutrition details', style: AppTextStyles.heading2),
          const SizedBox(height: 12),

          // Macro targets with progress bars
          _ProgressDetailRow('protein', protein, 150, 'g'),
          _ProgressDetailRow('carbs', carbs, 250, 'g'),
          _ProgressDetailRow('fat', fat, 65, 'g'),

          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Micronutrients
          _DetailRow('saturated fat', '${totals['saturatedFat']?.toStringAsFixed(1) ?? 0}g'),
          _DetailRow('sodium', '${totals['sodium']?.toStringAsFixed(0) ?? 0}mg'),
          _DetailRow('fiber', '${totals['fiber']?.toStringAsFixed(1) ?? 0}g'),
          _DetailRow('sugar', '${totals['sugar']?.toStringAsFixed(1) ?? 0}g'),
          _DetailRow('cholesterol', '${totals['cholesterol']?.toStringAsFixed(1) ?? 0}mg'),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('update weight',
              style: TextStyle(color: AppColors.beige)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                    style: const TextStyle(color: Colors.white)),
                trailing:
                const Icon(Icons.calendar_today, color: AppColors.accent),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                    labelText: 'kg',
                    labelStyle: TextStyle(color: AppColors.accent)),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('cancel',
                    style: TextStyle(color: AppColors.beige))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent),
              onPressed: () {
                final w = double.tryParse(controller.text);
                if (w != null) {
                  ref
                      .read(healthProvider.notifier)
                      .updateManualEntry(weight: w, date: selectedDate);
                }
                Navigator.pop(context);
              },
              child:
              const Text('update', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<HealthEntry> history;
  const _WeightChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final entries = history.where((e) => e.weight > 0).toList();
    if (entries.isEmpty)
      return const Center(child: Text('No weight data'));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < entries.length) {
                  if (value.toInt() %
                      (entries.length > 5
                          ? (entries.length / 5).ceil()
                          : 1) ==
                      0) {
                    return Text(
                        DateFormat('MM/dd')
                            .format(entries[value.toInt()].date),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10));
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: entries
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                .toList(),
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class _HealthStatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HealthStatCard(
      {required this.title,
        required this.value,
        required this.icon,
        required this.color,
        this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.beige)),
            Text(title, style: AppTextStyles.caption),
            if (onTap != null)
              const Icon(Icons.edit, size: 12, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem('protein', AppColors.accent),
        _LegendItem('carbs', AppColors.accent.withOpacity(0.6)),
        _LegendItem('fat', AppColors.accent.withOpacity(0.3)),
      ],
    );
  }

  Widget _LegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ProgressDetailRow extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  const _ProgressDetailRow(this.label, this.value, this.goal, this.unit);

  @override
  Widget build(BuildContext context) {
    final pct = (value / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: AppTextStyles.body)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white10,
                valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.olive),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${value.toStringAsFixed(0)}/$goal$unit',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.accent)),
        ],
      ),
    );
  }
}