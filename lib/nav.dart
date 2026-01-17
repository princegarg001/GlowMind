import 'package:glowmind/pages/home/glow_home_page.dart';
//import 'package:glowmind/pages/notes/notes_page.dart';
import 'package:glowmind/pages/sleep/sleep_page.dart';
import 'package:glowmind/pages/settings_page.dart';
import 'package:glowmind/pages/splash_gate.dart';
import 'package:glowmind/pages/auth_page.dart';
import 'package:glowmind/pages/Insights/insightspage.dart'; // NEW
import 'package:glowmind/pages/playlist/playlist_page.dart';
import 'package:glowmind/models/models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashGate()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AuthPage()),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: GlowHomePage()),
      ),
     
      GoRoute(
        path: AppRoutes.sleep,
        name: 'sleep',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SleepPage()),
      ),
      GoRoute(
        path: AppRoutes.insights, // NEW
        name: 'insights',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: InsightsPage()),
      ),
      GoRoute(
        path: '${AppRoutes.playlist}/:mood',
        name: 'playlist',
        pageBuilder: (context, state) {
          final moodStr = state.pathParameters['mood'] ?? 'balanced';
          final mood = _parseMood(moodStr);
          return NoTransitionPage(child: PlaylistPage(mood: mood));
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsPage()),
      ),
    ],
  );

  static GlowMood _parseMood(String moodStr) {
    switch (moodStr.toLowerCase()) {
      case 'anxious':
        return GlowMood.anxious;
      case 'burnoutrisk':
        return GlowMood.burnoutRisk;
      case 'balanced':
      default:
        return GlowMood.balanced;
    }
  }
}

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String notes = '/notes';
  static const String sleep = '/sleep';
  static const String insights = '/insights'; // NEW
  static const String playlist = '/playlist';
  static const String settings = '/settings';
  
  static String playlistForMood(GlowMood mood) => '/playlist/${mood.name}';
}
