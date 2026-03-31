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
}

class RecipeScreen extends ConsumerWidget {
  const RecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Recipes', style: TextStyle(color: AppColors.beige)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.beige),
      ),
      body: recipes.isEmpty
          ? const Center(child: Text('No recipes yet. Tap + to add one!', style: AppTextStyles.body))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(recipe.name, style: AppTextStyles.heading2),
                    subtitle: Text('${recipe.ingredients.length} Ingredients', style: const TextStyle(color: AppColors.beige)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.violet),
                    onTap: () => _showRecipeDetails(context, recipe),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context, ref),
        backgroundColor: AppColors.violet,
        child: const Icon(Icons.add, color: AppColors.beige),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(recipe.name, style: AppTextStyles.heading1),
              const Divider(color: AppColors.violet),
              const Text('Ingredients:', style: AppTextStyles.heading2),
              ...recipe.ingredients.map((i) => Text('• ${i.amount} ${i.unit} ${i.name}', style: AppTextStyles.body)),
              const SizedBox(height: 16),
              const Text('Instructions:', style: AppTextStyles.heading2),
              ...recipe.instructions.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${e.key + 1}. ${e.value}', style: AppTextStyles.body),
              )),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRecipeDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();

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
              const Text('Create New Recipe', style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'Recipe Name',
                  labelStyle: TextStyle(color: AppColors.beige),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.violet)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredientsController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'Ingredients (one per line)',
                  labelStyle: TextStyle(color: AppColors.beige),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsController,
                maxLines: 5,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'Instructions (one step per line)',
                  labelStyle: TextStyle(color: AppColors.beige),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.violet)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
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

                    ref.read(recipeProvider.notifier).addRecipe(Recipe(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      ingredients: ingredients,
                      instructions: instructions,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Recipe', style: TextStyle(color: AppColors.beige, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
