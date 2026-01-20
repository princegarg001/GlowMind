import 'package:flutter/material.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/nav.dart';
import 'package:glowmind/services/local_store.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();

    Future.microtask(() => _checkAuthAndNavigate());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    final app = context.read<AppState>();

    // Wait for animation and initialization
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted || _navigated) return;
    _navigated = true;

    // Check if user has ever signed up before (stored locally)
    final hasAccount = await LocalStore.getBool('has_account') ?? false;

    switch (app.authStatus) {
      case AuthStatus.signedOut:
        if (!mounted) return;
        // New users go to sign up, returning users go to sign in
        if (hasAccount) {
          context.go(AppRoutes.signIn);
        } else {
          context.go(AppRoutes.signUp);
        }
      case AuthStatus.guest:
      case AuthStatus.signedIn:
        if (!mounted) return;
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B061A),
              Color(0xFF1A0F3D),
              Color(0xFF05030C),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated glow orb
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Center(
                    child: Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withOpacity(0.6),
                            const Color(0xFF6366F1).withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.5),
                            blurRadius: 80,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_outlined,
                          size: 80,
                          color: Color(0xFFF5F3FF),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // App name and tagline
            Positioned(
              top: MediaQuery.of(context).size.height * 0.55,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      'GlowMind',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: const Color(0xFFF5F3FF),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        shadows: [
                          const Shadow(
                            color: Color(0xFF8B5CF6),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your silent mental health companion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFFBDB4FF),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            // Loading indicator
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
