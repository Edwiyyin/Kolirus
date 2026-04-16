import 'package:flutter/material.dart';
import '../utils/constants.dart';

// ── Koly Speech Bubble Widget ─────────────────────────────────────────────────
class KolySpeechBubble extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool showMascot;

  const KolySpeechBubble({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.showMascot = true,
  });

  @override
  State<KolySpeechBubble> createState() => _KolySpeechBubbleState();
}

class _KolySpeechBubbleState extends State<KolySpeechBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _bounceAnim,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.showMascot) ...[
                _KolyIcon(size: 200),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Speech bubble
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.olive.withOpacity(0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(
                            color: AppColors.olive.withOpacity(0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Koly',
                                style: TextStyle(
                                  color: AppColors.olive,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              if (widget.onDismiss != null)
                                GestureDetector(
                                  onTap: widget.onDismiss,
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white38),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppColors.beige,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          if (widget.actionLabel != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: widget.onAction,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.olive,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Koly Icon (uses the uploaded PNG) ────────────────────────────────────────
class _KolyIcon extends StatefulWidget {
  final double size;
  const _KolyIcon({required this.size});

  @override
  State<_KolyIcon> createState() => _KolyIconState();
}

class _KolyIconState extends State<_KolyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounceAnim.value),
        child: child,
      ),
      child: Image.asset(
        'assets/koly.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _KolyFallback(size: widget.size),
      ),
    );
  }
}

// Fallback if asset not found
class _KolyFallback extends StatelessWidget {
  final double size;
  const _KolyFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.eco, color: AppColors.olive, size: size * 0.8),
    );
  }
}

// ── Koly Tip Card (inline in screens) ────────────────────────────────────────
class KolyTipCard extends StatelessWidget {
  final String tip;
  final VoidCallback? onDismiss;

  const KolyTipCard({super.key, required this.tip, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.olive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.olive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _KolyIcon(size: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                color: AppColors.beige,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 14, color: Colors.white38),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}

// ── Koly Onboarding Screen ────────────────────────────────────────────────────
class KolyOnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const KolyOnboardingScreen({super.key, required this.onFinish});

  @override
  State<KolyOnboardingScreen> createState() => _KolyOnboardingScreenState();
}

class _KolyOnboardingScreenState extends State<KolyOnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late PageController _pageController;
  late AnimationController _mascotController;
  late Animation<double> _mascotBounce;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      title: "Hi, I'm Koly! 👋",
      message:
      "I'm your Mediterranean food buddy! I'll help you track what you eat, reduce food waste, and eat like your ancestors did — fresh, simple, and delicious.",
      emoji: '🫒',
    ),
    _OnboardingStep(
      title: "Your Kitchen, Organized",
      message:
      "Add food to your pantry by scanning barcodes or typing manually. I'll remind you before things expire — no more forgotten food in the back of the fridge!",
      emoji: '🥗',
    ),
    _OnboardingStep(
      title: "Log What You Eat",
      message:
      "Track your meals to understand your habits. I'll show you how much protein, carbs, and fat you're getting every day. Knowledge is the first step to eating better!",
      emoji: '📊',
    ),
    _OnboardingStep(
      title: "Build Healthy Streaks",
      message:
      "Earn streaks for healthy eating, staying hydrated, and wasting no food. Just like Duolingo — but for your plate! Let's build habits together.",
      emoji: '🔥',
    ),
    _OnboardingStep(
      title: "Ready to Start!",
      message:
      "Sign in with Google to save your data across devices, or continue without an account. Your food journey starts now — I'll be here whenever you need help!",
      emoji: '🚀',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _mascotBounce = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinish,
                child: const Text('Skip',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ),

            // Mascot
            Expanded(
              flex: 3,
              child: AnimatedBuilder(
                animation: _mascotBounce,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _mascotBounce.value),
                  child: child,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/koly.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.eco,
                          size: 120,
                          color: AppColors.olive,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _steps[_step].emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 4,
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            color: AppColors.beige,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.message,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + Button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  // Step dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _step ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _step
                              ? AppColors.olive
                              : AppColors.olive.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.olive,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _next,
                    child: Text(
                      _step == _steps.length - 1 ? "Let's Go!" : 'Next',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String message;
  final String emoji;

  const _OnboardingStep({
    required this.title,
    required this.message,
    required this.emoji,
  });
}

// ── Koly Help Button (floating) ───────────────────────────────────────────────
class KolyHelpButton extends StatelessWidget {
  final String tip;
  const KolyHelpButton({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => KolySpeechBubble(message: tip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Image.asset(
          'assets/koly.png',
          width: 45,
          height: 45,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppColors.olive),
        ),
      ),
    );
  }
}