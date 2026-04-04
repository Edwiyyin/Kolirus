import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../models/recipe.dart';
import '../models/food_item.dart';
import '../screens/recipe_screen.dart';
import '../main.dart'; // For toTitleCase

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  int _weeks = 1;
  final Map<int, Map<String, dynamic>> _weeklyPlan = {
    0: {'Breakfast': null, 'Lunch': null, 'Dinner': null}, // Monday
    1: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
    2: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
    3: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
    4: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
    5: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
    6: {'Breakfast': null, 'Lunch': null, 'Dinner': null},
  };

  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Routine Planner'.toTitleCase()),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.card,
            child: Column(
              children: [
                Text('Customize Your 1-Week Cycle'.toTitleCase(), 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('This Plan Will Repeat For The Chosen Number Of Weeks.'.toTitleCase(), 
                  style: const TextStyle(fontSize: 12, color: Colors.white54), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Repeat For: '.toTitleCase()),
                    DropdownButton<int>(
                      value: _weeks,
                      dropdownColor: AppColors.card,
                      items: List.generate(10, (i) => i + 1).map((i) => 
                        DropdownMenuItem(value: i, child: Text('$i Weeks'.toTitleCase()))
                      ).toList(),
                      onChanged: (val) => setState(() => _weeks = val!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, dayIndex) {
                return _buildDayCard(dayIndex);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.olive,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Routine Generated For $_weeks Weeks!'.toTitleCase()))
                );
                Navigator.pop(context);
              },
              child: Text('Generate & Start Routine'.toTitleCase(), 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayIndex) {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_days[dayIndex].toTitleCase(), 
              style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMealSlot(dayIndex, 'Breakfast'),
            _buildMealSlot(dayIndex, 'Lunch'),
            _buildMealSlot(dayIndex, 'Dinner'),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(int dayIndex, String mealType) {
    final entry = _weeklyPlan[dayIndex]![mealType];
    String displayName = 'Tap To Select Food'.toTitleCase();
    if (entry is Recipe) displayName = entry.name;
    if (entry is String) displayName = entry;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(mealType.toTitleCase(), style: const TextStyle(fontSize: 12, color: Colors.white54)),
      subtitle: Text(displayName.toTitleCase(), 
        style: TextStyle(color: entry != null ? Colors.white : Colors.white24, fontSize: 14)),
      trailing: entry != null 
        ? const Icon(Icons.check_circle, color: AppColors.olive, size: 20) 
        : const Icon(Icons.add_circle_outline, size: 20),
      onTap: () => _showEntryPicker(dayIndex, mealType),
    );
  }

  void _showEntryPicker(int dayIndex, String mealType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.menu_book, color: AppColors.olive),
            title: Text('Choose From Recipes'.toTitleCase()),
            onTap: () {
              Navigator.pop(context);
              _pickRecipe(dayIndex, mealType);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.olive),
            title: Text('Manual Entry'.toTitleCase()),
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

  void _pickRecipe(int dayIndex, String mealType) {
    final recipes = ref.read(recipeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Select Recipe'.toTitleCase(), style: AppTextStyles.heading2),
          ),
          Expanded(
            child: recipes.isEmpty 
              ? Center(child: Text('No Recipes Found'.toTitleCase()))
              : ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(recipes[i].name.toTitleCase()),
                    onTap: () {
                      setState(() {
                        _weeklyPlan[dayIndex]![mealType] = recipes[i];
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  void _manualEntry(int dayIndex, String mealType) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Manual Food Entry'.toTitleCase()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'What Are You Eating?'.toTitleCase()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.toTitleCase())),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              setState(() {
                _weeklyPlan[dayIndex]![mealType] = controller.text;
              });
              Navigator.pop(context);
            }
          }, child: Text('Add'.toTitleCase())),
        ],
      ),
    );
  }
}
