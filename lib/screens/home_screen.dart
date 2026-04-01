import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/food_log_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final calories = totals['calories'] ?? 0;
    const double goal = 2000;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text('hello,', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
          const Text('ready to fuel?', style: AppTextStyles.heading1),
          const SizedBox(height: 32),
          
          // Main Calorie Ring/Progress UX
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: (calories / goal).clamp(0, 1),
                    strokeWidth: 12,
                    backgroundColor: AppColors.card,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${calories.toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.beige)),
                    const Text('kcal', style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('of ${goal.toInt()}', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          const Text('quick macros', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _MacroMiniCard(label: 'protein', value: '${totals['protein']?.toInt() ?? 0}g', color: AppColors.olive),
              const SizedBox(width: 12),
              _MacroMiniCard(label: 'carbs', value: '${totals['carbs']?.toInt() ?? 0}g', color: AppColors.olive.withOpacity(0.6)),
              const SizedBox(width: 12),
              _MacroMiniCard(label: 'fat', value: '${totals['fat']?.toInt() ?? 0}g', color: AppColors.olive.withOpacity(0.3)),
            ],
          ),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.olive.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.olive),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'you have consumed ${(calories/goal*100).toInt()}% of your daily goal.',
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroMiniCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border(bottom: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.beige)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
