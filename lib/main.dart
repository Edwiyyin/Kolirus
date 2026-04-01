import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/food_log_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/routine_screen.dart';
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
          primary: AppColors.olive,
          secondary: AppColors.olive,
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    final List<Widget> _screens = [
      const HomeScreen(),
      const RoutineScreen(),
      const RecipeScreen(),
      const StatsScreen(),
      const PantryScreen(), // Hidden from direct tab access but available in stack
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.restaurant_menu, color: AppColors.olive),
          ),
        ),
        title: const Text('Kolirus', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.beige),
            onPressed: () {
              // Settings logic here
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),
          if (_isOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.black87),
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
            _navItem(Icons.calendar_month_rounded, 1, currentIndex),
            const SizedBox(width: 48), // Space for FAB
            _navItem(Icons.menu_book_rounded, 2, currentIndex),
            _navItem(Icons.bar_chart_rounded, 3, currentIndex),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        backgroundColor: AppColors.olive,
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
      icon: Icon(icon, color: index == current ? AppColors.olive : AppColors.textLight),
      onPressed: () {
        if (_isOpen) _toggleMenu();
        ref.read(navigationProvider.notifier).state = index;
      },
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
            _circularButton(Icons.kitchen_rounded, "Kitchen", () {
              _toggleMenu();
              ref.read(navigationProvider.notifier).state = 4; // Navigate to Pantry (Kitchen)
            }),
            const SizedBox(width: 20),
            _circularButton(Icons.add_box_outlined, "Add", () {
              _toggleMenu();
              _showManualPantryDialog(context, ref);
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
          child: Icon(icon, color: Colors.black),
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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('add to kitchen', style: AppTextStyles.heading1),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.beige),
                decoration: const InputDecoration(
                  labelText: 'food name',
                  labelStyle: TextStyle(color: AppColors.olive),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.olive)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: calController,
                    decoration: const InputDecoration(labelText: 'calories', labelStyle: TextStyle(color: AppColors.olive)),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: proteinController,
                    decoration: const InputDecoration(labelText: 'protein', labelStyle: TextStyle(color: AppColors.olive)),
                    keyboardType: TextInputType.number,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StorageLocation>(
                value: selectedLocation,
                dropdownColor: AppColors.card,
                items: StorageLocation.values.map((loc) => DropdownMenuItem(
                  value: loc, child: Text(loc.name.toUpperCase(), style: const TextStyle(color: AppColors.beige)),
                )).toList(),
                onChanged: (val) => selectedLocation = val!,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.olive, minimumSize: const Size(double.infinity, 50)),
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
                child: const Text('save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
