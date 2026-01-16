import 'package:flutter/material.dart';
import 'package:glowmind/nav.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/models/models.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final app = context.read<AppState>();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _navigated) return;
      _navigated = true;
      switch (app.authStatus) {
        case AuthStatus.signedOut:
          if (!mounted) return; context.go(AppRoutes.auth);
        case AuthStatus.guest:
        case AuthStatus.signedIn:
          if (!mounted) return; context.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
