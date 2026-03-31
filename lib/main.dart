import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/food_log_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/recipe_screen.dart';
import 'services/notification_service.dart';
import 'providers/navigation_provider.dart';
import 'models/food_item.dart';
import 'providers/pantry_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: KolirusApp()));
}

class KolirusApp extends StatelessWidget {
  const KolirusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kolirus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.card,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.primary,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final List<Widget> _screens = [
      const HomeScreen(),
      const PantryScreen(),
      Container(), // Placeholder for central FAB
      const RecipeScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context, ref),
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        color: AppColors.primary,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home_rounded, 
                color: currentIndex == 0 ? AppColors.accent : AppColors.textLight),
              onPressed: () => ref.read(navigationProvider.notifier).state = 0,
            ),
            IconButton(
              icon: Icon(Icons.kitchen_rounded, 
                color: currentIndex == 1 ? AppColors.accent : AppColors.textLight),
              onPressed: () => ref.read(navigationProvider.notifier).state = 1,
            ),
            const SizedBox(width: 48), // Space for FAB
            IconButton(
              icon: Icon(Icons.menu_book_rounded, 
                color: currentIndex == 3 ? AppColors.accent : AppColors.textLight),
              onPressed: () => ref.read(navigationProvider.notifier).state = 3,
            ),
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, 
                color: currentIndex == 4 ? AppColors.accent : AppColors.textLight),
              onPressed: () => ref.read(navigationProvider.notifier).state = 4,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.accent),
              title: const Text('Scan Food Barcode'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined, color: AppColors.accent),
              title: const Text('Add Pantry Manually'),
              onTap: () {
                Navigator.pop(context);
                _showManualPantryDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu, color: AppColors.accent),
              title: const Text('Log a Meal'),
              onTap: () {
                Navigator.pop(context);
                ref.read(navigationProvider.notifier).state = 3; // Switch to Log (Recipes for now or add log tab)
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showManualPantryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    StorageLocation selectedLocation = StorageLocation.shelf;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Manual Pantry Entry', style: AppTextStyles.heading1),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Food Name', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(
                      controller: calController,
                      decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StorageLocation>(
                  value: selectedLocation,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                  items: StorageLocation.values.map((loc) => DropdownMenuItem(
                    value: loc, child: Text(loc.name.toUpperCase()),
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedLocation = val!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final item = FoodItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        calories: double.tryParse(calController.text) ?? 0,
                        protein: double.tryParse(proteinController.text) ?? 0,
                        location: selectedLocation,
                      );
                      ref.read(pantryProvider.notifier).addItem(item);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add to Pantry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
