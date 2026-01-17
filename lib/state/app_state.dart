import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/services/glow_engine.dart';
import 'package:glowmind/services/supabase_service.dart';
import 'package:glowmind/supabase/supabase_config.dart';
import 'package:glowmind/state/music_state.dart';

class AppState extends ChangeNotifier {
  AppState({
    required SupabaseDataService dataService,
    required GlowEngine glowEngine,
    MusicState? musicState,
  })  : _dataService = dataService,
        _glowEngine = glowEngine,
        _musicState = musicState;

  final SupabaseDataService _dataService;
  final GlowEngine _glowEngine;
  final MusicState? _musicState;
  StreamSubscription? _authSubscription;

  AuthStatus _authStatus = AuthStatus.signedOut;
  AppUser? _user;
  List<NoteEntry> _notes = const [];
  SleepProfile? _sleep;
  GlowState _glow = const GlowState(intensity: 0.5, pulse: 0.2, mood: GlowMood.balanced);
  bool _isLoading = false;

  AuthStatus get authStatus => _authStatus;
  AppUser? get user => _user;
  List<NoteEntry> get notes => _notes;
  SleepProfile? get sleep => _sleep;
  GlowState get glow => _glow;
  bool get isLoading => _isLoading;
  MusicState? get musicState => _musicState;

  Future<void> init() async {
    _authSubscription = SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _onAuthChanged(session.user);
      } else {
        _onSignOut();
      }
    });
    
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser != null) {
      await _onAuthChanged(currentUser);
    }
  }

  Future<void> _onAuthChanged(dynamic supabaseUser) async {
    try {
      debugPrint('AppState: Auth changed for user: ${supabaseUser.id}');
      _isLoading = true;
      notifyListeners();

      _authStatus = AuthStatus.signedIn;
      _user = await _dataService.loadUser(supabaseUser.id);
      debugPrint('AppState: User loaded: ${_user != null}');
      
      // Initialize music even if user data fails to load
      final userId = _user?.id ?? supabaseUser.id;
      
      if (_user != null) {
        await loadUserData();
      }
      
      // Initialize music state for user
      if (_musicState != null) {
        debugPrint('AppState: Initializing music for user: $userId');
        await _musicState!.initForUser(userId);
        debugPrint('AppState: Music initialization complete');
      }
    } catch (e) {
      debugPrint('AppState: Auth change error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onSignOut() {
    _authStatus = AuthStatus.signedOut;
    _user = null;
    _notes = const [];
    _sleep = null;
    _glow = const GlowState(intensity: 0.5, pulse: 0.2, mood: GlowMood.balanced);
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (_user == null) return;
    
    try {
      _notes = await _dataService.loadNotes(_user!.id);
      _sleep = await _dataService.loadSleepProfile(_user!.id);
      _recomputeGlow();
      notifyListeners();
    } catch (e) {
      debugPrint('loadUserData error: $e');
    }
  }

  Future<void> continueAsGuest() async {
    debugPrint('AppState: Continuing as guest');
    _authStatus = AuthStatus.guest;
    _user = const AppUser(id: 'guest', isGuest: true);
    notifyListeners();
    
    // Initialize music for guest user (don't block if this fails)
    if (_musicState != null) {
      debugPrint('AppState: Initializing music for guest user');
      try {
        await _musicState!.initForUser('guest');
        debugPrint('AppState: Guest music initialization completed');
      } catch (e) {
        debugPrint('AppState: Guest music initialization failed: $e');
        // Continue without music - it's not critical for guest login
      }
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
      _onSignOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> addNote(String text) async {
    if (_user == null) return;
    
    try {
      final note = await _dataService.addNote(_user!.id, text);
      if (note != null) {
        _notes = [note, ..._notes];
        _recomputeGlow();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('addNote error: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final success = await _dataService.deleteNote(id);
      if (success) {
        _notes = _notes.where((n) => n.id != id).toList();
        _recomputeGlow();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deleteNote error: $e');
    }
  }

  Future<void> setSleepProfile(TimeOfDaySimple bedtime, TimeOfDaySimple wakeTime) async {
    if (_user == null) return;
    
    try {
      final profile = await _dataService.saveSleepProfile(_user!.id, bedtime, wakeTime);
      if (profile != null) {
        _sleep = profile;
        _recomputeGlow();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('setSleepProfile error: $e');
    }
  }

  void _recomputeGlow() {
    try {
      _glow = _glowEngine.computeGlow(notes: _notes, sleep: _sleep);
    } catch (e) {
      debugPrint('Glow recompute error: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
