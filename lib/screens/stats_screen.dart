import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/food_log_provider.dart';
import '../providers/health_provider.dart';
import '../models/health_entry.dart';
import '../utils/constants.dart';
import '../widgets/nutrient_bar.dart';
import 'addiction_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedNutrient = 'calories';
  bool _showBMI = false; // toggle between weight and BMI chart

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

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Addiction Shortcut
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddictionScreen())),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.olive.withOpacity(0.3),
                    AppColors.card
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border:
                  Border.all(color: AppColors.olive.withOpacity(0.5)),
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
                          Text('Addiction Tracker',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                          Text('Monitor and manage your habits',
                              style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white24),
                  ],
                ),
              ),
            ),

            // Weight / BMI header
            Row(
              children: [
                _StatHeader(
                    label: 'Weight',
                    value: '${health?.weight ?? 0}',
                    unit: 'kg',
                    color: AppColors.olive),
                const SizedBox(width: 12),
                _StatHeader(
                    label: 'BMI',
                    value: bmi.toStringAsFixed(1),
                    unit: '',
                    color: _getBMIColor(bmi)),
              ],
            ),
            const SizedBox(height: 12),

            // Log weight button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_chart, color: AppColors.olive),
                label: const Text('Log Weight Entry',
                    style: TextStyle(color: AppColors.olive)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.olive),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showWeightLogDialog(context, ref),
              ),
            ),
            const SizedBox(height: 8),

            // Edit history button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history, color: Colors.white54),
                label: const Text('Edit Weight History',
                    style: TextStyle(color: Colors.white54)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showWeightHistory(context, ref, history),
              ),
            ),

            const SizedBox(height: 24),

            // Chart toggle header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_showBMI ? 'BMI Progress' : 'Weight Progress',
                    style: AppTextStyles.heading2),
                // Toggle button
                GestureDetector(
                  onTap: () => setState(() => _showBMI = !_showBMI),
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

            // Chart
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

            const SizedBox(height: 32),
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
                          style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedNutrient = val!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20)),
              child: _NutrientTrendChart(nutrient: _selectedNutrient),
            ),

            const SizedBox(height: 32),
            const Text('Daily Gauges', style: AppTextStyles.heading2),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
              onPressed: () async {
                final val = double.tryParse(weightCtrl.text);
                if (val != null && val > 0) {
                  await ref
                      .read(healthProvider.notifier)
                      .updateManualEntry(weight: val, date: selectedDate);
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

  void _showWeightHistory(
      BuildContext context, WidgetRef ref, List<HealthEntry> history) {
    final withWeight = history.where((e) => e.weight > 0).toList().reversed.toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    leading: const Icon(Icons.monitor_weight_outlined,
                        color: AppColors.olive),
                    title: Text(
                        '${entry.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        DateFormat('EEE, d MMM yyyy').format(entry.date),
                        style: const TextStyle(color: Colors.white54)),
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
        title: Text(
            'Edit ${DateFormat('d MMM yyyy').format(entry.date)}',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () async {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) {
                await ref
                    .read(healthProvider.notifier)
                    .updateManualEntry(weight: val, date: entry.date);
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

  Color _getBMIColor(double bmi) {
    if (bmi <= 0) return Colors.white38;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return AppColors.olive;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}

// ── BMI Gauge Widget ──────────────────────────────────────────────────────────

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
    // BMI gauge range: 10 to 40
    final pct = bmi <= 0 ? 0.0 : ((bmi - 10) / 30.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          // Current BMI display
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
                      style:
                      TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gauge bar
          Stack(
            children: [
              // Background segments
              Row(
                children: [
                  Expanded(
                      flex: 17, // underweight: 10-18.5 = 8.5 parts -> 17 units
                      child: Container(
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                      )),
                  Expanded(
                      flex: 13, // healthy: 18.5-25 = 6.5 -> 13 units
                      child: Container(
                          height: 16, color: AppColors.olive)),
                  Expanded(
                      flex: 10, // overweight: 25-30 = 5 -> 10 units
                      child: Container(
                          height: 16, color: Colors.orange)),
                  Expanded(
                      flex: 20, // obese: 30-40 = 10 -> 20 units
                      child: Container(
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                      )),
                ],
              ),
              // Pointer
              if (bmi > 0)
                Positioned(
                  left: MediaQuery.of(context).size.width * pct * 0.72,
                  top: -4,
                  child: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Labels
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('18.5',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('25', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('30', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('40', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Under', style: TextStyle(color: Colors.blue, fontSize: 9)),
              Text('Healthy',
                  style: TextStyle(color: AppColors.olive, fontSize: 9)),
              Text('Over',
                  style: TextStyle(color: Colors.orange, fontSize: 9)),
              Text('Obese',
                  style: TextStyle(color: Colors.red, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 16),

          // BMI history chart
          if (history.where((e) => e.bodyMass > 0 || e.weight > 0).isNotEmpty)
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

class _StatHeader extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatHeader(
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
                style:
                const TextStyle(fontSize: 10, color: Colors.white54)),
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
        .map((e) => FlSpot(
        e.key.toDouble(), valueExtractor(e.value)))
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
                  show: true, color: color.withOpacity(0.1))),
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
    final totals =
    ref.watch(foodLogProvider.notifier).getDailyTotals();
    final val = totals[nutrient] ?? 0;
    final spots = List.generate(
        7, (i) => FlSpot(i.toDouble(), val * (0.5 + (i * 0.1)))).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles:
          AxisTitles(sideTitles: SideTitles(showTitles: true)),
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
              spots: spots,
              isCurved: true,
              color: AppColors.olive,
              barWidth: 4,
              belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.olive.withOpacity(0.05))),
        ],
      ),
    );
  }
}