import 'package:flutter/material.dart';
import 'package:glowmind/nav.dart';
import 'package:glowmind/services/freesound_service.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
          const SizedBox(height: AppSpacing.md),
          ServiceTestTile(
            title: 'Freesound API',
            icon: Icons.api_outlined,
            onTest: () => FreesoundService().testConnection(),
          ),
          const SizedBox(height: AppSpacing.md),
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

class ServiceTestTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Future<bool> Function() onTest;

  const ServiceTestTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTest,
  });

  @override
  State<ServiceTestTile> createState() => _ServiceTestTileState();
}

class _ServiceTestTileState extends State<ServiceTestTile> {
  bool? _success;
  bool _loading = false;

  Future<void> _test() async {
    setState(() {
      _loading = true;
      _success = null;
    });
    try {
      final result = await widget.onTest();
      if (mounted) {
        setState(() {
          _success = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _success = false;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(widget.icon, color: scheme.primary),
        title: Text('Test ${widget.title}'),
        subtitle: _success == null
            ? Text('Verify connection to ${widget.title}')
            : Text(
                _success! ? 'Connection healthy' : 'Connection failed',
                style: TextStyle(
                  color: _success! ? Colors.green : scheme.error,
                  fontSize: 12,
                ),
              ),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _success == null
                      ? scheme.outline.withOpacity(0.3)
                      : (_success! ? Colors.green : Colors.red),
                  boxShadow: _success != null
                      ? [
                          BoxShadow(
                            color: (_success! ? Colors.green : Colors.red).withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              ),
        onTap: _loading ? null : _test,
      ),
    );
  }
}
