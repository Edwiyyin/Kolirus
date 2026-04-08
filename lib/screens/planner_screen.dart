import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../models/recipe.dart';
import '../models/meal_routine.dart';
import '../models/meal_type.dart';
import '../models/food_item.dart';
import '../screens/recipe_screen.dart';
import '../providers/routine_provider.dart';
import '../providers/pantry_provider.dart';
import '../providers/planner_provider.dart';


// These times MUST match the format used in routine_screen.dart's hourly view
// The routine screen builds time strings as 'HH:00' and checks entry.time == timeStr
const _mealTimes = {
  MealType.Breakfast: '08:00',
  MealType.Lunch:     '12:00',
  MealType.Dinner:    '19:00',
  MealType.Snack:     '15:00',
};

const _mealLabels = {
  MealType.Breakfast: 'Breakfast',
  MealType.Lunch:     'Lunch',
  MealType.Dinner:    'Dinner',
  MealType.Snack:     'Snack',
};

const _days = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

const _meals = [
  MealType.Breakfast,
  MealType.Lunch,
  MealType.Dinner,
  MealType.Snack,
];

class _MealSlot {
  String? name;
  String? recipeId;
  double? calories;
  double? protein;
  double? carbs;
  double? fat;

  _MealSlot({
    this.name,
    this.recipeId,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  bool get isEmpty => name == null || name!.trim().isEmpty;
}

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with TickerProviderStateMixin {
  int _totalWeeks = 1;
  int _repeatFor = 4;

  // 8 template weeks max; data preserved when resizing
  late List<List<Map<MealType, _MealSlot>>> _weeks;
  bool _isGenerating = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _weeks = _emptyWeeks(8);
    _tabController = TabController(length: _totalWeeks, vsync: this);
  }

  List<List<Map<MealType, _MealSlot>>> _emptyWeeks(int count) =>
      List.generate(count, (_) =>
          List.generate(7, (_) =>
          {for (final m in _meals) m: _MealSlot()}));

  void _setWeekCount(int count) {
    if (count == _totalWeeks) return;
    // Preserve existing slot data
    final newWeeks = _emptyWeeks(8);
    for (int w = 0; w < _weeks.length; w++) {
      for (int d = 0; d < 7; d++) {
        for (final m in _meals) {
          newWeeks[w][d][m] = _weeks[w][d][m]!;
        }
      }
    }
    _tabController.dispose();
    setState(() {
      _totalWeeks = count;
      _weeks = newWeeks;
      _tabController = TabController(length: count, vsync: this);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
              _totalWeeks, (i) => Tab(text: 'Week ${i + 1}')),
        )
            : null,
      ),
      body: Column(
        children: [
          _buildConfigBar(),
          Expanded(
            child: _totalWeeks == 1
                ? _buildWeekView(0, recipes)
                : TabBarView(
              controller: _tabController,
              children: List.generate(
                  _totalWeeks, (wi) => _buildWeekView(wi, recipes)),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Config bar ─────────────────────────────────────────────────────────────

  Widget _buildConfigBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      color: AppColors.card,
      child: Row(
        children: [
          Expanded(
            child: _configTile(
              label: 'Template weeks',
              child: DropdownButton<int>(
                value: _totalWeeks,
                dropdownColor: AppColors.card,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(
                    color: AppColors.olive,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                items: List.generate(8, (i) => i + 1)
                    .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('$v week${v > 1 ? 's' : ''}')))
                    .toList(),
                onChanged: (v) { if (v != null) _setWeekCount(v); },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _configTile(
              label: 'Repeat for',
              child: DropdownButton<int>(
                value: _repeatFor,
                dropdownColor: AppColors.card,
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(
                    color: AppColors.olive,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
                items: [1, 2, 4, 8, 12]
                    .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text('$v week${v > 1 ? 's' : ''}')))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _repeatFor = v); },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configTile({required String label, required Widget child}) =>
      Container(
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
            Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            child,
          ],
        ),
      );

  // ── Week / day / row ───────────────────────────────────────────────────────

  Widget _buildWeekView(int wi, List<Recipe> recipes) =>
      ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        itemBuilder: (_, di) => _buildDayCard(wi, di, recipes),
      );

  Widget _buildDayCard(int wi, int di, List<Recipe> recipes) {
    final dayPlan = _weeks[wi][di];
    final hasAny = dayPlan.values.any((s) => !s.isEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasAny
                ? AppColors.olive.withOpacity(0.3)
                : Colors.white10),
      ),
      child: Column(
        children: [
          // Day header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                Text(_days[di],
                    style: TextStyle(
                        color:
                        hasAny ? AppColors.olive : AppColors.beige,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (hasAny)
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 16, color: Colors.white24),
                    onPressed: () => setState(() {
                      for (final m in _meals) {
                        _weeks[wi][di][m] = _MealSlot();
                      }
                    }),
                  ),
              ],
            ),
          ),
          ..._meals.map((m) => _mealRow(wi, di, m, recipes)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _mealRow(int wi, int di, MealType meal, List<Recipe> recipes) {

    final template = ref.watch(plannerTemplateProvider);final slot = template[wi]?[di]?[meal] ?? MealSlot();
    final filled = !slot.isEmpty;
    return InkWell(
      onTap: () => _showSlotPicker(wi, di, meal, recipes),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                _mealLabels[meal]!,
                style: TextStyle(
                    color: filled ? AppColors.olive : Colors.white24,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                filled ? slot.name!.toTitleCase() : 'Tap to plan…',
                style: TextStyle(
                    color: filled ? Colors.white : Colors.white24,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (filled && slot.calories != null)
              Text('${slot.calories!.toInt()} kcal',
                  style: const TextStyle(
                      color: AppColors.olive, fontSize: 11)),
            const SizedBox(width: 4),
            Icon(
              filled ? Icons.edit_outlined : Icons.add_circle_outline,
              size: 16,
              color: filled ? AppColors.olive : Colors.white10,
            ),
          ],
        ),
      ),
    );
  }

  // ── Slot picker ────────────────────────────────────────────────────────────

  void _showSlotPicker(int wi, int di, MealType meal, List<Recipe> recipes) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${_days[di]} · ${_mealLabels[meal]}',
                style: AppTextStyles.heading2,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu,
                  color: AppColors.olive),
              title: const Text('From Recipes'),
              onTap: () {
                Navigator.pop(ctx);
                _pickRecipe(wi, di, meal, recipes);
              },
            ),
            ListTile(
              leading:
              const Icon(Icons.kitchen, color: AppColors.olive),
              title: const Text('From Pantry'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromPantry(wi, di, meal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note,
                  color: AppColors.olive),
              title: const Text('Manual Entry'),
              onTap: () {
                Navigator.pop(ctx);
                _manualEntry(wi, di, meal);
              },
            ),
            if (!_weeks[wi][di][meal]!.isEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Clear this slot',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  setState(() => _weeks[wi][di][meal] = _MealSlot());
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _pickRecipe(int wi, int di, MealType meal, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recipes yet — add some first!')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Recipe',
                    style: AppTextStyles.heading2)),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: recipes.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(recipes[i].name.toTitleCase()),
                  subtitle: recipes[i].calories > 0
                      ? Text('${recipes[i].calories.toInt()} kcal')
                      : null,
                  onTap: () {
                    final newSlot = MealSlot(
                      name: recipes[i].name,
                      recipeId: recipes[i].id,
                      calories: recipes[i].calories,
                      protein: recipes[i].protein,
                      carbs: recipes[i].carbs,
                      fat: recipes[i].fat,
                    );

                    // UPDATE THE PROVIDER
                    ref.read(plannerTemplateProvider.notifier).updateSlot(wi, di, meal, newSlot);

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

  void _pickFromPantry(int wi, int di, MealType meal) {
    final pantry = ref.read(pantryProvider);
    if (pantry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your pantry is empty!')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, sc) => Column(
          children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select from Pantry',
                    style: AppTextStyles.heading2)),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: pantry.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(pantry[i].name.toTitleCase()),
                  subtitle: Text(
                      '${pantry[i].calories.toInt()} kcal / 100g'),
                  onTap: () {
                    setState(() {
                      _weeks[wi][di][meal] = _MealSlot(
                        name: pantry[i].name,
                        calories: pantry[i].calories,
                        protein: pantry[i].protein,
                        carbs: pantry[i].carbs,
                        fat: pantry[i].fat,
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
    final existing = _weeks[wi][di][meal]!;
    final nameCtrl = TextEditingController(text: existing.name ?? '');
    final calCtrl = TextEditingController(
        text: existing.calories?.toString() ?? '');
    final protCtrl = TextEditingController(
        text: existing.protein?.toString() ?? '');
    final carbCtrl = TextEditingController(
        text: existing.carbs?.toString() ?? '');
    final fatCtrl = TextEditingController(
        text: existing.fat?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('${_mealLabels[meal]} — manual entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Meal name *'),
              _field(calCtrl, 'Calories (kcal)',
                  type: TextInputType.number),
              _field(protCtrl, 'Protein (g)',
                  type: TextInputType.number),
              _field(carbCtrl, 'Carbs (g)',
                  type: TextInputType.number),
              _field(fatCtrl, 'Fat (g)',
                  type: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => _weeks[wi][di][meal] = _MealSlot(
                  name: nameCtrl.text,
                  calories: double.tryParse(calCtrl.text),
                  protein: double.tryParse(protCtrl.text),
                  carbs: double.tryParse(carbCtrl.text),
                  fat: double.tryParse(fatCtrl.text),
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Set',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType type = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          keyboardType: type,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.olive),
          ),
        ),
      );

  // ── Footer / generate ──────────────────────────────────────────────────────

  Widget _buildFooter() {
    int filled = 0;
    for (int w = 0; w < _totalWeeks; w++) {
      for (int d = 0; d < 7; d++) {
        for (final m in _meals) {
          if (!_weeks[w][d][m]!.isEmpty) filled++;
        }
      }
    }
    final totalDays = _repeatFor * 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          if (filled > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$filled meal slot${filled == 1 ? '' : 's'} planned · '
                    'will repeat over $totalDays days in your Routine',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed:
            (_isGenerating || filled == 0) ? null : _generate,
            child: _isGenerating
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(
              filled == 0
                  ? 'Add meals above first'
                  : 'Add to Routine · $_repeatFor weeks',
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ── Generate ───────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      // Start from the coming Monday (today if today is Monday)
      final weekday = now.weekday; // DateTime.monday == 1
      final daysToMon =
      weekday == DateTime.monday ? 0 : (8 - weekday) % 7;
      final startDate = DateTime(now.year, now.month, now.day)
          .add(Duration(days: daysToMon));

      int count = 0;

      for (int repeat = 0; repeat < _repeatFor; repeat++) {
        final templateWeek = repeat % _totalWeeks;
        for (int di = 0; di < 7; di++) {
          final date =
          startDate.add(Duration(days: repeat * 7 + di));
          for (final meal in _meals) {
            final slot = _weeks[templateWeek][di][meal]!;
            if (slot.isEmpty) continue;

            // Build a unique, deterministic ID so re-running the planner
            // with the same template replaces rather than duplicates entries.
            final entryId =
                '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${meal.index}';

            final entry = MealRoutine(
              id: entryId,
              date: date,
              mealType: meal,
              recipeId: slot.recipeId,
              manualEntry: slot.name,
              // time must be 'HH:00' — the routine screen builds
              // timeStr as '${hour.toString().padLeft(2,'0')}:00'
              time: _mealTimes[meal],
              isEaten: false,
              calories: slot.calories,
              protein: slot.protein,
              carbs: slot.carbs,
              fat: slot.fat,
            );

            // insertMealRoutine uses REPLACE conflict algorithm, so
            // re-generating with the same template safely overwrites.
            await ref
                .read(routineProvider.notifier)
                .addEntry(entry);
            count++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count meals added to your Routine starting '
                  '${DateFormat('d MMM').format(startDate)}. '
                  'Open the Routine tab to see them.',
            ),
            backgroundColor: AppColors.olive,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}