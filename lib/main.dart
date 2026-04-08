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
import 'models/meal_log.dart';
import 'models/meal_type.dart';

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
          content: Text('Data refreshed'), duration: Duration(seconds: 1)),
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
                  'assets/logo_github.png',
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
            style:
            TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
          child: const Icon(Icons.add, color: Colors.black, size: 30),
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/logo_github.png',
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
                      color: AppColors.olive,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ),
            _drawerItem(context, Icons.bar_chart_rounded, 'Stats', () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()));
            }),
            _drawerItem(context, Icons.warning_amber_rounded,
                'Addiction Tracker', () {
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
              _drawerItem(context, Icons.developer_mode, 'Dev Tools', () {
                Navigator.pop(context);
                ref.read(navigationProvider.notifier).state = 4;
              }, color: Colors.redAccent),
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
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()));
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
            style: const TextStyle(color: AppColors.beige, fontSize: 10)),
      ],
    );
  }
}

// ─── Dev Screen ───────────────────────────────────────────────────────────────

class _DevScreen extends ConsumerStatefulWidget {
  const _DevScreen();

  @override
  ConsumerState<_DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends ConsumerState<_DevScreen> {
  final List<String> _log = [];
  List<dynamic> _pending = [];

  final _foodNameCtrl = TextEditingController(text: 'Test Apple');
  int _daysUntilExpiry = 3;

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    super.dispose();
  }

  void _addLog(String msg) {
    final n = DateTime.now();
    final ts =
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
    setState(() => _log.insert(0, '[$ts] $msg'));
  }

  // ── Filter test: build a fake FoodItem and open the real scanner dialog ────

  void _runFilterTest({
    required BuildContext context,
    required String productName,
    required String ingredients,
    required List<String> allergens,
    required String? nutriScore,
  }) {
    final fakeProduct = FoodItem(
      id: 'dev_filter_test',
      name: productName,
      barcode: '0000000000000',
      brand: 'Dev Test Brand',
      nutriScore: nutriScore,
      ingredientsText: ingredients,
      allergens: allergens,
      calories: 200,
      protein: 5,
      carbs: 30,
      fat: 8,
    );

    // Open the scanner screen's product dialog directly
    // We do this by navigating to ScannerScreen with the fake product pre-loaded
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DevFilterPreviewScreen(product: fakeProduct),
      ),
    );
    _addLog('Opened filter preview for "$productName"');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final water = ref.watch(waterProvider);
    final logs = ref.watch(foodLogProvider);
    final pantry = ref.watch(pantryProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    style:
                    TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Notifications ─────────────────────────────────────────────
          _section('Notifications'),
          _devBtn(
            icon: Icons.notifications_active,
            label: 'Send Immediate Notification',
            onTap: () async {
              await NotificationService().showTestNotification();
              _addLog('Immediate notification sent');
            },
          ),

          // Expiry food tester
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.olive.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border:
              Border.all(color: AppColors.olive.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Test Expiry Notifications',
                    style: TextStyle(
                        color: AppColors.olive,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _foodNameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Food name',
                    labelStyle: TextStyle(color: Colors.white54),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Expires in:',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _daysUntilExpiry.toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        activeColor: AppColors.olive,
                        label: '$_daysUntilExpiry days',
                        onChanged: (v) =>
                            setState(() => _daysUntilExpiry = v.toInt()),
                      ),
                    ),
                    Text('$_daysUntilExpiry d',
                        style: const TextStyle(
                            color: AppColors.olive, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.olive),
                    icon: const Icon(Icons.add_alert,
                        color: Colors.black, size: 16),
                    label: Text(
                      'Add to Pantry + Schedule ${_daysUntilExpiry} daily notifications',
                      style: const TextStyle(
                          color: Colors.black, fontSize: 12),
                    ),
                    onPressed: () async {
                      final expiry = DateTime.now()
                          .add(Duration(days: _daysUntilExpiry));
                      final item = FoodItem(
                        id: DateTime.now()
                            .millisecondsSinceEpoch
                            .toString(),
                        name: _foodNameCtrl.text.isNotEmpty
                            ? _foodNameCtrl.text
                            : 'Test Food',
                        calories: 50,
                        protein: 1,
                        carbs: 10,
                        fat: 0.5,
                        expiryDate: expiry,
                        addedDate: DateTime.now(),
                      );
                      await ref
                          .read(pantryProvider.notifier)
                          .addItem(item);
                      _addLog(
                          'Added "${item.name}" expiring in $_daysUntilExpiry days. '
                              '$_daysUntilExpiry daily notifications scheduled at 9AM. '
                              'Background the app — they will still fire.');
                    },
                  ),
                ),
              ],
            ),
          ),

          _devBtn(
            icon: Icons.timer,
            label: 'Schedule Test Notification in 5 Seconds',
            subtitle: 'Background the app immediately after tapping',
            onTap: () async {
              await NotificationService().scheduleTestExpiryIn5Seconds();
              _addLog(
                  'Notification scheduled for 5s — background the app now!');
            },
          ),
          _devBtn(
            icon: Icons.list_alt,
            label: 'List Pending Notifications',
            onTap: () async {
              final p =
              await NotificationService().getPendingNotifications();
              setState(() => _pending = p);
              _addLog('${p.length} pending notification(s)');
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

          // ── Filter Tests ──────────────────────────────────────────────
          const SizedBox(height: 8),
          _section('Filter Tests — Scan Preview'),
          const Text(
            'Tap a preset to open the scanner product dialog with that product. '
                'Your active filters (set in Settings) will be checked and warnings shown exactly as during a real scan.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Presets that trigger the real scanner dialog
          ...[
            {
              'label': 'Pork Sausage (Halal/Vegan test)',
              'name': 'Pork Sausage',
              'ingredients': 'pork, lard, salt, pepper, spices, casing',
              'allergens': <String>[],
              'score': 'D',
              'color': Colors.redAccent,
            },
            {
              'label': 'Whole Milk (Vegan/Milk allergy)',
              'name': 'Whole Milk 1L',
              'ingredients': 'whole milk, vitamin D',
              'allergens': <String>['milk'],
              'score': 'B',
              'color': Colors.orange,
            },
            {
              'label': 'Bread (Gluten/Keto test)',
              'name': 'White Bread',
              'ingredients': 'wheat flour, water, yeast, salt, sugar, glucose syrup',
              'allergens': <String>['gluten', 'wheat'],
              'score': 'C',
              'color': Colors.orange,
            },
            {
              'label': 'Salmon Fillet (Fish allergy test)',
              'name': 'Atlantic Salmon Fillet',
              'ingredients': 'salmon, salt',
              'allergens': <String>['fish'],
              'score': 'A',
              'color': AppColors.olive,
            },
            {
              'label': 'Peanut Butter (Nut/Peanut allergy)',
              'name': 'Smooth Peanut Butter',
              'ingredients': 'peanuts, palm oil, sugar, salt',
              'allergens': <String>['peanuts', 'nuts'],
              'score': 'C',
              'color': Colors.orange,
            },
            {
              'label': 'Beer (Halal/Alcohol test)',
              'name': 'Lager Beer 33cl',
              'ingredients': 'water, barley malt, hops, alcohol',
              'allergens': <String>['gluten'],
              'score': 'D',
              'color': Colors.redAccent,
            },
            {
              'label': 'Clean product (no violations)',
              'name': 'Sparkling Water',
              'ingredients': 'carbonated water, natural minerals',
              'allergens': <String>[],
              'score': 'A',
              'color': AppColors.olive,
            },
          ].map((preset) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _runFilterTest(
                  context: context,
                  productName: preset['name'] as String,
                  ingredients: preset['ingredients'] as String,
                  allergens:
                  List<String>.from(preset['allergens'] as List),
                  nutriScore: preset['score'] as String?,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                    (preset['color'] as Color).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: (preset['color'] as Color)
                            .withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner,
                          color: preset['color'] as Color, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(preset['label'] as String,
                                style: TextStyle(
                                    color: preset['color'] as Color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              'Ingredients: ${preset['ingredients']}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: (preset['color'] as Color)
                              .withOpacity(0.5),
                          size: 16),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── Streak Tests ──────────────────────────────────────────────
          const SizedBox(height: 8),
          _section('Streak Tests'),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Text(
              'Healthy streak: requires calories > 300, fiber >= 8g, sugar <= 40g, satFat <= 15g per day.\n'
                  'Clean streak: satFat <= 20g, sugar <= 30g, sodium <= 2300mg, cholesterol <= 300mg per day.\n'
                  'After injecting, go to the Home screen to see updated streak counts.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          _devBtn(
            icon: Icons.local_fire_department,
            label: 'Inject 3-Day Healthy Streak',
            onTap: () async {
              await _injectHealthyStreak(3);
              ref.read(foodLogProvider.notifier).loadLogs(DateTime.now());
              _addLog(
                  'Injected 3 days of healthy logs. Check Home screen streaks.');
            },
          ),
          _devBtn(
            icon: Icons.shield,
            label: 'Inject 5-Day Clean (Addiction-Free) Streak',
            onTap: () async {
              await _injectCleanStreak(5);
              ref.read(foodLogProvider.notifier).loadLogs(DateTime.now());
              _addLog('Injected 5 days of clean logs.');
            },
          ),
          _devBtn(
            icon: Icons.eco,
            label: 'Remove All Expired Items (No-Waste Streak)',
            onTap: () async {
              final expired = pantry
                  .where((i) =>
              i.expiryDate != null &&
                  i.expiryDate!.isBefore(DateTime.now()))
                  .toList();
              for (final item in expired) {
                if (item.id != null) {
                  await ref
                      .read(pantryProvider.notifier)
                      .removeItem(item.id!);
                }
              }
              _addLog(
                  'Removed ${expired.length} expired items — no-waste streak improved.');
            },
          ),

          // ── Data ──────────────────────────────────────────────────────
          const SizedBox(height: 8),
          _section('Data Management'),
          _devBtn(
            icon: Icons.auto_fix_high,
            label: 'Fill Mock Data (Pantry + Recipes)',
            onTap: () async {
              final mockItems = [
                FoodItem(
                    id: 'mock1',
                    name: 'Greek Yogurt',
                    calories: 150,
                    protein: 15,
                    carbs: 6,
                    fat: 0,
                    addedDate: DateTime.now(),
                    nutriScore: 'A'),
                FoodItem(
                    id: 'mock2',
                    name: 'Chicken Breast',
                    calories: 165,
                    protein: 31,
                    carbs: 0,
                    fat: 3.6,
                    addedDate: DateTime.now(),
                    ingredientsText: 'chicken, salt'),
                FoodItem(
                    id: 'mock3',
                    name: 'Olive Oil',
                    calories: 884,
                    protein: 0,
                    carbs: 0,
                    fat: 100,
                    addedDate: DateTime.now(),
                    expiryDate:
                    DateTime.now().add(const Duration(days: 10))),
                FoodItem(
                    id: 'mock4',
                    name: 'Pork Sausage',
                    calories: 320,
                    protein: 12,
                    carbs: 2,
                    fat: 28,
                    addedDate: DateTime.now(),
                    ingredientsText: 'pork, lard, salt, spices'),
                FoodItem(
                    id: 'mock5',
                    name: 'Whole Milk',
                    calories: 61,
                    protein: 3,
                    carbs: 5,
                    fat: 3,
                    addedDate: DateTime.now(),
                    allergens: ['milk'],
                    ingredientsText: 'whole milk'),
              ];
              for (final item in mockItems) {
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
              _addLog(
                  'Pantry + recipe filled. Pork & milk items useful for filter tests.');
            },
          ),
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

          // ── State ─────────────────────────────────────────────────────
          const SizedBox(height: 8),
          _section('State Snapshot'),
          _infoRow('Logs today', '${logs.length}'),
          _infoRow('Water',
              '${water.todayMl.toInt()} / ${water.goalMl.toInt()} ml'),
          _infoRow('User', settings['name'] ?? 'N/A'),
          _infoRow('Pantry items', '${pantry.length}'),
          _infoRow('Calorie goal',
              '${(settings['calorie_goal'] ?? 2000).toInt()} kcal'),

          // ── Log ───────────────────────────────────────────────────────
          const SizedBox(height: 8),
          _devBtn(
            icon: Icons.delete_sweep,
            label: 'Clear Log',
            color: Colors.redAccent,
            onTap: () => setState(() => _log.clear()),
          ),
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _log
                    .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(l,
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Streak injection ───────────────────────────────────────────────────────

  Future<void> _injectHealthyStreak(int days) async {
    final now = DateTime.now();
    for (int i = 1; i <= days; i++) {
      final day = now.subtract(Duration(days: i));
      await DatabaseService.instance.insertMealLog(MealLog(
        id: 'dev_healthy_${day.millisecondsSinceEpoch}',
        foodItemId: 'dev_inject',
        foodName: 'Healthy Meal (Dev)',
        quantity: 1,
        consumedAt: DateTime(day.year, day.month, day.day, 12),
        type: MealType.Lunch,
        calories: 600,
        protein: 30,
        carbs: 60,
        fat: 15,
        fiber: 12, // >= 8g threshold
        sugar: 10, // <= 40g threshold
        saturatedFat: 3, // <= 15g threshold
        sodium: 500,
        cholesterol: 50,
      ));
    }
  }

  Future<void> _injectCleanStreak(int days) async {
    final now = DateTime.now();
    for (int i = 1; i <= days; i++) {
      final day = now.subtract(Duration(days: i));
      await DatabaseService.instance.insertMealLog(MealLog(
        id: 'dev_clean_${day.millisecondsSinceEpoch}',
        foodItemId: 'dev_inject',
        foodName: 'Clean Meal (Dev)',
        quantity: 1,
        consumedAt: DateTime(day.year, day.month, day.day, 12),
        type: MealType.Lunch,
        calories: 500,
        protein: 25,
        carbs: 50,
        fat: 12,
        fiber: 8,
        sugar: 15, // <= 30g threshold
        saturatedFat: 5, // <= 20g threshold
        sodium: 800, // <= 2300mg threshold
        cholesterol: 80, // <= 300mg threshold
      ));
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hard Reset?'),
        content: const Text(
            'This will delete everything. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = await DatabaseService.instance.database;
              for (final t in [
                'food_items',
                'recipes',
                'meal_logs',
                'health_entries',
                'user_settings',
                'meal_routine',
                'water_logs',
                'shopping_list',
                'shopping_groups',
                'receipts',
                'custom_diets',
              ]) {
                try {
                  await db.delete(t);
                } catch (_) {}
              }
              SystemChannels.platform
                  .invokeMethod('SystemNavigator.pop');
            },
            child: const Text('RESET & EXIT',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

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
    String? subtitle,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(color: color, fontSize: 13)),
                      if (subtitle != null)
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
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
      children: [
        Text('$key:  ',
            style:
            const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ),
      ],
    ),
  );
}

// ── Dev Filter Preview Screen ─────────────────────────────────────────────────
// Opens the exact same product dialog the scanner uses, but with a fake product.

class _DevFilterPreviewScreen extends ConsumerWidget {
  final FoodItem product;
  const _DevFilterPreviewScreen({required this.product});

  // Allergen keywords (same map as scanner_screen.dart)
  static const Map<String, List<String>> _allergenKeywords = {
    'gluten': ['gluten', 'wheat', 'barley', 'rye', 'oat', 'spelt'],
    'milk': ['milk', 'dairy', 'lactose', 'cheese', 'butter', 'cream', 'whey', 'casein'],
    'eggs': ['egg', 'albumin', 'mayonnaise'],
    'nuts': ['nuts', 'almond', 'cashew', 'walnut', 'pecan', 'pistachio', 'hazelnut'],
    'peanuts': ['peanut', 'groundnut'],
    'sesame': ['sesame', 'tahini'],
    'soybeans': ['soy', 'soya', 'tofu', 'miso'],
    'fish': ['fish', 'cod', 'salmon', 'tuna', 'anchovy', 'sardine'],
    'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'prawn'],
    'celery': ['celery'],
    'mustard': ['mustard'],
    'lupin': ['lupin'],
    'molluscs': ['mollusc', 'squid', 'octopus'],
    'sulphites': ['sulphite', 'sulfite', 'sulphur'],
  };

  static const Map<String, List<String>> _dietaryKeywords = {
    'vegan': ['meat', 'beef', 'pork', 'chicken', 'fish', 'seafood', 'milk', 'dairy', 'egg', 'cheese', 'butter', 'cream', 'honey', 'gelatin', 'lard'],
    'vegetarian': ['meat', 'beef', 'pork', 'chicken', 'turkey', 'fish', 'seafood', 'gelatin', 'lard'],
    'keto': ['sugar', 'glucose', 'fructose', 'corn syrup', 'wheat', 'rice', 'corn', 'potato', 'bread'],
    'paleo': ['grain', 'wheat', 'rice', 'corn', 'oat', 'legume', 'bean', 'soy', 'dairy', 'sugar'],
    'mediterranean': ['trans fat', 'hydrogenated', 'artificial', 'lard'],
    'low-carb': ['sugar', 'glucose', 'wheat', 'rice', 'starch', 'bread', 'pasta'],
  };

  static const Map<String, List<String>> _religiousKeywords = {
    'halal': ['pork', 'pig', 'lard', 'bacon', 'ham', 'alcohol', 'wine', 'beer', 'spirits'],
    'kosher': ['pork', 'pig', 'lard', 'shellfish', 'shrimp', 'crab', 'lobster'],
    'hindu vegetarian': ['beef', 'veal', 'pork', 'chicken', 'egg'],
    'jain': ['meat', 'fish', 'egg', 'onion', 'garlic', 'potato'],
    'buddhist vegetarian': ['meat', 'fish', 'egg', 'onion', 'garlic'],
    'christian lent': ['meat', 'beef', 'pork', 'chicken'],
    'orthodox lent': ['meat', 'dairy', 'egg', 'fish', 'oil', 'wine'],
  };

  List<String> _detectAllergens(List<String> userAllergies) {
    final text = '${product.name} ${product.ingredientsText ?? ''} ${product.allergens.join(' ')}'.toLowerCase();
    final found = <String>[];
    for (final a in userAllergies) {
      final keywords = _allergenKeywords[a.toLowerCase()] ?? [a.toLowerCase()];
      if (keywords.any((k) => text.contains(k))) found.add(a);
    }
    return found;
  }

  List<String> _detectDietViolations(List<String> dietary, List<String> religious) {
    final text = '${product.name} ${product.ingredientsText ?? ''} ${product.allergens.join(' ')}'.toLowerCase();
    final v = <String>[];
    for (final d in dietary) {
      final kw = _dietaryKeywords[d.toLowerCase()] ?? [];
      if (kw.any((k) => text.contains(k))) v.add('Not ${d.toTitleCase()}');
    }
    for (final r in religious) {
      final kw = _religiousKeywords[r.toLowerCase()] ?? [];
      if (kw.any((k) => text.contains(k))) v.add('Violates ${r.toTitleCase()}');
    }
    return v;
  }

  Color _nutriColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'a': return Colors.green.shade700;
      case 'b': return Colors.green.shade400;
      case 'c': return Colors.yellow.shade700;
      case 'd': return Colors.orange.shade700;
      case 'e': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final userAllergies = List<String>.from(settings['allergies'] ?? []);
    final userDietary = List<String>.from(settings['dietary_prefs'] ?? []);
    final userReligious = List<String>.from(settings['religious_prefs'] ?? []);

    final allergyWarnings = _detectAllergens(userAllergies);
    final dietViolations = _detectDietViolations(userDietary, userReligious);
    final hasWarning = allergyWarnings.isNotEmpty || dietViolations.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Filter Preview'),
        backgroundColor: AppColors.card,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.olive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.olive),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            style: AppTextStyles.heading2),
                        Text(product.brand ?? 'Dev Test',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (product.nutriScore != null)
                    Chip(
                      label: Text(product.nutriScore!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      backgroundColor: _nutriColor(product.nutriScore),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter results panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasWarning
                    ? Colors.redAccent.withOpacity(0.08)
                    : AppColors.olive.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasWarning
                      ? Colors.redAccent.withOpacity(0.4)
                      : AppColors.olive.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        hasWarning
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: hasWarning
                            ? Colors.redAccent
                            : AppColors.olive,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasWarning
                            ? 'Your filters flagged this product'
                            : 'Passes all your active filters',
                        style: TextStyle(
                          color: hasWarning
                              ? Colors.redAccent
                              : AppColors.olive,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (allergyWarnings.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('ALLERGY WARNING',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      'Contains: ${allergyWarnings.map((a) => a.toUpperCase()).join(", ")}',
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ],
                  if (dietViolations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('DIET RESTRICTIONS',
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      dietViolations.join(' · '),
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 13),
                    ),
                  ],
                  if (!hasWarning) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Active filters: ${[...userAllergies, ...userDietary, ...userReligious].isEmpty ? "none — set filters in Settings" : [...userAllergies, ...userDietary, ...userReligious].join(", ")}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ingredients',
                      style: TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product.ingredientsText ?? 'No ingredient data',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  if (product.allergens.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Declared allergens:',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: product.allergens
                          .map((a) => Chip(
                        label: Text(a,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white)),
                        backgroundColor: AppColors.card,
                      ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nutrition (per 100g)',
                      style: TextStyle(
                          color: AppColors.olive,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macro('Kcal',
                          '${product.calories.toInt()}'),
                      _macro('Protein',
                          '${product.protein.toStringAsFixed(1)}g'),
                      _macro('Carbs',
                          '${product.carbs.toStringAsFixed(1)}g'),
                      _macro('Fat',
                          '${product.fat.toStringAsFixed(1)}g'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, String value) => Column(
    children: [
      Text(value,
          style: const TextStyle(
              color: AppColors.olive,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      Text(label,
          style: const TextStyle(
              color: Colors.white54, fontSize: 11)),
    ],
  );
}
