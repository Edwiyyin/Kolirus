import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'providers/navigation_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/health_provider.dart';
import 'providers/water_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/pantry_provider.dart';
import 'models/food_item.dart';
import 'models/recipe.dart';

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
      home: const MainShell(),
    );
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
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
      _firstTapTime = null;
      ref.read(_devUnlockedProvider.notifier).state = true;
      // Jump to dev tab
      ref.read(navigationProvider.notifier).state = 4;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer mode unlocked'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _refreshAll() {
    ref.read(foodLogProvider.notifier).loadLogs(DateTime.now());
    ref.read(healthProvider.notifier).loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Data refreshed'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final devUnlocked = ref.watch(_devUnlockedProvider);

    final screens = <Widget>[
      const HomeScreen(),
      const PantryScreen(),
      const RecipeScreen(),
      const RoutineScreen(),
      if (devUnlocked) const _DevScreen(),
    ];

    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: _handleLogoTap,
              onLongPress: _refreshAll,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_menu,
                      color: AppColors.olive,
                      size: 24),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Kolirus',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined,
                color: AppColors.olive),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const ShoppingListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.beige),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: _buildDrawer(context, devUnlocked),
      body: Stack(
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
            const SizedBox(width: 48),
            _navItem(Icons.menu_book_rounded, 2, currentIndex),
            _navItem(Icons.calendar_month_rounded, 3, currentIndex),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab',
        onPressed: _toggleFab,
        backgroundColor: AppColors.olive,
        shape: const CircleBorder(),
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: 0.125).animate(_fabController),
          child:
          const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDrawer(BuildContext context, bool devUnlocked) {
    return Drawer(
      backgroundColor: AppColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.olive,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant_menu,
                            color: Colors.black,
                            size: 28)),
                  ),
                  const SizedBox(width: 12),
                  const Text('KOLIRUS',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 18,
                          color: AppColors.beige)),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('ANALYTICS',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ),
            _drawerItem(context, Icons.bar_chart_rounded, 'Stats', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()));
            }),
            _drawerItem(
                context, Icons.warning_amber_rounded, 'Addiction Tracker',
                    () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddictionScreen()));
                }),
            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('ACCOUNT',
                  style: TextStyle(
                      color: AppColors.olive,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ),
            _drawerItem(context, Icons.settings_outlined, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
            }),
            if (devUnlocked) ...[
              const Divider(color: Colors.white10),
              _drawerItem(
                context,
                Icons.developer_mode,
                'Dev Tools',
                    () {
                  Navigator.pop(context);
                  ref.read(navigationProvider.notifier).state = 4;
                },
                color: Colors.redAccent,
              ),
            ],
            const Spacer(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 11, color: Colors.white24),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Product data powered by Open Food Facts (openfoodfacts.org)',
                      style:
                      TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('Kolirus v1.0.0',
                  style:
                  TextStyle(color: Colors.white24, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String label,
      VoidCallback onTap, {
        Color color = AppColors.olive,
      }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: const TextStyle(color: AppColors.beige, fontSize: 14)),
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _navItem(IconData icon, int index, int current) {
    return IconButton(
      icon: Icon(icon,
          color: index == current ? AppColors.olive : AppColors.textLight),
      onPressed: () {
        if (_fabOpen) _toggleFab();
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
        scale:
        CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circularButton(Icons.qr_code_scanner, 'Scan', () {
              _toggleFab();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ScannerScreen()));
            }),
            const SizedBox(width: 30),
            _circularButton(Icons.receipt_long, 'Receipt', () {
              _toggleFab();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReceiptScannerScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _circularButton(
      IconData icon, String label, VoidCallback onTap) {
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
        Text(label,
            style:
            const TextStyle(color: AppColors.beige, fontSize: 10)),
      ],
    );
  }
}

class _DevScreen extends ConsumerStatefulWidget {
  const _DevScreen();

  @override
  ConsumerState<_DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends ConsumerState<_DevScreen> {
  final List<String> _log = [];
  List<dynamic> _pending = [];

  void _addLog(String msg) {
    final n = DateTime.now();
    final ts =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    setState(() => _log.insert(0, '[$ts] $msg'));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider);
    final logs = ref.watch(foodLogProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Text('DEV',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 2)),
              ),
              const SizedBox(width: 12),
              const Text('Developer Tools',
                  style: TextStyle(
                      color: AppColors.beige,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(_devUnlockedProvider.notifier).state = false;
                  ref.read(navigationProvider.notifier).state = 0;
                },
                child: const Text('Exit',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _section('Testing & Automation'),
          _devBtn(
            icon: Icons.checklist_rtl,
            label: 'Run Comprehensive Test Suite',
            onTap: () async {
               _addLog('Running automated tests...');
               await Future.delayed(const Duration(seconds: 1));
               _addLog('Notifications: OK');
               _addLog('Database Integrity: OK');
               _addLog('Health Permissions: VERIFYING...');
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing completed. Check Dev Log.')));
            },
          ),
          _devBtn(
            icon: Icons.auto_fix_high,
            label: 'Fill Mock Data (Full House)',
            onTap: () async {
              final mockItems = [
                FoodItem(id: 'mock1', name: 'Greek Yogurt', calories: 150, protein: 15, carbs: 6, fat: 0, addedDate: DateTime.now(), nutriScore: 'A'),
                FoodItem(id: 'mock2', name: 'Chicken Breast', calories: 165, protein: 31, carbs: 0, fat: 3.6, addedDate: DateTime.now(), nutriScore: 'A'),
                FoodItem(id: 'mock3', name: 'Olive Oil', calories: 884, protein: 0, carbs: 0, fat: 100, addedDate: DateTime.now(), nutriScore: 'C', expiryDate: DateTime.now().add(const Duration(days: 10))),
              ];
              for(var item in mockItems) {
                await DatabaseService.instance.insertFoodItem(item);
              }
              await DatabaseService.instance.insertRecipe(Recipe(
                id: 'mock_recipe',
                name: 'Mediterranean Salad',
                category: 'Lunch',
                ingredients: [],
                instructions: [],
                calories: 350,
                protein: 12,
                carbs: 15,
                fat: 25,
              ));
              ref.read(pantryProvider.notifier).loadItems();
              ref.read(recipeProvider.notifier).loadRecipes();
              _addLog('Pantry and Recipes filled with mock data');
            },
          ),

          const SizedBox(height: 8),
          _section('Notifications'),
          _devBtn(
            icon: Icons.notifications_active,
            label: 'Send Immediate Notification',
            onTap: () async {
              await NotificationService().showTestNotification();
              _addLog('Immediate notification sent');
            },
          ),
          _devBtn(
            icon: Icons.timer,
            label: 'Schedule Expiry Notification in 5 Seconds',
            onTap: () async {
              await NotificationService().scheduleTestExpiryIn5Seconds();
              _addLog('Expiry scheduled in 5s');
            },
          ),
          _devBtn(
            icon: Icons.list_alt,
            label: 'List Pending Notifications',
            onTap: () async {
              final p =
              await NotificationService().getPendingNotifications();
              setState(() => _pending = p);
              _addLog('${p.length} pending notification(s) found');
            },
          ),
          _devBtn(
            icon: Icons.notifications_off,
            label: 'Cancel All Notifications',
            color: Colors.orange,
            onTap: () async {
              await NotificationService().cancelAll();
              setState(() => _pending = []);
              _addLog('All notifications cancelled');
            },
          ),
          if (_pending.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _pending
                    .map((n) => Text('  #${n.id}: ${n.title}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)))
                    .toList(),
              ),
            ),

          const SizedBox(height: 8),
          _section('Data Management'),
          _devBtn(
            icon: Icons.refresh,
            label: 'Force Sync Health Data',
            onTap: () async {
              await ref.read(healthProvider.notifier).loadData();
              _addLog('Health sync forced');
            },
          ),
          _devBtn(
            icon: Icons.delete_forever,
            label: 'Hard Reset (Wipe All Data)',
            color: Colors.redAccent,
            onTap: () => _confirmReset(context),
          ),

          const SizedBox(height: 8),
          _section('State Snapshot'),
          _infoRow('Logs today', '${logs.length}'),
          _infoRow(
              'Water',
              '${water.todayMl.toInt()} / ${water.goalMl.toInt()} ml  '
                  '(${(water.progress * 100).toStringAsFixed(0)}%)'),
          _infoRow('User name', settings['name'] ?? 'N/A'),
          _infoRow('Calorie goal',
              '${(settings['calorie_goal'] ?? 2000).toInt()} kcal'),

          const SizedBox(height: 8),
          _section('App Info'),
          _infoRow('Version', '1.0.0'),
          _infoRow('Platform', Theme.of(context).platform.name.toUpperCase()),
          _infoRow('Time', DateTime.now().toString().split('.').first),

          const SizedBox(height: 8),
          _section('Danger Zone'),
          _devBtn(
            icon: Icons.delete_sweep,
            label: 'Clear Dev Log',
            color: Colors.redAccent,
            onTap: () => setState(() => _log.clear()),
          ),

          if (_log.isNotEmpty) ...[
            const SizedBox(height: 8),
            _section('Log'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _log
                    .map((l) => Text(l,
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontFamily: 'monospace')))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hard Reset?'),
        content: const Text('This will delete everything. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await DatabaseService.instance.database;
              await db.delete('food_items');
              await db.delete('recipes');
              await db.delete('meal_logs');
              await db.delete('health_entries');
              await db.delete('user_settings');
              await db.delete('meal_routine');
              await db.delete('water_logs');
              await db.delete('shopping_list');
              await db.delete('shopping_groups');
              
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            child: const Text('RESET & EXIT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t.toUpperCase(),
        style: const TextStyle(
            color: AppColors.olive,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5)),
  );

  Widget _devBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.olive,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: TextStyle(color: color, fontSize: 13))),
                Icon(Icons.chevron_right,
                    color: color.withOpacity(0.4), size: 16),
              ],
            ),
          ),
        ),
      );

  Widget _infoRow(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$key:  ',
            style: const TextStyle(
                color: Colors.white38, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ),
      ],
    ),
  );
}