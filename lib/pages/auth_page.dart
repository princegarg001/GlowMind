import 'package:flutter/material.dart';
import 'package:glowmind/auth/supabase_auth_manager.dart';
import 'package:glowmind/nav.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B061A),
                  Color(0xFF1A0F3D),
                  Color(0xFF05030C),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Purple Glow Orb
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.35),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.6),
                    blurRadius: 120,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'GlowMind',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: const Color(0xFFF5F3FF),
                          shadows: const [
                            Shadow(
                              color: Color(0xFF8B5CF6),
                              blurRadius: 18,
                            )
                          ],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silent mental health companion — understands without asking.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFBDB4FF),
                        ),
                  ),
                  const SizedBox(height: 56),
                  const _AuthCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatefulWidget {
  const _AuthCard();

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authManager = SupabaseAuthManager();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _isSignUp
          ? await _authManager.createAccountWithEmail(context, _emailController.text, _passwordController.text)
          : await _authManager.signInWithEmail(context, _emailController.text, _passwordController.text);

      if (user != null && mounted) {
        await context.read<AppState>().loadUserData();
        if (mounted) context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authManager.signInWithGoogle(context);
      if (user != null && mounted) {
        await context.read<AppState>().loadUserData();
        if (mounted) context.go(AppRoutes.home);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestContinue() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AppState>().continueAsGuest();
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to continue as guest. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140F28).withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6D4AFF).withOpacity(0.4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 35,
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSignUp ? 'Create Account' : 'Sign In',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFFF5F3FF)),
            ),
            const SizedBox(height: 20),
            _glowField(controller: _emailController, label: 'Email', enabled: !_isLoading),
            const SizedBox(height: 14),
            _glowField(controller: _passwordController, label: 'Password', obscure: true, enabled: !_isLoading),
            const SizedBox(height: 22),
            _glowButton(text: _isSignUp ? 'Sign Up' : 'Sign In', loading: _isLoading, onTap: _handleEmailAuth),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleSignIn,
              icon: const Icon(Icons.g_mobiledata, size: 28, color: Color(0xFFC7BFFF)),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC7BFFF),
                side: const BorderSide(color: Color(0xFF6D5BFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp ? 'Already have an account? Sign in' : 'Need an account? Sign up',
                style: const TextStyle(color: Color(0xFFC7BFFF)),
              ),
            ),
            const Divider(height: 32, color: Color(0xFF2A2450)),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGuestContinue,
              icon: const Icon(Icons.bolt, color: Color(0xFF8B5CF6)),
              label: const Text('Continue as guest'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEDE9FE),
                side: const BorderSide(color: Color(0xFF6D4AFF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: const TextStyle(color: Color(0xFFEDE9FE)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFBDB4FF)),
        filled: true,
        fillColor: const Color(0xFF0F0A22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5B4BFF), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFA78BFA), width: 1.2),
        ),
      ),
    );
  }

  Widget _glowButton({
    required String text,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.45),
            blurRadius: 28,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
