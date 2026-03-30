import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolirus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.card,
            onPressed: () => _showComingSoon(context, 'Notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColors.card,
            onPressed: () => _showComingSoon(context, 'Profile'),
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
            ),
            const SizedBox(height: 16),
            Text('Today at a glance', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryCard(
                title: 'Calories',
                value: '1,840',
                sub: '360 remaining',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warning,
                onTap: () => _showComingSoon(context, 'Calorie details'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(
                title: 'Pantry',
                value: '12 items',
                sub: '3 expiring soon',
                icon: Icons.kitchen_rounded,
                iconColor: AppColors.secondary,
                onTap: () => _showComingSoon(context, 'Pantry'),
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _SummaryCard(
                title: 'Water',
                value: '1.4 L',
                sub: '0.6 L to go',
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.primary,
                onTap: () => _showWaterDialog(context),
              )),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(
                title: 'Steps',
                value: '6,240',
                sub: '3,760 to goal',
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.success,
                onTap: () => _showComingSoon(context, 'Steps & Google Fit'),
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
            const SizedBox(height: 20),
            _QuickActionsRow(context: context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWaterDialog(BuildContext context) {
    double _water = 1.4;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppColors.background,
          title: Text('Water intake', style: AppTextStyles.heading2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_water.toStringAsFixed(1)} L',
                  style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              Slider(
                value: _water,
                min: 0,
                max: 4,
                divisions: 16,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.accent,
                onChanged: (v) => setInner(() => _water = v),
              ),
              Text('Goal: 2.0 L', style: AppTextStyles.caption),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String greeting;
  final int mealsCompleted, totalMeals;

  const _GreetingCard({
    required this.greeting,
    required this.mealsCompleted,
    required this.totalMeals,
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
              Text('Calories', style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
              )),
              Text('1,840 / 2,200 kcal', style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
              )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.61,
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.card),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meals today', style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
              )),
              Text('$mealsCompleted / $totalMeals done',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalMeals == 0 ? 0 : mealsCompleted / totalMeals,
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                key: ValueKey(done),
                color: done ? AppColors.success : AppColors.accent,
                size: 20,
              ),
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

class _QuickActionsRow extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsRow({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionButton(
              label: 'Scan food',
              icon: Icons.qr_code_scanner,
              onTap: () {},
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionButton(
              label: 'Add to log',
              icon: Icons.add_circle_outline_rounded,
              onTap: () {},
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionButton(
              label: 'Recipes',
              icon: Icons.menu_book_rounded,
              onTap: () {},
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent, width: 0.8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}