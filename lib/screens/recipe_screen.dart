import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
import '../providers/pantry_provider.dart';
import '../utils/constants.dart';

final recipeProvider = StateNotifierProvider<RecipeNotifier, List<Recipe>>((ref) {
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
}

class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeProvider);

    return Column(
      children: [
        Expanded(
          child: recipes.isEmpty
              ? const Center(child: Text('no recipes yet. tap + to add one!', style: AppTextStyles.body))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(recipe.name.toLowerCase(), style: AppTextStyles.heading2),
                        subtitle: Text('${recipe.ingredients.length} ingredients', style: const TextStyle(color: AppColors.beige)),
                        trailing: const Icon(Icons.edit, color: AppColors.olive),
                        onTap: () => _showRecipeEditor(context, ref, recipe: recipe),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 80, right: 16),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'add_recipe_fab',
              onPressed: () => _showRecipeEditor(context, ref),
              backgroundColor: AppColors.olive,
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  void _showRecipeEditor(BuildContext context, WidgetRef ref, {Recipe? recipe}) {
    final isEditing = recipe != null;
    final nameController = TextEditingController(text: recipe?.name ?? '');
    final ingredientsController = TextEditingController(
      text: recipe?.ingredients.map((i) => i.name).join('\n') ?? ''
    );
    final instructionsController = TextEditingController(
      text: recipe?.instructions.join('\n') ?? ''
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEditing ? 'edit recipe' : 'create new recipe', style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'recipe name',
                  labelStyle: TextStyle(color: AppColors.olive),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.beige)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredientsController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'ingredients (one per line)',
                  labelStyle: TextStyle(color: AppColors.olive),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.beige)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsController,
                maxLines: 6,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'description',
                  labelStyle: TextStyle(color: AppColors.olive),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.beige)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final ingredients = ingredientsController.text
                        .split('\n')
                        .where((s) => s.trim().isNotEmpty)
                        .map((s) => RecipeIngredient(foodItemId: '', name: s, amount: 0, unit: ''))
                        .toList();
                    final instructions = instructionsController.text
                        .split('\n')
                        .where((s) => s.trim().isNotEmpty)
                        .toList();

                    final newRecipe = Recipe(
                      id: isEditing ? recipe.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text.toLowerCase(),
                      ingredients: ingredients,
                      instructions: instructions,
                    );

                    if (isEditing) {
                      ref.read(recipeProvider.notifier).updateRecipe(newRecipe);
                    } else {
                      ref.read(recipeProvider.notifier).addRecipe(newRecipe);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'update' : 'save', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
