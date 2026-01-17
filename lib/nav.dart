import 'package:glowmind/pages/home/glow_home_page.dart';
import 'package:glowmind/pages/music/vertical_mood_navigator.dart';
import 'package:glowmind/pages/music/playlist_manager_page.dart';
//import 'package:glowmind/pages/notes/notes_page.dart';
import 'package:glowmind/pages/sleep/sleep_page.dart';
import 'package:glowmind/pages/settings_page.dart';
import 'package:glowmind/pages/splash_gate.dart';
import 'package:glowmind/pages/auth_page.dart';
import 'package:glowmind/pages/Insights/insightspage.dart'; // NEW
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
            const NoTransitionPage(child: VerticalMoodNavigator()),
      ),
      GoRoute(
        path: AppRoutes.originalHome,
        name: 'original_home',
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
        path: AppRoutes.playlists,
        name: 'playlists',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PlaylistManagerPage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SettingsPage()),
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String originalHome = '/original-home';
  static const String notes = '/notes';
  static const String sleep = '/sleep';
  static const String insights = '/insights'; // NEW
  static const String playlists = '/playlists';
  static const String settings = '/settings';
}
