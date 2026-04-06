import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/recipe.dart';
import '../models/meal_routine.dart';
import '../models/meal_type.dart';
import '../screens/recipe_screen.dart';
import '../providers/routine_provider.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  int _weeks = 1;
  bool _isGenerating = false;

  // Weekly plan: dayIndex → mealType → Recipe or manual string
  final Map<int, Map<String, dynamic?>> _weeklyPlan = {
    for (int i = 0; i < 7; i++)
      i: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
  };

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];

  final Map<String, String> _mealTimes = {
    'Breakfast': '08:00',
    'Lunch': '12:00',
    'Dinner': '19:00',
  };

  final Map<String, MealType> _mealTypeMap = {
    'Breakfast': MealType.Breakfast,
    'Lunch': MealType.Lunch,
    'Dinner': MealType.Dinner,
  };

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Routine Planner'.toTitleCase()),
      ),
      body: Column(
        children: [
          // Config header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.card,
            child: Column(
              children: [
                const Text(
                  'Plan Your Week',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.beige),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set meals for each day, then generate your routine.',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Repeat for: ', style: TextStyle(color: AppColors.beige)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _weeks,
                        dropdownColor: AppColors.card,
                        underline: const SizedBox(),
                        items: List.generate(8, (i) => i + 1).map((i) =>
                            DropdownMenuItem(
                                value: i,
                                child: Text('$i week${i == 1 ? '' : 's'}',
                                    style: const TextStyle(color: AppColors.beige)))
                        ).toList(),
                        onChanged: (val) => setState(() => _weeks = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick-fill button
                if (recipes.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.auto_awesome, color: AppColors.olive, size: 16),
                    label: const Text('Auto-fill with recipes',
                        style: TextStyle(color: AppColors.olive, fontSize: 12)),
                    onPressed: () => _autoFill(recipes),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, dayIndex) => _buildDayCard(dayIndex, recipes),
            ),
          ),

          // Generate button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isGenerating
                  ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline, color: Colors.black),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Routine for $_weeks Week${_weeks > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: _isGenerating ? null : () => _generateRoutine(),
            ),
          ),
        ],
      ),
    );
  }

  void _autoFill(List<Recipe> recipes) {
    if (recipes.isEmpty) return;
    setState(() {
      for (int day = 0; day < 7; day++) {
        for (final mealType in ['Breakfast', 'Lunch', 'Dinner']) {
          final recipeIndex = (day * 3 + _mealTypeIndex(mealType)) % recipes.length;
          _weeklyPlan[day]![mealType] = recipes[recipeIndex];
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Week auto-filled with recipes!')),
    );
  }

  int _mealTypeIndex(String mealType) {
    switch (mealType) {
      case 'Breakfast': return 0;
      case 'Lunch': return 1;
      case 'Dinner': return 2;
      default: return 0;
    }
  }

  Future<void> _generateRoutine() async {
    setState(() => _isGenerating = true);

    try {
      final now = DateTime.now();
      // Find next Monday
      final daysUntilMonday = (8 - now.weekday) % 7;
      final startDate = DateTime(now.year, now.month,
          now.day + (daysUntilMonday == 0 ? 0 : daysUntilMonday));

      int totalCreated = 0;

      for (int week = 0; week < _weeks; week++) {
        for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
          final date = startDate.add(Duration(days: week * 7 + dayIndex));
          final dayPlan = _weeklyPlan[dayIndex]!;

          for (final mealType in ['Breakfast', 'Lunch', 'Dinner']) {
            final entry = dayPlan[mealType];
            if (entry == null) continue;

            String mealName;
            String? recipeId;
            double? calories, protein, carbs, fat;

            if (entry is Recipe) {
              mealName = entry.name;
              recipeId = entry.id;
              calories = entry.calories;
              protein = entry.protein;
              carbs = entry.carbs;
              fat = entry.fat;
            } else {
              mealName = entry.toString();
            }

            final routine = MealRoutine(
              id: '${DateTime.now().millisecondsSinceEpoch}_${week}_${dayIndex}_$mealType',
              date: date,
              mealType: _mealTypeMap[mealType]!,
              recipeId: recipeId,
              manualEntry: mealName,
              time: _mealTimes[mealType],
              isEaten: false,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
            );

            await ref.read(routineProvider.notifier).addEntry(routine);
            totalCreated++;
          }
        }
      }

      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Generated $totalCreated meal${totalCreated == 1 ? '' : 's'} across $_weeks week${_weeks > 1 ? 's' : ''}!'),
            backgroundColor: AppColors.olive,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating routine: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildDayCard(int dayIndex, List<Recipe> recipes) {
    final dayPlan = _weeklyPlan[dayIndex]!;
    final hasAnyMeal = dayPlan.values.any((v) => v != null);

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasAnyMeal ? AppColors.olive.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _days[dayIndex].toTitleCase(),
                    style: TextStyle(
                      color: hasAnyMeal ? AppColors.olive : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                if (hasAnyMeal)
                  GestureDetector(
                    onTap: () => setState(() {
                      for (final k in dayPlan.keys) dayPlan[k] = null;
                    }),
                    child: const Text('Clear', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMealSlot(dayIndex, 'Breakfast', recipes),
            _buildMealSlot(dayIndex, 'Lunch', recipes),
            _buildMealSlot(dayIndex, 'Dinner', recipes),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(int dayIndex, String mealType, List<Recipe> recipes) {
    final entry = _weeklyPlan[dayIndex]![mealType];
    String displayName = 'Tap to add';
    bool hasEntry = false;

    if (entry is Recipe) {
      displayName = entry.name;
      hasEntry = true;
    } else if (entry is String && entry.isNotEmpty) {
      displayName = entry;
      hasEntry = true;
    }

    return GestureDetector(
      onTap: () => _showEntryPicker(dayIndex, mealType, recipes),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasEntry ? AppColors.olive.withOpacity(0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasEntry ? AppColors.olive.withOpacity(0.3) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: hasEntry ? AppColors.olive : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mealTimes[mealType]! + '  ' + mealType,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                  Text(
                    displayName.toTitleCase(),
                    style: TextStyle(
                      color: hasEntry ? Colors.white : Colors.white24,
                      fontSize: 13,
                      fontWeight: hasEntry ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasEntry)
              GestureDetector(
                onTap: () => setState(() => _weeklyPlan[dayIndex]![mealType] = null),
                child: const Icon(Icons.close, size: 16, color: Colors.white24),
              )
            else
              const Icon(Icons.add, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showEntryPicker(int dayIndex, String mealType, List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              '$mealType — ${_days[dayIndex]}',
              style: AppTextStyles.heading2,
            ),
          ),
          if (recipes.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.menu_book, color: AppColors.olive),
              title: const Text('Choose from Recipes', style: TextStyle(color: AppColors.beige)),
              onTap: () {
                Navigator.pop(context);
                _pickRecipe(dayIndex, mealType, recipes);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.olive),
            title: const Text('Manual Entry', style: TextStyle(color: AppColors.beige)),
            onTap: () {
              Navigator.pop(context);
              _manualEntry(dayIndex, mealType);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _pickRecipe(int dayIndex, String mealType, List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select Recipe'.toTitleCase(), style: AppTextStyles.heading2),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: recipes.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(recipes[i].name.toTitleCase(),
                      style: const TextStyle(color: Colors.white)),
                  subtitle: recipes[i].calories > 0
                      ? Text('${recipes[i].calories.toInt()} kcal · ${recipes[i].category}',
                      style: AppTextStyles.caption)
                      : null,
                  trailing: const Icon(Icons.add_circle_outline, color: AppColors.olive, size: 20),
                  onTap: () {
                    setState(() => _weeklyPlan[dayIndex]![mealType] = recipes[i]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _manualEntry(int dayIndex, String mealType) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('$mealType — ${_days[dayIndex]}',
            style: const TextStyle(color: AppColors.beige, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'What are you eating?',
            hintStyle: TextStyle(color: Colors.white38),
            labelText: 'Meal name',
            labelStyle: TextStyle(color: AppColors.olive),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _weeklyPlan[dayIndex]![mealType] = controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}