import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';
import '../models/food_item.dart';
import '../providers/pantry_provider.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

final recipeProvider =
StateNotifierProvider<RecipeNotifier, List<Recipe>>((ref) {
  return RecipeNotifier();
});

class RecipeNotifier extends StateNotifier<List<Recipe>> {
  RecipeNotifier() : super([]) {
    loadRecipes();
  }

  final _db = DatabaseService.instance;

  Future<void> loadRecipes() async {
    state = await _db.getRecipes();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _db.insertRecipe(recipe);
    await loadRecipes();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _db.insertRecipe(recipe);
    await loadRecipes();
  }

  Future<void> deleteRecipe(String id) async {
    final db = await _db.database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    await loadRecipes();
  }

  Future<String> exportToJson() async {
    final recipes = state;
    final jsonList = recipes.map((r) => r.toMap()).toList();
    return jsonEncode(jsonList);
  }

  Future<int> importFromJson(String jsonStr) async {
    final List<dynamic> list = jsonDecode(jsonStr);
    int count = 0;
    for (final item in list) {
      try {
        final recipe = Recipe.fromMap(Map<String, dynamic>.from(item));
        final newRecipe = Recipe(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$count',
          name: recipe.name,
          description: recipe.description,
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          imageUrl: recipe.imageUrl,
          isCommunityShared: recipe.isCommunityShared,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          servings: recipe.servings,
          category: recipe.category,
          calories: recipe.calories,
          protein: recipe.protein,
          carbs: recipe.carbs,
          fat: recipe.fat,
          saturatedFat: recipe.saturatedFat,
          sodium: recipe.sodium,
          cholesterol: recipe.cholesterol,
          fiber: recipe.fiber,
          sugar: recipe.sugar,
        );
        await _db.insertRecipe(newRecipe);
        count++;
      } catch (_) {}
    }
    await loadRecipes();
    return count;
  }
}

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key});

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final allRecipes = ref.watch(recipeProvider);
    final filteredRecipes = allRecipes.where((r) {
      final matchesSearch =
      r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          hintStyle:
                          const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.olive),
                          filled: true,
                          fillColor: AppColors.card,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon:
                      const Icon(Icons.more_vert, color: AppColors.olive),
                      color: AppColors.card,
                      onSelected: (val) {
                        if (val == 'export') _exportRecipes(context);
                        if (val == 'import') _importRecipes(context);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(children: [
                            Icon(Icons.file_upload,
                                color: AppColors.olive, size: 18),
                            SizedBox(width: 8),
                            Text('Export JSON',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(children: [
                            Icon(Icons.file_download,
                                color: AppColors.olive, size: 18),
                            SizedBox(width: 8),
                            Text('Import JSON',
                                style: TextStyle(color: Colors.white)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Breakfast',
                      'Lunch',
                      'Dinner',
                      'Snack',
                      'Dessert'
                    ].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: AppColors.olive,
                          labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white),
                          backgroundColor: AppColors.card,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRecipes.isEmpty
                ? const Center(
                child: Text('No recipes found',
                    style: TextStyle(color: Colors.white38)))
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredRecipes.length,
              itemBuilder: (context, index) {
                final recipe = filteredRecipes[index];
                return _RecipeCard(
                  recipe: recipe,
                  onEdit: () => _showRecipeEditor(context, ref,
                      recipe: recipe),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecipeEditor(context, ref),
        backgroundColor: AppColors.olive,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // ── Export: write temp file then share/save via system picker ─────────────
  Future<void> _exportRecipes(BuildContext context) async {
    try {
      final jsonStr = await ref.read(recipeProvider.notifier).exportToJson();

      // Write to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kolirus_recipes.json');
      await file.writeAsString(jsonStr);

      // Share sheet lets the user pick where to save
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Kolirus Recipes Export',
      );

      if (context.mounted) {
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recipes exported successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ── Import: open file picker so user selects a .json file ─────────────────
  Future<void> _importRecipes(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Kolirus Recipes JSON',
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final jsonStr = await file.readAsString();

      if (!context.mounted) return;
      final count =
      await ref.read(recipeProvider.notifier).importFromJson(jsonStr);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count recipe(s) successfully!'),
            backgroundColor: AppColors.olive,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _showRecipeEditor(BuildContext context, WidgetRef ref,
      {Recipe? recipe}) {
    final isEditing = recipe != null;
    final nameController = TextEditingController(text: recipe?.name ?? '');
    final servingsController =
    TextEditingController(text: recipe?.servings.toString() ?? '1');
    final prepController =
    TextEditingController(text: recipe?.prepTime.toString() ?? '0');
    final cookController =
    TextEditingController(text: recipe?.cookTime.toString() ?? '0');
    final calController = TextEditingController(
        text: recipe?.calories.toStringAsFixed(0) ?? '');
    final proteinController = TextEditingController(
        text: recipe?.protein.toStringAsFixed(0) ?? '');
    final carbsController =
    TextEditingController(text: recipe?.carbs.toStringAsFixed(0) ?? '');
    final fatController =
    TextEditingController(text: recipe?.fat.toStringAsFixed(0) ?? '');
    final instructionsController =
    TextEditingController(text: recipe?.instructions.join('\n') ?? '');
    String selectedCat = recipe?.category ?? 'Lunch';

    List<RecipeIngredient> ingredients = recipe != null
        ? List<RecipeIngredient>.from(recipe.ingredients)
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? 'Edit Recipe' : 'New Recipe',
                    style: AppTextStyles.heading1),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: AppColors.olive)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: servingsController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Servings',
                            labelStyle: TextStyle(color: AppColors.olive)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCat,
                        dropdownColor: AppColors.card,
                        decoration: const InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: AppColors.olive)),
                        items: [
                          'Breakfast',
                          'Lunch',
                          'Dinner',
                          'Snack',
                          'Dessert'
                        ]
                            .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: const TextStyle(
                                    color: Colors.white))))
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => selectedCat = val!),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: prepController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Prep (min)',
                            labelStyle: TextStyle(color: AppColors.olive)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cookController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Cook (min)',
                            labelStyle: TextStyle(color: AppColors.olive)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Nutrition (per serving)',
                      style: TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: calController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Calories',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                          labelStyle: TextStyle(color: AppColors.olive)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Ingredients
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ingredients',
                        style: TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.kitchen,
                              color: AppColors.olive, size: 16),
                          label: const Text('From Pantry',
                              style: TextStyle(
                                  color: AppColors.olive, fontSize: 12)),
                          onPressed: () => _showPantryIngredientPicker(
                              context, ref, ingredients, setModalState),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add,
                              color: AppColors.olive, size: 16),
                          label: const Text('Manual',
                              style: TextStyle(
                                  color: AppColors.olive, fontSize: 12)),
                          onPressed: () => _showManualIngredientDialog(
                              context, ingredients, setModalState),
                        ),
                      ],
                    ),
                  ],
                ),
                if (ingredients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                        'No ingredients yet — add from pantry or manually',
                        style:
                        TextStyle(color: Colors.white24, fontSize: 12)),
                  )
                else
                  ...ingredients.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: AppColors.olive),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${e.value.amount} ${e.value.unit}  ${e.value.name}'
                                .trim(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close,
                              size: 16, color: Colors.white38),
                          onPressed: () => setModalState(
                                  () => ingredients.removeAt(e.key)),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    labelStyle: TextStyle(color: AppColors.olive),
                    hintText: 'One step per line',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final insts = instructionsController.text
                          .split('\n')
                          .where((s) => s.trim().isNotEmpty)
                          .toList();
                      final recipeId = isEditing
                          ? recipe.id!
                          : DateTime.now()
                          .millisecondsSinceEpoch
                          .toString();
                      final newRecipe = Recipe(
                        id: recipeId,
                        name: nameController.text,
                        category: selectedCat,
                        servings:
                        int.tryParse(servingsController.text) ?? 1,
                        prepTime: int.tryParse(prepController.text) ?? 0,
                        cookTime: int.tryParse(cookController.text) ?? 0,
                        ingredients: ingredients,
                        instructions: insts,
                        imageUrl: recipe?.imageUrl,
                        calories:
                        double.tryParse(calController.text) ?? 0,
                        protein:
                        double.tryParse(proteinController.text) ?? 0,
                        carbs: double.tryParse(carbsController.text) ?? 0,
                        fat: double.tryParse(fatController.text) ?? 0,
                      );
                      if (isEditing) {
                        ref
                            .read(recipeProvider.notifier)
                            .updateRecipe(newRecipe);
                      } else {
                        ref
                            .read(recipeProvider.notifier)
                            .addRecipe(newRecipe);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Save',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPantryIngredientPicker(BuildContext context, WidgetRef ref,
      List<RecipeIngredient> ingredients, StateSetter setModalState) {
    final pantry = ref.read(pantryProvider);
    if (pantry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your pantry is empty. Add items first!')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Pick From Pantry', style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: pantry.length,
                  itemBuilder: (ctx, i) {
                    final item = pantry[i];
                    final alreadyAdded = ingredients.any((ing) =>
                    ing.name.toLowerCase() ==
                        item.name.toLowerCase());
                    return ListTile(
                      title: Text(item.name.toTitleCase(),
                          style: TextStyle(
                              color: alreadyAdded
                                  ? AppColors.olive
                                  : Colors.white)),
                      subtitle: Text('${item.calories.toInt()} kcal / 100g',
                          style: AppTextStyles.caption),
                      trailing: alreadyAdded
                          ? const Icon(Icons.check_circle,
                          color: AppColors.olive, size: 20)
                          : const Icon(Icons.add_circle_outline,
                          color: Colors.white38, size: 20),
                      onTap: alreadyAdded
                          ? null
                          : () {
                        Navigator.pop(ctx);
                        _showAmountDialog(context, item,
                            ingredients, setModalState);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountDialog(BuildContext context, FoodItem item,
      List<RecipeIngredient> ingredients, StateSetter setModalState) {
    final amountCtrl = TextEditingController(text: '100');
    String selectedUnit = 'g';
    const units = [
      'g', 'kg', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'piece', 'slice', 'pinch'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Add ${item.name.toTitleCase()}',
              style:
              const TextStyle(color: AppColors.beige, fontSize: 16)),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: AppColors.olive),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedUnit,
                dropdownColor: AppColors.card,
                items: units
                    .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(u,
                        style:
                        const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) =>
                    setDialogState(() => selectedUnit = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive),
              onPressed: () {
                setModalState(() {
                  ingredients.add(RecipeIngredient(
                    name: item.name,
                    amount: amountCtrl.text.isEmpty
                        ? '100'
                        : amountCtrl.text,
                    unit: selectedUnit,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualIngredientDialog(BuildContext context,
      List<RecipeIngredient> ingredients, StateSetter setModalState) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '100');
    String selectedUnit = 'g';
    const units = [
      'g', 'kg', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'piece', 'slice', 'pinch'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Add Ingredient',
              style: TextStyle(color: AppColors.beige)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ingredient name',
                  labelStyle: TextStyle(color: AppColors.olive),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: AppColors.olive),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: selectedUnit,
                    dropdownColor: AppColors.card,
                    items: units
                        .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u,
                            style: const TextStyle(
                                color: Colors.white))))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedUnit = val!),
                  ),
                ],
              ),
            ],
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
                  setModalState(() {
                    ingredients.add(RecipeIngredient(
                      name: nameCtrl.text,
                      amount: amountCtrl.text.isEmpty
                          ? '1'
                          : amountCtrl.text,
                      unit: selectedUnit,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onEdit;
  const _RecipeCard({required this.recipe, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(context, ref, recipe),
      onLongPress: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: recipe.imageUrl != null
                    ? Image.network(recipe.imageUrl!,
                    fit: BoxFit.cover, width: double.infinity)
                    : Container(
                    color: AppColors.olive.withOpacity(0.1),
                    child: const Center(
                        child: Icon(Icons.restaurant,
                            color: AppColors.olive, size: 40))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.olive),
                      const SizedBox(width: 4),
                      Text('${recipe.prepTime + recipe.cookTime} min',
                          style: AppTextStyles.caption),
                      const Spacer(),
                      Text(recipe.category,
                          style: TextStyle(
                              color: AppColors.olive.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (recipe.calories > 0)
                    Text('${recipe.calories.toInt()} kcal',
                        style: const TextStyle(
                            color: AppColors.olive,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(
      BuildContext context, WidgetRef ref, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      image: recipe.imageUrl != null
                          ? DecorationImage(
                          image: NetworkImage(recipe.imageUrl!),
                          fit: BoxFit.cover)
                          : null,
                    ),
                    child: recipe.imageUrl == null
                        ? const Icon(Icons.restaurant,
                        size: 80, color: AppColors.olive)
                        : null,
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(recipe.name,
                                style: AppTextStyles.heading1)),
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.olive),
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit();
                            }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(recipe.category.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.olive,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem(Icons.people_outline,
                            '${recipe.servings} servings'),
                        _infoItem(Icons.timer_outlined,
                            '${recipe.prepTime}m prep'),
                        _infoItem(Icons.outdoor_grill_outlined,
                            '${recipe.cookTime}m cook'),
                      ],
                    ),
                    if (recipe.calories > 0) ...[
                      const Divider(color: Colors.white10, height: 30),
                      const Text('Nutrition per serving',
                          style: TextStyle(
                              color: AppColors.olive,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _macroChip(
                              '${recipe.calories.toInt()}', 'kcal'),
                          _macroChip(
                              '${recipe.protein.toInt()}g', 'protein'),
                          _macroChip(
                              '${recipe.carbs.toInt()}g', 'carbs'),
                          _macroChip('${recipe.fat.toInt()}g', 'fat'),
                        ],
                      ),
                    ],
                    const Divider(color: Colors.white10, height: 30),
                    const Text('Ingredients', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: AppColors.olive),
                          const SizedBox(width: 12),
                          Text('${ing.amount}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.olive)),
                          const SizedBox(width: 4),
                          Text(ing.unit,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.beige)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(ing.name,
                                  style: const TextStyle(
                                      color: Colors.white70))),
                        ],
                      ),
                    )),
                    const Divider(color: Colors.white10, height: 30),
                    const Text('Instructions', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    ...recipe.instructions
                        .asMap()
                        .entries
                        .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.olive,
                              child: Text('${entry.key + 1}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.bold))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Text(entry.value,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.5))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.redAccent.withOpacity(0.1),
                          foregroundColor: Colors.redAccent,
                          minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        ref
                            .read(recipeProvider.notifier)
                            .deleteRecipe(recipe.id!);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete Recipe'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(text,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _macroChip(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.beige,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}