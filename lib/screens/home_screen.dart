import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/food_log_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/health_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Map<String, bool> _mealsDone = {
    'Breakfast': false,
    'Lunch': false,
    'Dinner': false,
    'Snack': false,
  };

  final Map<String, String> _mealTimes = {
    'Breakfast': '08:00',
    'Lunch': '12:30',
    'Dinner': '19:00',
    'Snack': '16:00',
  };

  void _toggleMeal(String meal) {
    setState(() => _mealsDone[meal] = !_mealsDone[meal]!);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  int get _mealsCompleted => _mealsDone.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final pantryCount = ref.watch(pantryProvider).length;
    final health = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.restaurant_menu),
          ),
        ),
        title: const Text('Kolirus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(healthProvider.notifier).syncWithGoogleFit(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingCard(
              greeting: _getGreeting(),
              mealsCompleted: _mealsCompleted,
              totalMeals: _mealsDone.length,
              calories: totals['calories'] ?? 0,
            ),
            const SizedBox(height: 16),
            Text('Today at a glance', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryCard(
                title: 'Calories',
                value: '${totals['calories']?.toStringAsFixed(0)}',
                sub: 'kcal consumed',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warning,
                onTap: () {},
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(
                title: 'Pantry',
                value: '$pantryCount items',
                sub: 'In stock',
                icon: Icons.kitchen_rounded,
                iconColor: AppColors.secondary,
                onTap: () {},
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryCard(
                title: 'Steps',
                value: '${health?.steps ?? 0}',
                sub: 'steps today',
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.success,
                onTap: () {},
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(
                title: 'Weight',
                value: '${health?.weight ?? 0} kg',
                sub: 'Current BMI: ${health?.bodyMass.toStringAsFixed(1)}',
                icon: Icons.monitor_weight_rounded,
                iconColor: AppColors.primary,
                onTap: () => _showHealthUpdateDialog(context),
              )),
            ]),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Meal routine', style: AppTextStyles.heading2),
                Text(
                  '$_mealsCompleted / ${_mealsDone.length} done',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._mealsDone.keys.map((meal) => _MealRoutineCard(
              meal: meal,
              time: _mealTimes[meal]!,
              done: _mealsDone[meal]!,
              onTap: () => _toggleMeal(meal),
            )),
          ],
        ),
      ),
    );
  }

  void _showHealthUpdateDialog(BuildContext context) {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Health Data'),
        content: TextField(
          controller: weightController,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(weightController.text);
              if (w != null) {
                ref.read(healthProvider.notifier).updateManualEntry(weight: w);
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final int mealsCompleted, totalMeals;
  final double calories;

  const _GreetingCard({
    required this.greeting,
    required this.mealsCompleted,
    required this.totalMeals,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: AppTextStyles.caption.copyWith(
            color: AppColors.accent, fontSize: 13,
          )),
          const SizedBox(height: 4),
          Text('Ready to eat well today?', style: AppTextStyles.heading1.copyWith(
            color: AppColors.card,
          )),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Calories', style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
              Text('${calories.toStringAsFixed(0)} / 2000 kcal', style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (calories / 2000).clamp(0.0, 1.0),
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.card),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title, required this.value,
    required this.sub,   required this.icon,
    required this.iconColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Text(title, style: AppTextStyles.caption),
              ]),
              const SizedBox(height: 8),
              Text(value, style: AppTextStyles.heading2),
              const SizedBox(height: 2),
              Text(sub, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealRoutineCard extends StatelessWidget {
  final String meal, time;
  final bool done;
  final VoidCallback onTap;

  const _MealRoutineCard({
    required this.meal, required this.time,
    required this.done, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: done ? AppColors.card : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done ? AppColors.secondary : AppColors.accent,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(meal,
              style: AppTextStyles.body.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? AppColors.textLight : AppColors.text,
              ),
            )),
            Text(time, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
