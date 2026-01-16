import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/services/supabase_service.dart';
import 'package:glowmind/services/glow_engine.dart';
import 'package:glowmind/supabase/supabase_config.dart';
import 'theme.dart';
import 'nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AppState(
          dataService: SupabaseDataService(),
          glowEngine: GlowEngine(),
        )..init(),
        child: MaterialApp.router(
          title: 'GlowMind',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: AppRouter.router,
        ),
      );
}
