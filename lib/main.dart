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
import 'providers/navigation_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/health_provider.dart';
import 'providers/water_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/pantry_provider.dart';
import 'widgets/koly_mascot.dart';
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
      if (devUnlocked) const _DevScreen(),
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

// ── Dev Screen ─────────────────────────────────────────────────────────────────

class _DevScreen extends ConsumerWidget {
  const _DevScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools', style: TextStyle(color: Colors.redAccent)),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => ref.read(navigationProvider.notifier).state = 0)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _devSection('Testing & Simulation'),
          _devBtn(
            icon: Icons.water_drop,
            label: 'Simulate Water (+500ml)',
            onTap: () => ref.read(waterProvider.notifier).addWater(500),
          ),
          const Divider(),
          _devSection('App State'),
          _devBtn(
            icon: Icons.refresh,
            label: 'Reset Onboarding',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('koly_onboarded', false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Onboarding reset. Restart app.')));
            },
          ),
          _devBtn(
            icon: Icons.star,
            label: 'Toggle Premium Status',
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final current = prefs.getBool('kolirus_premium') ?? false;
              await prefs.setBool('kolirus_premium', !current);
              ref.invalidate(premiumProvider);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Premium: ${!current}')));
            },
          ),
        ],
      ),
    );
  }

  Widget _devSection(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(color: AppColors.olive, fontWeight: FontWeight.bold, fontSize: 11)),
  );

  Widget _devBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.olive),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.white10)),
    );
  }
}
