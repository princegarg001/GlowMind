import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/services/supabase_service.dart';
import 'package:glowmind/services/glow_engine.dart';
import 'package:glowmind/services/audio_service.dart';
import 'package:glowmind/services/music_storage.dart';
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
  Widget build(BuildContext context) {
    // Create music state instance
    final musicState = MusicState(
      audioService: AudioService(),
      storage: MusicStorage(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(
            dataService: SupabaseDataService(),
            glowEngine: GlowEngine(),
            musicState: musicState,
          )..init(),
        ),
        ChangeNotifierProvider.value(value: musicState),
      ],
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
}
