import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../providers/food_log_provider.dart';
import '../models/meal_log.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../providers/pantry_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/recipe_screen.dart'; 
import '../models/meal_type.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(foodLogProvider.notifier).getDailyTotals();
    final logs = ref.watch(foodLogProvider);
    final settings = ref.watch(settingsProvider);
    final userName = settings['name'] ?? 'User';
    final calories = totals['calories'] ?? 0;
    final double goal = settings['calorie_goal'] ?? 2000.0;

    final pantry = ref.watch(pantryProvider);
    final recipes = ref.watch(recipeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello ${userName.toString().toTitleCase()},',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 16)),
                  const Text('Ready To Fuel?', style: AppTextStyles.heading1),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showLogMealBottomSheet(context, ref),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Log Meal',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          GestureDetector(
            onTap: () => _showEditGoalDialog(context, ref, goal),
            child: Center(
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
                      valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.olive),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${calories.toInt()}',
                          style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.beige)),
                      const Text('Kcal',
                          style: TextStyle(
                              color: AppColors.olive,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Of ${goal.toInt()}', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
          const Text('Recommended Recipes', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          _RecommendedRecipes(pantry: pantry, recipes: recipes),

          const SizedBox(height: 32),
          const Text('Quick Macros', style: AppTextStyles.heading2),
          const SizedBox(height: 16),

          Row(
            children: [
              _MacroMiniCard(
                  label: 'Protein',
                  value: '${totals['protein']?.toInt() ?? 0}g',
                  color: AppColors.olive),
              const SizedBox(width: 12),
              _MacroMiniCard(
                  label: 'Carbs',
                  value: '${totals['carbs']?.toInt() ?? 0}g',
                  color: AppColors.olive.withOpacity(0.6)),
              const SizedBox(width: 12),
              _MacroMiniCard(
                  label: 'Fat',
                  value: '${totals['fat']?.toInt() ?? 0}g',
                  color: AppColors.olive.withOpacity(0.3)),
            ],
          ),

          const SizedBox(height: 32),
          const Text("Today's Logs", style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No Meals Logged Today',
                        style: TextStyle(color: Colors.white24))))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _MealLogTile(log: log);
              },
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WidgetRef ref, double currentGoal) {
    final ctrl = TextEditingController(text: currentGoal.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Daily Calorie Goal'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'Kcal'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            final val = double.tryParse(ctrl.text);
            if (val != null && val > 0) {
              ref.read(settingsProvider.notifier).updateCalorieGoal(val);
              Navigator.pop(context);
            }
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _showLogMealBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LogMealSheet(),
    );
  }
}

class _RecommendedRecipes extends StatelessWidget {
  final List<FoodItem> pantry;
  final List<Recipe> recipes;

  const _RecommendedRecipes({required this.pantry, required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return const Text('Add some recipes to get recommendations!', style: TextStyle(color: Colors.white38));
    }

    final recommended = recipes.map((recipe) {
      int matches = 0;
      for (var ing in recipe.ingredients) {
        if (pantry.any((p) => p.name.toLowerCase().contains(ing.name.toLowerCase()))) {
          matches++;
        }
      }
      return {'recipe': recipe, 'matches': matches};
    }).toList();

    recommended.sort((a, b) => (b['matches'] as int).compareTo(a['matches'] as int));

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommended.length.clamp(0, 5),
        itemBuilder: (context, index) {
          final recipe = recommended[index]['recipe'] as Recipe;
          final matches = recommended[index]['matches'] as int;
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: matches > 0 ? AppColors.olive.withOpacity(0.3) : Colors.transparent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name.toTitleCase(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.kitchen, size: 12, color: matches > 0 ? AppColors.olive : Colors.white24),
                    const SizedBox(width: 4),
                    Text('$matches/${recipe.ingredients.length} Items', 
                      style: TextStyle(fontSize: 10, color: matches > 0 ? AppColors.olive : Colors.white24)),
                  ],
                ),
                Text(recipe.category.toTitleCase(), style: AppTextStyles.caption),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogMealSheet extends ConsumerStatefulWidget {
  final MealLog? editLog;
  const _LogMealSheet({this.editLog});

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.editLog != null) {
      _tabController.index = 2; // Default to manual for editing
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantry = ref.watch(pantryProvider);
    final recipes = ref.watch(recipeProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(widget.editLog != null ? 'Edit Meal' : 'Log A Meal', style: AppTextStyles.heading1),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          if (widget.editLog == null)
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.olive,
              labelColor: AppColors.olive,
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'From Kitchen'),
                Tab(text: 'From Recipes'),
                Tab(text: 'Manual'),
              ],
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: widget.editLog != null ? const NeverScrollableScrollPhysics() : null,
              children: [
                // Tab 1: From Kitchen
                pantry.isEmpty
                    ? const Center(
                    child: Text('Kitchen Is Empty. Scan Items First!',
                        style: TextStyle(color: Colors.white38)))
                    : _KitchenMealPicker(pantry: pantry),

                // Tab 2: From Recipes
                recipes.isEmpty
                    ? const Center(
                    child: Text('No Recipes Found.',
                        style: TextStyle(color: Colors.white38)))
                    : _RecipeMealPicker(recipes: recipes),

                // Tab 3: Manual Entry
                _ManualMealEntry(editLog: widget.editLog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeMealPicker extends ConsumerStatefulWidget {
  final List<Recipe> recipes;
  const _RecipeMealPicker({required this.recipes});

  @override
  ConsumerState<_RecipeMealPicker> createState() => _RecipeMealPickerState();
}

class _RecipeMealPickerState extends ConsumerState<_RecipeMealPicker> {
  Recipe? _selected;
  MealType _mealType = MealType.Lunch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<Recipe>(
            value: _selected,
            hint: const Text('Select a recipe',
                style: TextStyle(color: Colors.white38)),
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Recipe',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: widget.recipes
                .map((recipe) => DropdownMenuItem(
              value: recipe,
              child: Text(recipe.name.toTitleCase(),
                  style: const TextStyle(color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) => setState(() => _selected = val),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Meal type',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: MealType.values
                .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name.toTitleCase(),
                    style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_selected != null) {
                final log = MealLog(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  foodItemId: _selected!.id ?? 'recipe',
                  foodName: _selected!.name,
                  quantity: 1.0, 
                  consumedAt: DateTime.now(),
                  type: _mealType,
                  calories: _selected!.calories,
                  protein: _selected!.protein,
                  carbs: _selected!.carbs,
                  fat: _selected!.fat,
                  saturatedFat: _selected!.saturatedFat,
                  sodium: _selected!.sodium,
                  cholesterol: _selected!.cholesterol,
                  fiber: _selected!.fiber,
                  sugar: _selected!.sugar,
                );
                ref.read(foodLogProvider.notifier).addLog(log);
                Navigator.pop(context);
              }
            },
            child: const Text('Log Recipe',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _KitchenMealPicker extends ConsumerStatefulWidget {
  final List<FoodItem> pantry;
  const _KitchenMealPicker({required this.pantry});

  @override
  ConsumerState<_KitchenMealPicker> createState() => _KitchenMealPickerState();
}

class _KitchenMealPickerState extends ConsumerState<_KitchenMealPicker> {
  FoodItem? _selected;
  MealType _mealType = MealType.Lunch;
  final _quantityController = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<FoodItem>(
            value: _selected,
            hint: const Text('Select Food From Kitchen',
                style: TextStyle(color: Colors.white38)),
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Food Item',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: widget.pantry
                .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item.name.toTitleCase(),
                  style: const TextStyle(color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) => setState(() => _selected = val),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Meal Type',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: MealType.values
                .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name.toTitleCase(),
                    style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Quantity (Grams)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_selected != null) {
                final qty =
                    double.tryParse(_quantityController.text) ?? 100;
                ref
                    .read(foodLogProvider.notifier)
                    .addMeal(_selected!, qty, _mealType);
                Navigator.pop(context);
              }
            },
            child: const Text('Log Meal',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ManualMealEntry extends ConsumerStatefulWidget {
  final MealLog? editLog;
  const _ManualMealEntry({this.editLog});

  @override
  ConsumerState<_ManualMealEntry> createState() => _ManualMealEntryState();
}

class _ManualMealEntryState extends ConsumerState<_ManualMealEntry> {
  late TextEditingController _nameController;
  late TextEditingController _calController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _sodiumController;
  late MealType _mealType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.editLog?.foodName ?? '');
    _calController = TextEditingController(text: widget.editLog?.calories.toInt().toString() ?? '');
    _proteinController = TextEditingController(text: widget.editLog?.protein.toString() ?? '');
    _carbsController = TextEditingController(text: widget.editLog?.carbs.toString() ?? '');
    _fatController = TextEditingController(text: widget.editLog?.fat.toString() ?? '');
    _fiberController = TextEditingController(text: widget.editLog?.fiber.toString() ?? '');
    _sodiumController = TextEditingController(text: widget.editLog?.sodium.toString() ?? '');
    _mealType = widget.editLog?.type ?? MealType.Lunch;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Meal Name *',
                labelStyle: TextStyle(color: AppColors.olive)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MealType>(
            value: _mealType,
            dropdownColor: AppColors.card,
            decoration: const InputDecoration(
                labelText: 'Meal Type',
                labelStyle: TextStyle(color: AppColors.olive)),
            items: MealType.values
                .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.name.toTitleCase(),
                    style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _calController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Calories (Kcal)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _proteinController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Protein (G)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _carbsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Carbs (G)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _fatController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Fat (G)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _fiberController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Fiber (G)',
                    labelStyle: TextStyle(color: AppColors.olive)),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          TextField(
            controller: _sodiumController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                labelText: 'Sodium (Mg)',
                labelStyle: TextStyle(color: AppColors.olive)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                final log = MealLog(
                  id: widget.editLog?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  foodItemId: widget.editLog?.foodItemId ?? 'manual',
                  foodName: _nameController.text,
                  quantity: widget.editLog?.quantity ?? 1.0,
                  consumedAt: widget.editLog?.consumedAt ?? DateTime.now(),
                  type: _mealType,
                  calories: double.tryParse(_calController.text) ?? 0,
                  protein: double.tryParse(_proteinController.text) ?? 0,
                  carbs: double.tryParse(_carbsController.text) ?? 0,
                  fat: double.tryParse(_fatController.text) ?? 0,
                  fiber: double.tryParse(_fiberController.text) ?? 0,
                  sodium: double.tryParse(_sodiumController.text) ?? 0,
                );
                if (widget.editLog != null) {
                  ref.read(foodLogProvider.notifier).updateLog(log);
                } else {
                  ref.read(foodLogProvider.notifier).addLog(log);
                }
                Navigator.pop(context);
              }
            },
            child: Text(widget.editLog != null ? 'Update Meal' : 'Log Meal',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MealLogTile extends ConsumerWidget {
  final MealLog log;
  const _MealLogTile({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(log.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(foodLogProvider.notifier).removeLog(log.id!);
      },
      child: GestureDetector(
        onTap: () => _showEditLogSheet(context, ref, log),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.olive.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.restaurant,
                    color: AppColors.olive, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.foodName.toTitleCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      '${log.type.name.toTitleCase()} • ${DateFormat('hh:mm a').format(log.consumedAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Text('${log.calories.toInt()} Kcal',
                  style: const TextStyle(
                      color: AppColors.olive, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditLogSheet(BuildContext context, WidgetRef ref, MealLog log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LogMealSheet(editLog: log),
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroMiniCard(
      {required this.label, required this.value, required this.color});

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
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.beige)),
            const SizedBox(height: 4),
            Text(label.toTitleCase(), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
