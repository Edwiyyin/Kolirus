import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/food_log_provider.dart';
import '../utils/constants.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Daily Macro Distribution', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totals['protein'] ?? 1,
                      title: 'P',
                      color: Colors.red,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: totals['carbs'] ?? 1,
                      title: 'C',
                      color: Colors.blue,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: totals['fat'] ?? 1,
                      title: 'F',
                      color: Colors.yellow,
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _StatTile('Saturated Fat', '${totals['saturatedFat']?.toStringAsFixed(1) ?? 0}g'),
            _StatTile('Sodium', '${totals['sodium']?.toStringAsFixed(1) ?? 0}mg'),
            _StatTile('Fiber', '${totals['fiber']?.toStringAsFixed(1) ?? 0}g'),
            _StatTile('Sugar', '${totals['sugar']?.toStringAsFixed(1) ?? 0}g'),
          ],
        ),
      ),
    );
  }

  Widget _StatTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
