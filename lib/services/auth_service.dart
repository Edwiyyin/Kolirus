import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_service.dart';
// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final GoogleSignInAccount? account;
  final bool isLoading;
  final bool hasCompletedOnboarding;

  const AuthState({
    this.account,
    this.isLoading = false,
    this.hasCompletedOnboarding = false,
  });

  bool get isSignedIn => account != null;
  String get userId => account?.id ?? 'local_user';
  String get displayName => account?.displayName ?? 'Guest';
  String get email => account?.email ?? '';
  String? get photoUrl => account?.photoUrl;

  AuthState copyWith({
    GoogleSignInAccount? account,
    bool? isLoading,
    bool? hasCompletedOnboarding,
    bool clearAccount = false,
  }) {
    return AuthState(
      account: clearAccount ? null : (account ?? this.account),
      isLoading: isLoading ?? this.isLoading,
      hasCompletedOnboarding:
      hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('koly_onboarded') ?? false;

    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await SyncService.instance.syncFromCloud(account.id);
      }
      state = state.copyWith(
        account: account,
        isLoading: false,
        hasCompletedOnboarding: onboarded,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        hasCompletedOnboarding: onboarded,
      );
    }
  }

  Future<bool> signIn() async {
    try {
      state = state.copyWith(isLoading: true);
      final account = await _googleSignIn.signIn();
      if (account != null) {
        // Upload local data to cloud first
        await SyncService.instance.syncToCloud(account.id);
        // Then pull any existing cloud data
        await SyncService.instance.syncFromCloud(account.id);
        state = state.copyWith(account: account, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    // Upload latest data before signing out
    if (state.account != null) {
      await SyncService.instance.syncToCloud(state.account!.id);
    }
    await _googleSignIn.signOut();
    state = state.copyWith(clearAccount: true);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('koly_onboarded', true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }


}
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// ── Sign-In Screen ────────────────────────────────────────────────────────────

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF2A1733),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/koly.png',
                width: 140,
                height: 140,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.eco,
                  size: 100,
                  color: Color(0xFF808000),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kolirus',
                style: TextStyle(
                  color: Color(0xFFDECD87),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Eat like your Mediterranean ancestors',
                style: TextStyle(
                  color: Color(0xFFC8B870),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Google Sign-In
              if (auth.isLoading)
                const CircularProgressIndicator(color: Color(0xFF808000))
              else ...[
                // Google Sign-In button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.login, size: 22),
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  onPressed: () async {
                    final success =
                    await ref.read(authProvider.notifier).signIn();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Sign-in failed. Try again.')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Continue without account
                TextButton(
                  onPressed: () {
                    // Just proceed — no account needed
                    ref.read(authProvider.notifier).completeOnboarding();
                  },
                  child: const Text(
                    'Continue without account',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to sync your data across devices',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Account Card (used in Settings) ──────────────────────────────────────────

class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3A2244),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined,
                color: Color(0xFF808000), size: 40),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest Mode',
                      style: TextStyle(
                          color: Color(0xFFDECD87),
                          fontWeight: FontWeight.bold)),
                  Text('Data stored on this device only',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF808000),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signIn();
              },
              child: const Text('Sign In',
                  style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2244),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF808000).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: auth.photoUrl != null
                ? NetworkImage(auth.photoUrl!)
                : null,
            backgroundColor: const Color(0xFF808000).withOpacity(0.2),
            child: auth.photoUrl == null
                ? Text(
              auth.displayName.isNotEmpty
                  ? auth.displayName[0].toUpperCase()
                  : 'G',
              style: const TextStyle(
                  color: Color(0xFF808000),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.displayName,
                  style: const TextStyle(
                      color: Color(0xFFDECD87), fontWeight: FontWeight.bold),
                ),
                Text(
                  auth.email,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF808000).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Data synced',
                    style: TextStyle(
                        color: Color(0xFF808000),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}