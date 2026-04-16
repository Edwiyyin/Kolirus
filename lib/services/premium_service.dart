import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// ── Premium State ─────────────────────────────────────────────────────────────

class PremiumState {
  final bool isPremium;
  final bool isLoading;

  const PremiumState({this.isPremium = false, this.isLoading = false});
}

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(const PremiumState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final premium = prefs.getBool('kolirus_premium') ?? false;
    state = PremiumState(isPremium: premium);
  }

  Future<bool> purchasePremium(BuildContext context) async {
    state = PremiumState(isLoading: true);

    // Simulate payment processing (2-second delay)
    // In production: integrate Google Play Billing / in_app_purchase package
    await Future.delayed(const Duration(seconds: 2));

    // For demo: always succeed
    // Real implementation would call:
    //   InAppPurchase.instance.buyConsumable(purchaseParam) or buyNonConsumable
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kolirus_premium', true);
    state = const PremiumState(isPremium: true);
    return true;
  }

  Future<void> restorePurchases() async {
    // In production: InAppPurchase.instance.restorePurchases()
    final prefs = await SharedPreferences.getInstance();
    final premium = prefs.getBool('kolirus_premium') ?? false;
    state = PremiumState(isPremium: premium);
  }
}

final premiumProvider =
StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier();
});

// ── Ad Banner Widget ──────────────────────────────────────────────────────────
// Simulated ad banner — replace with real AdMob widget when SDK is configured

class AdBannerWidget extends ConsumerWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);
    if (premium.isPremium) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showAdModal(context, ref),
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0F22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('Ad', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Kolirus — Remove Ads',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    'Go Premium for \$2',
                    style: TextStyle(
                        color: Color(0xFF808000),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF808000).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF808000).withOpacity(0.4)),
                ),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Color(0xFF808000), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const PremiumUpsellSheet(),
    );
  }
}

// ── Premium Upsell Sheet ──────────────────────────────────────────────────────

class PremiumUpsellSheet extends ConsumerWidget {
  const PremiumUpsellSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);

    if (premium.isPremium) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Color(0xFF808000), size: 48),
            const SizedBox(height: 12),
            const Text('You\'re Premium!',
                style: TextStyle(
                    color: Color(0xFFDECD87),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Thank you for supporting Kolirus. Enjoy no ads!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/koly.png',
                width: 56,
                height: 56,
                errorBuilder: (_, __, ___) => const Icon(Icons.eco,
                    size: 48, color: Color(0xFF808000)),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Go Premium',
                        style: TextStyle(
                            color: Color(0xFFDECD87),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('One-time purchase',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF808000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '\$2',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          ...[
            ('Remove all ads forever', Icons.block),
            ('Unlock Auto Plan (AI meal planner)', Icons.auto_awesome),
            ('Support independent development', Icons.favorite),
          ].map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(item.$2, color: const Color(0xFF808000), size: 18),
                const SizedBox(width: 12),
                Text(item.$1,
                    style: const TextStyle(
                        color: Color(0xFFDECD87), fontSize: 14)),
              ],
            ),
          )),
          const SizedBox(height: 20),
          if (premium.isLoading)
            const CircularProgressIndicator(color: Color(0xFF808000))
          else ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF808000),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final success =
                await ref.read(premiumProvider.notifier).purchasePremium(context);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Welcome to Premium! Ads removed.'),
                      backgroundColor: Color(0xFF808000),
                    ),
                  );
                }
              },
              child: const Text(
                'Unlock Premium — \$2',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => ref.read(premiumProvider.notifier).restorePurchases(),
              child: const Text('Restore Purchase',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Paywall Gate Widget ───────────────────────────────────────────────────────
// Wrap any feature that requires premium

class PremiumGate extends ConsumerWidget {
  final Widget child;
  final String featureName;
  final String description;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    required this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);
    if (premium.isPremium) return child;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => const PremiumUpsellSheet(),
      ),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Color(0xFF808000), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    featureName,
                    style: const TextStyle(
                        color: Color(0xFFDECD87),
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style:
                    const TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF808000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Unlock for \$2',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}