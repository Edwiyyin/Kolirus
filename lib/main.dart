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
      title: 'kolirus',
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
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) _controller.forward();
      else _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    final List<Widget> _screens = [
      const HomeScreen(),
      const PantryScreen(),
      const FoodLogScreen(),
      const RecipeScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),
          if (_isOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black54),
            ),
          _buildFabMenu(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        color: AppColors.primary,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _navItem(Icons.home_rounded, 0, currentIndex),
            _navItem(Icons.kitchen_rounded, 1, currentIndex),
            const SizedBox(width: 48),
            _navItem(Icons.menu_book_rounded, 3, currentIndex),
            _navItem(Icons.bar_chart_rounded, 4, currentIndex),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(_controller),
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navItem(IconData icon, int index, int current) {
    return IconButton(
      icon: Icon(icon, color: index == current ? AppColors.accent : AppColors.textLight),
      onPressed: () => ref.read(navigationProvider.notifier).state = index,
    );
  }

  Widget _buildFabMenu() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circularButton(Icons.qr_code_scanner, "Scan", () {
              _toggleMenu();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
            }),
            const SizedBox(width: 20),
            _circularButton(Icons.add_box_outlined, "Pantry", () {
              _toggleMenu();
              _showManualPantryDialog(context, ref);
            }),
            const SizedBox(width: 20),
            _circularButton(Icons.restaurant_menu, "Log", () {
              _toggleMenu();
              ref.read(navigationProvider.notifier).state = 2;
            }),
          ],
        ),
      ),
    );
  }

  Widget _circularButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: AppColors.olive,
          mini: true,
          child: Icon(icon, color: AppColors.beige),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.beige, fontSize: 10)),
      ],
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
                const Text('Add to Pantry', style: AppTextStyles.heading1),
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
                      decoration: const InputDecoration(labelText: 'Calories', border: OutlineInputBorder()),
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
                  child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
