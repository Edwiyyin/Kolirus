import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/food_log_provider.dart';
import '../providers/health_provider.dart';
import '../utils/constants.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final health = ref.watch(healthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('biometrics', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _HealthStatCard(
                title: 'steps',
                value: '${health?.steps ?? 0}',
                icon: Icons.directions_walk,
                color: AppColors.olive,
              )),
              const SizedBox(width: 12),
              Expanded(child: _HealthStatCard(
                title: 'weight',
                value: '${health?.weight ?? 0} kg',
                icon: Icons.monitor_weight,
                color: AppColors.olive,
                onTap: () => _showWeightDialog(context, ref),
              )),
            ],
          ),
          const SizedBox(height: 24),
          const Text('nutrition', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.olive.withOpacity(0.2)),
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
                          value: totals['protein'] ?? 1,
                          title: 'P',
                          color: AppColors.olive,
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: totals['carbs'] ?? 1,
                          title: 'C',
                          color: AppColors.olive.withOpacity(0.6),
                          radius: 45,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        PieChartSectionData(
                          value: totals['fat'] ?? 1,
                          title: 'F',
                          color: AppColors.olive.withOpacity(0.3),
                          radius: 40,
                          titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
          const Text('details', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          _DetailRow('saturated fat', '${totals['saturatedFat']?.toStringAsFixed(1) ?? 0}g'),
          _DetailRow('sodium', '${totals['sodium']?.toStringAsFixed(1) ?? 0}mg'),
          _DetailRow('fiber', '${totals['fiber']?.toStringAsFixed(1) ?? 0}g'),
          _DetailRow('sugar', '${totals['sugar']?.toStringAsFixed(1) ?? 0}g'),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('update weight', style: TextStyle(color: AppColors.beige)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.beige),
          decoration: const InputDecoration(labelText: 'kg', labelStyle: TextStyle(color: AppColors.olive)),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('cancel', style: TextStyle(color: AppColors.beige))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () {
              final w = double.tryParse(controller.text);
              if (w != null) ref.read(healthProvider.notifier).updateManualEntry(weight: w);
              Navigator.pop(context);
            },
            child: const Text('update', style: TextStyle(color: Colors.black)),
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

  const _HealthStatCard({required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.heading2),
            Text(title, style: AppTextStyles.caption),
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
        _LegendItem('protein', AppColors.olive),
        _LegendItem('carbs', AppColors.olive.withOpacity(0.6)),
        _LegendItem('fat', AppColors.olive.withOpacity(0.3)),
      ],
    );
  }

  Widget _LegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.olive)),
        ],
      ),
    );
  }
}
