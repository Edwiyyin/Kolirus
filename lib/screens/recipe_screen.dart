import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import '../services/database_service.dart';
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

  Future<void> deleteRecipe(String id) async {
    final db = await _db.database;
    await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
    await loadRecipes();
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
      final matchesSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: AppColors.olive),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedCategory = cat),
                          selectedColor: AppColors.olive,
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
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
                ? const Center(child: Text('No recipes found', style: TextStyle(color: Colors.white38)))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        onEdit: () => _showRecipeEditor(context, ref, recipe: recipe),
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

  void _showRecipeEditor(BuildContext context, WidgetRef ref, {Recipe? recipe}) {
    final isEditing = recipe != null;
    final nameController = TextEditingController(text: recipe?.name ?? '');
    final servingsController = TextEditingController(text: recipe?.servings.toString() ?? '1');
    final prepController = TextEditingController(text: recipe?.prepTime.toString() ?? '0');
    final cookController = TextEditingController(text: recipe?.cookTime.toString() ?? '0');
    final ingredientsController = TextEditingController(
      text: recipe?.ingredients.map((i) => '${i.amount} ${i.unit} ${i.name}').join('\n') ?? ''
    );
    final instructionsController = TextEditingController(
      text: recipe?.instructions.join('\n') ?? ''
    );
    String selectedCat = recipe?.category ?? 'Lunch';

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
              Text(isEditing ? 'Edit Recipe' : 'New Recipe', style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppColors.olive)),
              ),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: servingsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Servings', labelStyle: TextStyle(color: AppColors.olive)),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<String>(
                    value: selectedCat,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppColors.olive)),
                    items: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => selectedCat = val!,
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: prepController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Prep (min)', labelStyle: TextStyle(color: AppColors.olive)),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: cookController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Cook (min)', labelStyle: TextStyle(color: AppColors.olive)),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredientsController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ingredients (e.g. 200 g Flour)',
                  labelStyle: TextStyle(color: AppColors.olive),
                  hintText: 'One per line',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final ings = ingredientsController.text.split('\n').where((s) => s.trim().isNotEmpty).map((s) {
                      final parts = s.split(' ');
                      if (parts.length >= 3) {
                        return RecipeIngredient(amount: parts[0], unit: parts[1], name: parts.sublist(2).join(' '));
                      }
                      return RecipeIngredient(amount: '', unit: '', name: s);
                    }).toList();
                    
                    final insts = instructionsController.text.split('\n').where((s) => s.trim().isNotEmpty).toList();

                    final newRecipe = Recipe(
                      id: isEditing ? recipe.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      category: selectedCat,
                      servings: int.tryParse(servingsController.text) ?? 1,
                      prepTime: int.tryParse(prepController.text) ?? 0,
                      cookTime: int.tryParse(cookController.text) ?? 0,
                      ingredients: ings,
                      instructions: insts,
                      imageUrl: recipe?.imageUrl,
                    );

                    if (isEditing) {
                      ref.read(recipeProvider.notifier).updateRecipe(newRecipe);
                    } else {
                      ref.read(recipeProvider.notifier).addRecipe(newRecipe);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: recipe.imageUrl != null
                    ? Image.network(recipe.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                    : Container(color: AppColors.olive.withOpacity(0.1), child: const Center(child: Icon(Icons.restaurant, color: AppColors.olive, size: 40))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.olive),
                      const SizedBox(width: 4),
                      Text('${recipe.prepTime + recipe.cookTime} min', style: AppTextStyles.caption),
                      const Spacer(),
                      Text(recipe.category, style: TextStyle(color: AppColors.olive.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, WidgetRef ref, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
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
                      image: recipe.imageUrl != null ? DecorationImage(image: NetworkImage(recipe.imageUrl!), fit: BoxFit.cover) : null,
                    ),
                    child: recipe.imageUrl == null ? const Icon(Icons.restaurant, size: 80, color: AppColors.olive) : null,
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
                        Expanded(child: Text(recipe.name, style: AppTextStyles.heading1)),
                        IconButton(icon: const Icon(Icons.edit, color: AppColors.olive), onPressed: () {
                          Navigator.pop(context);
                          onEdit();
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(recipe.category.toUpperCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoItem(Icons.people_outline, '${recipe.servings} servings'),
                        _infoItem(Icons.timer_outlined, '${recipe.prepTime}m prep'),
                        _infoItem(Icons.outdoor_grill_outlined, '${recipe.cookTime}m cook'),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 40),
                    const Text('Ingredients', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    ...recipe.ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: AppColors.olive),
                          const SizedBox(width: 12),
                          Text('${ing.amount} ${ing.unit}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ing.name, style: const TextStyle(color: Colors.white70))),
                        ],
                      ),
                    )),
                    const Divider(color: Colors.white10, height: 40),
                    const Text('Instructions', style: AppTextStyles.heading2),
                    const SizedBox(height: 12),
                    ...recipe.instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 12, backgroundColor: AppColors.olive, child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 16),
                          Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.white, height: 1.5))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        ref.read(recipeProvider.notifier).deleteRecipe(recipe.id!);
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
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
