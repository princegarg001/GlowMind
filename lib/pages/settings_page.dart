import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/theme.dart';
import 'package:glowmind/nav.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: Theme.of(context).textTheme.titleLarge?.withColor(scheme.onSurface))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.person_outline, color: scheme.onSurface),
              title: Text(app.user?.isGuest == true ? 'Guest user' : 'Signed in'),
              subtitle: Text(app.user?.email ?? 'No email'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: const Text('Sign out'),
              onTap: () async {
                await context.read<AppState>().signOut();
                if (context.mounted) context.go(AppRoutes.auth);
              },
            ),
          ),
        ],
      ),
    );
  }
}
