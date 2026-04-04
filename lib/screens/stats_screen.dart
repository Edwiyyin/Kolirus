import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/food_log_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_entry.dart';
import '../utils/constants.dart';
import '../widgets/nutrient_bar.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedNutrient = 'calories';

  final Map<String, Map<String, dynamic>> _nutrientMeta = {
    'calories': {'label': 'Calories (kcal)', 'goal': 2000.0, 'unit': 'kcal'},
    'protein': {'label': 'Protein (g)', 'goal': 150.0, 'unit': 'g'},
    'carbs': {'label': 'Carbs (g)', 'goal': 250.0, 'unit': 'g'},
    'fat': {'label': 'Fat (g)', 'goal': 70.0, 'unit': 'g'},
    'fiber': {'label': 'Fiber (g)', 'goal': 30.0, 'unit': 'g'},
    'sugar': {'label': 'Sugar (g)', 'goal': 50.0, 'unit': 'g'},
    'sodium': {'label': 'Sodium (mg)', 'goal': 2300.0, 'unit': 'mg'},
    'potassium': {'label': 'Potassium (mg)', 'goal': 3500.0, 'unit': 'mg'},
    'magnesium': {'label': 'Magnesium (mg)', 'goal': 400.0, 'unit': 'mg'},
    'vitaminC': {'label': 'Vitamin C (mg)', 'goal': 90.0, 'unit': 'mg'},
    'calcium': {'label': 'Calcium (mg)', 'goal': 1000.0, 'unit': 'mg'},
    'iron': {'label': 'Iron (mg)', 'goal': 18.0, 'unit': 'mg'},
  };

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final healthState = ref.watch(healthProvider);
    final history = healthState.history;
    final health = healthState.today;

    double bmi = 0;
    if (health != null && health.weight > 0 && health.height > 0) {
      bmi = health.weight / ((health.height / 100) * (health.height / 100));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight / BMI header with log button
          Row(
            children: [
              _StatHeader(label: 'Weight', value: '${health?.weight ?? 0}', unit: 'kg', color: AppColors.olive),
              const SizedBox(width: 12),
              _StatHeader(label: 'BMI', value: bmi.toStringAsFixed(1), unit: '', color: _getBMIColor(bmi)),
            ],
          ),
          const SizedBox(height: 12),
          // Log weight with date button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_chart, color: AppColors.olive),
              label: const Text('Log Weight Entry', style: TextStyle(color: AppColors.olive)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.olive),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showWeightLogDialog(context, ref),
            ),
          ),

          const SizedBox(height: 24),
          const Text('weight progress', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            child: _HistoryChart(history: history, valueExtractor: (e) => e.weight, color: AppColors.olive),
          ),

          // Weight history list (last 5 entries)
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Weight Logs', style: AppTextStyles.heading2),
                TextButton(
                  onPressed: () => _showFullWeightHistory(context, history),
                  child: const Text('View All', style: TextStyle(color: AppColors.olive, fontSize: 12)),
                ),
              ],
            ),
            ...history.reversed.take(5).map((e) => _WeightHistoryTile(entry: e, ref: ref)),
          ],

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('nutrient trend', style: AppTextStyles.heading2),
              DropdownButton<String>(
                value: _selectedNutrient,
                dropdownColor: AppColors.card,
                underline: Container(),
                items: _nutrientMeta.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label']))).toList(),
                onChanged: (val) => setState(() => _selectedNutrient = val!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            child: _NutrientTrendChart(nutrient: _selectedNutrient),
          ),

          const SizedBox(height: 32),
          const Text('daily gauges', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          ..._nutrientMeta.entries.map((e) {
            final val = totals[e.key] ?? 0;
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

  void _showWeightLogDialog(BuildContext context, WidgetRef ref) {
    final weightCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Log Weight', style: TextStyle(color: AppColors.beige)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.olive, size: 18),
                title: Text(
                  DateFormat('EEE, d MMM yyyy').format(selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                trailing: const Icon(Icons.edit, color: Colors.white38, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.olive,
                          onPrimary: Colors.black,
                          surface: AppColors.card,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: weightCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: TextStyle(color: AppColors.olive),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () async {
                final val = double.tryParse(weightCtrl.text);
                if (val != null && val > 0) {
                  await ref.read(healthProvider.notifier).updateManualEntry(
                    weight: val,
                    date: selectedDate,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                          'Logged ${val}kg on ${DateFormat('d MMM yyyy').format(selectedDate)}')),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullWeightHistory(BuildContext context, List<HealthEntry> history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('All Weight Logs', style: AppTextStyles.heading2),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: history.reversed.map((e) => _WeightHistoryTile(entry: e, ref: ref)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppColors.olive;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

class _WeightHistoryTile extends StatelessWidget {
  final HealthEntry entry;
  final WidgetRef ref;
  const _WeightHistoryTile({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (entry.weight == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.monitor_weight_outlined, color: AppColors.olive, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat('EEE, d MMM yyyy').format(entry.date),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            '${entry.weight} kg',
            style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white24),
            onPressed: () {
              final ctrl = TextEditingController(text: entry.weight.toString());
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.card,
                  title: Text(
                    'Edit ${DateFormat('d MMM yyyy').format(entry.date)}',
                    style: const TextStyle(color: AppColors.beige, fontSize: 15),
                  ),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      labelStyle: TextStyle(color: AppColors.olive),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
                      onPressed: () async {
                        final val = double.tryParse(ctrl.text);
                        if (val != null && val > 0) {
                          await ref.read(healthProvider.notifier).updateManualEntry(
                            weight: val,
                            date: entry.date,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatHeader extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatHeader({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<HealthEntry> history;
  final double Function(HealthEntry) valueExtractor;
  final Color color;
  const _HistoryChart({required this.history, required this.valueExtractor, required this.color});

  @override
  Widget build(BuildContext context) {
    final nonZero = history.where((e) => valueExtractor(e) > 0).toList();
    if (nonZero.isEmpty) return const Center(child: Text('No weight data yet. Log your first entry!', style: TextStyle(color: Colors.white38)));
    final spots = nonZero.asMap().entries.map((e) => FlSpot(e.key.toDouble(), valueExtractor(e.value))).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
            if (v.toInt() < 0 || v.toInt() >= nonZero.length) return const Text('');
            return Text(DateFormat('MM/dd').format(nonZero[v.toInt()].date), style: const TextStyle(fontSize: 8));
          })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: color, barWidth: 3, belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1))),
        ],
      ),
    );
  }
}

class _NutrientTrendChart extends ConsumerWidget {
  final String nutrient;
  const _NutrientTrendChart({required this.nutrient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final val = ref.watch(foodLogProvider.notifier).getDailyTotals()[nutrient] ?? 10;
    final spots = List.generate(7, (i) => FlSpot(i.toDouble(), val * (0.8 + (i * 0.1)))).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: AppColors.olive, barWidth: 4, belowBarData: BarAreaData(show: true, color: AppColors.olive.withOpacity(0.05))),
        ],
      ),
    );
  }
}