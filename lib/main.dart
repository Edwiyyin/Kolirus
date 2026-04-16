import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/recipe_screen.dart';
import 'screens/routine_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/receipt_scanner_screen.dart';
import 'screens/addiction_screen.dart';
import 'screens/food_log_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/premium_service.dart';
import 'services/database_service.dart';
import 'providers/navigation_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/health_provider.dart';
import 'providers/water_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/pantry_provider.dart';
import 'widgets/koly_mascot.dart';
import 'models/meal_type.dart';
import 'models/food_item.dart';
import 'models/meal_log.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2A1733),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF808000)),
        ),
      );
    }

    if (!auth.hasCompletedOnboarding) {
      return KolyOnboardingScreen(
        onFinish: () => ref.read(authProvider.notifier).completeOnboarding(),
      );
    }

    return const MainShell();
  }
}

final _devUnlockedProvider = StateProvider<bool>((ref) => false);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  bool _fabOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _logoTapCount = 0;
  DateTime? _firstTapTime;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
      _fabOpen ? _fabController.forward() : _fabController.reverse();
    });
  }

  void _handleLogoTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 5)) {
      _firstTapTime = now;
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    if (_logoTapCount >= 10) {
      _logoTapCount = 0;
      ref.read(_devUnlockedProvider.notifier).state = true;
      ref.read(navigationProvider.notifier).state = 4;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dev mode unlocked!'), backgroundColor: Colors.redAccent));
    }
  }

  String _getScreenTip(int index) {
    const tips = [
      'Home! Tap the ring to see history or log a meal.',
      'Kitchen! I suggest expiry dates based on where you store things.',
      'Cookbook! Import/Export your favorite recipes.',
      'Planner! Check things off as you eat them to stay on track.',
    ];
    return index < tips.length ? tips[index] : 'I am Koly, your companion!';
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final devUnlocked = ref.watch(_devUnlockedProvider);
    final auth = ref.watch(authProvider);
    final premium = ref.watch(premiumProvider);

    final screens = <Widget>[
      const HomeScreen(),
      const PantryScreen(),
      const RecipeScreen(),
      const RoutineScreen(),
      if (devUnlocked) const DevScreen(),
    ];
    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: _handleLogoTap,
            child: Image.asset('assets/logo_github.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.restaurant_menu,
                    color: AppColors.olive,
                    size: 24)),
          ),
        ),
        title: const Text('Kolirus',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          KolyHelpButton(tip: _getScreenTip(currentIndex)), // Koly in the AppBar (top bar)
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined, color: AppColors.olive),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.beige),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, devUnlocked, auth, premium),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                IndexedStack(index: safeIndex, children: screens),
                if (_fabOpen)
                  GestureDetector(
                    onTap: _toggleFab,
                    child: Container(color: Colors.black87),
                  ),
                _buildFabMenu(),
              ],
            ),
          ),
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
          children: [
            _navItem(Icons.home_rounded, 0, currentIndex),
            _navItem(Icons.kitchen_rounded, 1, currentIndex),
            const SizedBox(width: 48), // Space for FAB
            _navItem(Icons.menu_book_rounded, 2, currentIndex),
            _navItem(Icons.calendar_month_rounded, 3, currentIndex),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFab,
        backgroundColor: AppColors.olive,
        shape: const CircleBorder(),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(_fabController),
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDrawer(BuildContext context, bool devUnlocked, AuthState auth, PremiumState premium) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('KOLIRUS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18, color: AppColors.beige)),
            ),
            _drawerItem(context, Icons.bar_chart_rounded, 'Statistics', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
            }),
            _drawerItem(context, Icons.history, 'Meal History', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLogScreen()));
            }),
            _drawerItem(context, Icons.warning_amber_rounded, 'Addiction Tracker', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddictionScreen()));
            }),
            const Divider(color: Colors.white10),
            _drawerItem(context, Icons.track_changes, 'Goals', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
            _drawerItem(context, Icons.settings_outlined, 'Settings & Filters', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            if (devUnlocked) ...[
              const Divider(color: Colors.white10),
              _drawerItem(context, Icons.developer_mode, 'Developer Tools', () {
                Navigator.pop(context);
                ref.read(navigationProvider.notifier).state = 4;
              }, color: Colors.redAccent),
            ],
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Kolirus v1.1.0', style: TextStyle(color: Colors.white24, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color color = AppColors.olive}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: const TextStyle(color: AppColors.beige, fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _navItem(IconData icon, int index, int current) {
    return IconButton(
      icon: Icon(icon, color: index == current ? AppColors.olive : AppColors.textLight),
      onPressed: () => ref.read(navigationProvider.notifier).state = index,
    );
  }

  Widget _buildFabMenu() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circularButton(Icons.qr_code_scanner, 'Scan', () {
              _toggleFab();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
            }),
            const SizedBox(width: 30),
            _circularButton(Icons.receipt_long, 'Receipt', () {
              _toggleFab();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptScannerScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _circularButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: null,
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
}

class DevScreen extends ConsumerStatefulWidget {
  const DevScreen({super.key});

  @override
  ConsumerState<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends ConsumerState<DevScreen> {
  int _pendingNotifCount = 0;
  bool _loadingNotifs = false;

  @override
  void initState() {
    super.initState();
    _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    setState(() => _loadingNotifs = true);
    final pending =
    await NotificationService().getPendingNotifications();
    if (mounted) {
      setState(() {
        _pendingNotifCount = pending.length;
        _loadingNotifs = false;
      });
    }
  }

  void _snack(String msg, {Color color = AppColors.olive}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools',
            style: TextStyle(color: Colors.redAccent)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () =>
            ref.read(navigationProvider.notifier).state = 0,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _devBanner(),
          const SizedBox(height: 16),

          // ── Water ──────────────────────────────────────────────────────
          _section('💧 Water Simulation'),
          _devBtn(
            icon: Icons.water_drop,
            label: 'Add 250ml (1 glass)',
            sub: 'Simulates drinking one glass',
            onTap: () {
              ref.read(waterProvider.notifier).addWater(250);
              _snack('+250ml water added');
            },
          ),
          _devBtn(
            icon: Icons.water,
            label: 'Add 500ml',
            sub: 'Simulates a large drink',
            onTap: () {
              ref.read(waterProvider.notifier).addWater(500);
              _snack('+500ml water added');
            },
          ),
          _devBtn(
            icon: Icons.water_damage_outlined,
            label: 'Fill Daily Water Goal',
            sub: 'Instantly hits today\'s water goal',
            onTap: () async {
              final water = ref.read(waterProvider);
              final remaining = water.goalMl - water.todayMl;
              if (remaining > 0) {
                await ref
                    .read(waterProvider.notifier)
                    .addWater(remaining);
              }
              _snack('Water goal reached!');
            },
          ),

          // ── Meal Logging ───────────────────────────────────────────────
          _section('🍽 Meal Simulation'),
          _devBtn(
            icon: Icons.breakfast_dining,
            label: 'Log Sample Breakfast',
            sub: 'Adds oatmeal 300kcal to today',
            onTap: () async {
              final log = MealLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                foodItemId: 'dev_breakfast',
                foodName: 'Dev Oatmeal',
                quantity: 100,
                consumedAt: DateTime.now(),
                type: MealType.Breakfast,
                calories: 300,
                protein: 10,
                carbs: 55,
                fat: 6,
                fiber: 4,
                sugar: 12,
              );
              await ref.read(foodLogProvider.notifier).addLog(log);
              _snack('Breakfast logged');
            },
          ),
          _devBtn(
            icon: Icons.lunch_dining,
            label: 'Log Sample Lunch',
            sub: 'Adds grilled chicken 450kcal',
            onTap: () async {
              final log = MealLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                foodItemId: 'dev_lunch',
                foodName: 'Dev Grilled Chicken',
                quantity: 200,
                consumedAt: DateTime.now(),
                type: MealType.Lunch,
                calories: 450,
                protein: 50,
                carbs: 10,
                fat: 22,
                sodium: 600,
              );
              await ref.read(foodLogProvider.notifier).addLog(log);
              _snack('Lunch logged');
            },
          ),
          _devBtn(
            icon: Icons.local_fire_department,
            label: 'Hit Calorie Goal',
            sub: 'Logs meals to reach your calorie goal',
            onTap: () async {
              final settings = ref.read(settingsProvider);
              final goal = (settings['calorie_goal'] ?? 2000.0) as double;
              final totals =
              ref.read(foodLogProvider.notifier).getDailyTotals();
              final remaining = goal - (totals['calories'] ?? 0);
              if (remaining <= 0) {
                _snack('Already at goal!');
                return;
              }
              final log = MealLog(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                foodItemId: 'dev_goal_fill',
                foodName: 'Dev Goal Fill',
                quantity: 100,
                consumedAt: DateTime.now(),
                type: MealType.Dinner,
                calories: remaining,
                protein: remaining * 0.2,
                carbs: remaining * 0.5,
                fat: remaining * 0.3 / 9,
              );
              await ref.read(foodLogProvider.notifier).addLog(log);
              _snack('Calorie goal reached!');
            },
          ),

          // ── Pantry ─────────────────────────────────────────────────────
          _section('🥦 Pantry Tools'),
          _devBtn(
            icon: Icons.add_shopping_cart,
            label: 'Add 5 Sample Pantry Items',
            sub: 'Populates kitchen with test items',
            onTap: () async {
              final items = [
                FoodItem(
                  id: 'dev_item_${DateTime.now().millisecondsSinceEpoch}_1',
                  name: 'Dev Olive Oil',
                  calories: 884, protein: 0, carbs: 0, fat: 100,
                  location: StorageLocation.shelf,
                  expiryDate:
                  DateTime.now().add(const Duration(days: 180)),
                ),
                FoodItem(
                  id: 'dev_item_${DateTime.now().millisecondsSinceEpoch}_2',
                  name: 'Dev Greek Yogurt',
                  calories: 59, protein: 10, carbs: 3.6, fat: 0.4,
                  location: StorageLocation.fridge,
                  expiryDate:
                  DateTime.now().add(const Duration(days: 7)),
                ),
                FoodItem(
                  id: 'dev_item_${DateTime.now().millisecondsSinceEpoch}_3',
                  name: 'Dev Salmon Fillet',
                  calories: 208, protein: 20, carbs: 0, fat: 13,
                  location: StorageLocation.freezer,
                  expiryDate:
                  DateTime.now().add(const Duration(days: 90)),
                ),
                FoodItem(
                  id: 'dev_item_${DateTime.now().millisecondsSinceEpoch}_4',
                  name: 'Dev Chickpeas',
                  calories: 364, protein: 19, carbs: 61, fat: 6,
                  location: StorageLocation.shelf,
                  expiryDate:
                  DateTime.now().add(const Duration(days: 365)),
                ),
                FoodItem(
                  id: 'dev_item_${DateTime.now().millisecondsSinceEpoch}_5',
                  name: 'Dev Spinach',
                  calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4,
                  location: StorageLocation.fridge,
                  expiryDate:
                  DateTime.now().add(const Duration(days: 3)),
                ),
              ];
              for (final item in items) {
                await ref.read(pantryProvider.notifier).addItem(item);
              }
              _snack('5 items added to kitchen');
            },
          ),
          _devBtn(
            icon: Icons.warning_amber_rounded,
            label: 'Add Expiring Item (2 days)',
            sub: 'Tests expiry notification system',
            onTap: () async {
              final item = FoodItem(
                id: 'dev_expiring_${DateTime.now().millisecondsSinceEpoch}',
                name: 'Dev Expiring Milk',
                calories: 61, protein: 3.2, carbs: 4.8, fat: 3.3,
                location: StorageLocation.fridge,
                expiryDate:
                DateTime.now().add(const Duration(days: 2)),
              );
              await ref.read(pantryProvider.notifier).addItem(item);
              _snack('Expiring item added (2 days)');
            },
          ),
          _devBtn(
            icon: Icons.delete_sweep,
            label: 'Clear All Pantry Items',
            sub: 'Wipes entire pantry (irreversible)',
            color: Colors.redAccent,
            onTap: () async {
              final confirmed = await _confirm(
                  'Clear pantry?',
                  'This will delete all pantry items permanently.');
              if (confirmed) {
                final db = await DatabaseService.instance.database;
                await db.delete('food_items');
                await ref.read(pantryProvider.notifier).loadItems();
                _snack('Pantry cleared', color: Colors.redAccent);
              }
            },
          ),

          // ── Notifications ──────────────────────────────────────────────
          _section('🔔 Notifications'),
          _devBtn(
            icon: Icons.notifications_active,
            label: 'Send Instant Test Notification',
            sub: 'Fires immediately to verify system works',
            onTap: () async {
              await NotificationService().showTestNotification();
              _snack('Test notification sent');
            },
          ),
          _devBtn(
            icon: Icons.timer,
            label: 'Schedule Notification (5s)',
            sub: 'Fires 5 seconds from now',
            onTap: () async {
              await NotificationService()
                  .scheduleTestExpiryIn5Seconds();
              _snack('Notification scheduled for 5s');
            },
          ),
          _devBtn(
            icon: Icons.pending_actions,
            label: _loadingNotifs
                ? 'Loading...'
                : 'Pending: $_pendingNotifCount notification(s)',
            sub: 'Tap to refresh count',
            onTap: _refreshPendingCount,
          ),
          _devBtn(
            icon: Icons.notifications_off,
            label: 'Cancel All Notifications',
            sub: 'Clears all scheduled notifications',
            color: Colors.orangeAccent,
            onTap: () async {
              await NotificationService().cancelAll();
              await _refreshPendingCount();
              _snack('All notifications cancelled',
                  color: Colors.orangeAccent);
            },
          ),

          // ── Health ─────────────────────────────────────────────────────
          _section('🏃 Health Data'),
          _devBtn(
            icon: Icons.monitor_weight,
            label: 'Set Test Weight (70 kg)',
            sub: 'Logs a weight entry for today',
            onTap: () async {
              await ref
                  .read(healthProvider.notifier)
                  .updateManualEntry(weight: 70.0, height: 175.0);
              _snack('Weight set to 70kg, height 175cm');
            },
          ),
          _devBtn(
            icon: Icons.fitness_center,
            label: 'Simulate Week of Weight Data',
            sub: 'Adds 7 days of declining weight',
            onTap: () async {
              final now = DateTime.now();
              for (int i = 7; i >= 0; i--) {
                final date =
                now.subtract(Duration(days: i));
                await ref
                    .read(healthProvider.notifier)
                    .updateManualEntry(
                    weight: 75.0 - (i * 0.3),
                    height: 175.0,
                    date: date);
              }
              _snack('7 days of weight data added');
            },
          ),

          // ── App State ──────────────────────────────────────────────────
          _section('⚙️ App State'),
          _devBtn(
            icon: Icons.restart_alt,
            label: 'Reset Onboarding',
            sub: 'Shows onboarding again on next restart',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('koly_onboarded', false);
              _snack('Onboarding reset. Restart the app.');
            },
          ),
          _devBtn(
            icon: Icons.star,
            label: 'Toggle Premium Status',
            sub: 'Switches premium on/off',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final current =
                  prefs.getBool('kolirus_premium') ?? false;
              await prefs.setBool('kolirus_premium', !current);
              _snack('Premium: ${!current}');
            },
          ),
          _devBtn(
            icon: Icons.settings_backup_restore,
            label: 'Reset All Goals to Default',
            sub: 'Restores calorie, water, protein goals',
            onTap: () async {
              final n = ref.read(settingsProvider.notifier);
              await n.updateNutrientGoal('calorie_goal', 2000);
              await n.updateNutrientGoal('protein_goal', 150);
              await n.updateNutrientGoal('carbs_goal', 250);
              await n.updateNutrientGoal('fat_goal', 70);
              await n.updateNutrientGoal('fiber_goal', 30);
              await n.updateNutrientGoal('water_goal', 2000);
              _snack('Goals reset to defaults');
            },
          ),

          // ── Danger Zone ────────────────────────────────────────────────
          _section('🗑 Danger Zone', color: Colors.redAccent),
          _devBtn(
            icon: Icons.delete_forever,
            label: 'Clear All Meal Logs (Today)',
            sub: 'Deletes all of today\'s meal logs',
            color: Colors.redAccent,
            onTap: () async {
              final confirmed = await _confirm(
                  'Clear today\'s logs?',
                  'All meal logs for today will be permanently deleted.');
              if (confirmed) {
                final db = await DatabaseService.instance.database;
                final now = DateTime.now();
                final start =
                DateTime(now.year, now.month, now.day).toIso8601String();
                final end = DateTime(now.year, now.month, now.day, 23, 59, 59)
                    .toIso8601String();
                await db.delete('meal_logs',
                    where: 'consumedAt BETWEEN ? AND ?',
                    whereArgs: [start, end]);
                await ref.read(foodLogProvider.notifier).loadLogs(now);
                _snack('Today\'s logs cleared', color: Colors.redAccent);
              }
            },
          ),
          _devBtn(
            icon: Icons.delete_forever,
            label: 'Wipe ALL Meal Logs',
            sub: 'Deletes entire meal history forever',
            color: Colors.redAccent,
            onTap: () async {
              final confirmed = await _confirm(
                  'Wipe all logs?',
                  'This will permanently delete ALL meal history. This cannot be undone!');
              if (confirmed) {
                final db = await DatabaseService.instance.database;
                await db.delete('meal_logs');
                await ref.read(foodLogProvider.notifier).loadLogs(DateTime.now());
                _snack('All meal logs wiped', color: Colors.redAccent);
              }
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _devBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.developer_mode,
              color: Colors.redAccent, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Developer mode — for testing only. Changes affect real data.',
              style: TextStyle(
                  color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {Color color = AppColors.olive}) =>
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5),
        ),
      );

  Widget _devBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? sub,
    Color color = AppColors.olive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        subtitle: sub != null
            ? Text(sub,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11))
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ??
        false;
  }
}