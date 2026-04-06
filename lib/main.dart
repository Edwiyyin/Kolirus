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
import 'screens/planner_screen.dart';
import 'screens/addiction_screen.dart';
import 'services/notification_service.dart';
import 'providers/navigation_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/health_provider.dart';

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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _bannerMessage;

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
      if (_isOpen)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  void _showBanner(String msg) {
    setState(() => _bannerMessage = msg);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bannerMessage = null);
    });
  }

  void _refreshAll() {
    ref.read(foodLogProvider.notifier).loadLogs(DateTime.now());
    ref.read(healthProvider.notifier).loadData();
    _showBanner('Data Refreshed');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    final List<Widget> screens = [
      const HomeScreen(),
      const PantryScreen(),
      const RecipeScreen(),
      const RoutineScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: GestureDetector(
              onTap: _refreshAll,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.restaurant_menu, color: AppColors.olive, size: 24),
                ),
              ),
            ),
          ),
        ),
        title: const Text('Kolirus',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined, color: AppColors.olive),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.beige),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          IndexedStack(
            index: currentIndex.clamp(0, 3),
            children: screens,
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
            _navItem(Icons.home_rounded, 'Home', 0, currentIndex),
            _navItem(Icons.kitchen_rounded, 'Kitchen', 1, currentIndex),
            const SizedBox(width: 48),
            _navItem(Icons.menu_book_rounded, 'Recipes', 2, currentIndex),
            _navItem(Icons.calendar_month_rounded, 'Calendar', 3, currentIndex),
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

  Widget _buildDrawer(BuildContext context) {
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/logo.png', width: 28, height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.restaurant_menu, color: Colors.black, size: 28)),
                  ),
                  const SizedBox(width: 12),
                  const Text('KOLIRUS',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          letterSpacing: 1.5, fontSize: 18, color: AppColors.beige)),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('ANALYTICS', style: TextStyle(color: AppColors.olive,
                  fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            _drawerItem(context, Icons.bar_chart_rounded, 'Stats', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
            }),
            _drawerItem(context, Icons.warning_amber_rounded, 'Addiction Tracker', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddictionScreen()));
            }),
            const Divider(color: Colors.white10),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('ACCOUNT', style: TextStyle(color: AppColors.olive,
                  fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            _drawerItem(context, Icons.settings_outlined, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Kolirus v1.0.0',
                  style: TextStyle(color: Colors.white24, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.olive, size: 22),
      title: Text(label, style: const TextStyle(color: AppColors.beige, fontSize: 14)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _navItem(IconData icon, String label, int index, int current) {
    return IconButton(
      icon: Icon(icon,
          color: index == current ? AppColors.olive : AppColors.textLight),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _circularButton(Icons.qr_code_scanner, "Scan Food", () {
                  _toggleMenu();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScannerScreen()));
                }),
                const SizedBox(width: 30),
                _circularButton(Icons.receipt_long, "Receipt", () {
                  _toggleMenu();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReceiptScannerScreen()));
                }),
              ],
            ),
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
        Text(label,
            style: const TextStyle(color: AppColors.beige, fontSize: 10)),
      ],
    );
  }
}