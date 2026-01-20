import 'package:flutter/material.dart';
import 'package:glowmind/services/affirmation_service.dart';
import 'package:glowmind/services/audio_recorder_service.dart';
import 'package:glowmind/services/audio_service.dart';
import 'package:glowmind/services/glow_engine.dart';
import 'package:glowmind/services/music_storage.dart';
import 'package:glowmind/services/notification_service.dart';
import 'package:glowmind/services/supabase_service.dart';
import 'package:glowmind/state/affirmation_state.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/supabase/supabase_config.dart';
import 'package:provider/provider.dart';

import 'nav.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  // Initialize notification service early for background tasks
  try {
    await NotificationService.instance.initialize();
    debugPrint('NotificationService initialized in main');
  } catch (e) {
    debugPrint('Notification initialization error: $e');
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

    // Create affirmation state instance
    final affirmationState = AffirmationState(
      service: AffirmationService(),
      audioRecorder: AudioRecorderService(),
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
        ChangeNotifierProvider.value(value: affirmationState),
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
