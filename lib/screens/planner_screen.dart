import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/recipe.dart';
import '../models/meal_routine.dart';
import '../models/meal_type.dart';
import '../screens/recipe_screen.dart';
import '../providers/routine_provider.dart';

class _MealSlot {
  String? name;
  String? recipeId;
  double? calories;
  double? protein;
  double? carbs;
  double? fat;

  _MealSlot({this.name, this.recipeId, this.calories, this.protein, this.carbs, this.fat});

  bool get isEmpty => name == null || name!.isEmpty;
}

const _mealTimes = {
  MealType.Breakfast: '08:00',
  MealType.Lunch: '12:30',
  MealType.Dinner: '19:00',
  MealType.Snack: '15:30',
};

const _mealLabels = {
  MealType.Breakfast: 'Breakfast',
  MealType.Lunch: 'Lunch',
  MealType.Dinner: 'Dinner',
  MealType.Snack: 'Snack',
};

const _days = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

const _meals = [MealType.Breakfast, MealType.Lunch, MealType.Dinner, MealType.Snack];

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  int _totalWeeks = 1;
  int _repeatFor = 4;
  late List<List<Map<MealType, _MealSlot>>> _weeks;
  bool _isGenerating = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initWeeks();
    _tabController = TabController(length: _totalWeeks, vsync: this);
  }

  void _initWeeks() {
    _weeks = List.generate(
      8, // Max supported template weeks
          (_) => List.generate(
        7,
            (_) => {for (final m in _meals) m: _MealSlot()},
      ),
    );
  }

  void _setWeekCount(int count) {
    setState(() {
      _totalWeeks = count;
      _tabController = TabController(length: _totalWeeks, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        bottom: _totalWeeks > 1
            ? TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.olive,
          labelColor: AppColors.olive,
          unselectedLabelColor: Colors.white38,
          tabs: List.generate(
            _totalWeeks,
                (i) => Tab(text: 'Week ${i + 1}'),
          ),
        )
            : null,
      ),
      body: Column(
        children: [
          _buildConfigBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(
                _totalWeeks,
                    (wi) => _buildWeekView(wi, recipes),
              ),
            ),
          ),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildConfigBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.card,
      child: Row(
        children: [
          Expanded(
            child: _configChip(
              label: 'Template',
              child: DropdownButton<int>(
                value: _totalWeeks,
                dropdownColor: AppColors.card,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(color: AppColors.olive, fontSize: 13, fontWeight: FontWeight.bold),
                items: List.generate(8, (i) => i + 1)
                    .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('$v Week${v > 1 ? 's' : ''}')))
                    .toList(),
                onChanged: (v) => _setWeekCount(v!),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _configChip(
              label: 'Duration',
              child: DropdownButton<int>(
                value: _repeatFor,
                dropdownColor: AppColors.card,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(color: AppColors.olive, fontSize: 13, fontWeight: FontWeight.bold),
                items: [1, 2, 4, 8, 12]
                    .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('$v Weeks')))
                    .toList(),
                onChanged: (v) => setState(() => _repeatFor = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configChip({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.olive.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }

  Widget _buildWeekView(int weekIndex, List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, dayIndex) =>
          _buildDayCard(weekIndex, dayIndex, recipes),
    );
  }

  Widget _buildDayCard(int weekIndex, int dayIndex, List<Recipe> recipes) {
    final dayPlan = _weeks[weekIndex][dayIndex];
    final hasAny = dayPlan.values.any((s) => !s.isEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasAny ? AppColors.olive.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(_days[dayIndex],
                    style: TextStyle(
                        color: hasAny ? AppColors.olive : AppColors.beige,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (hasAny)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white24),
                    onPressed: () => setState(() {
                      for (final m in _meals) _weeks[weekIndex][dayIndex][m] = _MealSlot();
                    }),
                  ),
              ],
            ),
          ),
          ..._meals.map((m) => _buildMealRow(weekIndex, dayIndex, m, recipes)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMealRow(int wi, int di, MealType meal, List<Recipe> recipes) {
    final slot = _weeks[wi][di][meal]!;
    final hasEntry = !slot.isEmpty;

    return InkWell(
      onTap: () => _showSlotPicker(wi, di, meal, recipes),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(_mealLabels[meal]!,
                  style: TextStyle(
                      color: hasEntry ? AppColors.olive : Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text(
                hasEntry ? slot.name!.toTitleCase() : 'Plan meal...',
                style: TextStyle(
                    color: hasEntry ? Colors.white : Colors.white10,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(hasEntry ? Icons.edit_outlined : Icons.add_circle_outline,
                size: 16, color: hasEntry ? AppColors.olive : Colors.white10),
          ],
        ),
      ),
    );
  }

  void _showSlotPicker(int wi, int di, MealType meal, List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('${_days[di]} ${_mealLabels[meal]}', style: AppTextStyles.heading2),
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: AppColors.olive),
            title: const Text('Pick from Recipes'),
            onTap: () {
              Navigator.pop(ctx);
              _pickRecipe(wi, di, meal, recipes);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note, color: AppColors.olive),
            title: const Text('Manual Entry'),
            onTap: () {
              Navigator.pop(ctx);
              _manualEntry(wi, di, meal);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _pickRecipe(int wi, int di, MealType meal, List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (_, sc) => Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Select Recipe', style: AppTextStyles.heading2)),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: recipes.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(recipes[i].name.toTitleCase()),
                  subtitle: Text('${recipes[i].calories.toInt()} kcal'),
                  onTap: () {
                    setState(() {
                      _weeks[wi][di][meal] = _MealSlot(
                        name: recipes[i].name,
                        recipeId: recipes[i].id,
                        calories: recipes[i].calories,
                        protein: recipes[i].protein,
                        carbs: recipes[i].carbs,
                        fat: recipes[i].fat,
                      );
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _manualEntry(int wi, int di, MealType meal) {
    final nameCtrl = TextEditingController(text: _weeks[wi][di][meal]!.name);
    final calCtrl = TextEditingController(text: _weeks[wi][di][meal]!.calories?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Manual Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Meal Name')),
            TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => _weeks[wi][di][meal] = _MealSlot(
                    name: nameCtrl.text,
                    calories: double.tryParse(calCtrl.text)
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.olive,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isGenerating ? null : _generate,
        child: _isGenerating
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text('Generate Rotation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      // Start this coming Monday
      final daysToMonday = (DateTime.monday - now.weekday + 7) % 7;
      final startDate = DateTime(now.year, now.month, now.day + daysToMonday);

      for (int rw = 0; rw < _repeatFor; rw++) {
        final tw = rw % _totalWeeks;
        for (int di = 0; di < 7; di++) {
          final date = startDate.add(Duration(days: rw * 7 + di));
          final dayPlan = _weeks[tw][di];
          for (final meal in _meals) {
            final slot = dayPlan[meal]!;
            if (slot.isEmpty) continue;

            await ref.read(routineProvider.notifier).addEntry(MealRoutine(
              id: '${date.millisecondsSinceEpoch}_${meal.index}',
              date: date,
              mealType: meal,
              recipeId: slot.recipeId,
              manualEntry: slot.name,
              time: _mealTimes[meal],
              calories: slot.calories,
              protein: slot.protein,
              carbs: slot.carbs,
              fat: slot.fat,
            ));
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rotation generated successfully!')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}