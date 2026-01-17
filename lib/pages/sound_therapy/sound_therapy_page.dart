import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/services/sound_therapy_service.dart';
import 'package:glowmind/services/audio_service.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/widgets/sleep_timer_dialog.dart';

/// Sound therapy playlist page with playback controls
class SoundTherapyPage extends StatefulWidget {
  final GlowMood mood;

  const SoundTherapyPage({
    super.key,
    required this.mood,
  });

  @override
  State<SoundTherapyPage> createState() => _SoundTherapyPageState();
}

class _SoundTherapyPageState extends State<SoundTherapyPage> {
  final SoundTherapyService _soundService = SoundTherapyService();
  final AudioService _audioService = AudioService();
  
  Playlist? _playlist;
  bool _isLoading = true;
  String? _error;
  bool _isPlaying = false;
  Track? _currentTrack;
  int _currentTrackIndex = 0;
  LoopMode _loopMode = LoopMode.all;
  bool _shuffle = false;
  Duration _position = Duration.zero;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    _setupListeners();
  }

  void _setupListeners() {
    _audioService.isPlayingStream.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _audioService.trackStream.listen((track) {
      if (mounted) {
        setState(() => _currentTrack = track);
      }
    });

    _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _audioService.durationStream.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });
  }

  Future<void> _loadPlaylist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final userId = appState.user?.id ?? 'guest';
      
      final playlist = await _soundService.getPlaylistForMood(widget.mood, userId);
      
      if (playlist == null || playlist.tracks.isEmpty) {
        setState(() {
          _error = 'No sounds available for this mood';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _playlist = playlist;
        _isLoading = false;
      });

      // Auto-load and play the playlist
      await _audioService.loadPlaylist(playlist);
      await _audioService.play();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load playlist: $e';
        _isLoading = false;
      });
    }
  }

  void _showSleepTimer() {
    showDialog(
      context: context,
      builder: (context) => SleepTimerDialog(
        currentTimer: _audioService.sleepTimer,
        onStart: (duration) => _audioService.startSleepTimer(duration),
        onCancel: () => _audioService.cancelSleepTimer(),
      ),
    );
  }

  String _getMoodDisplayName() {
    switch (widget.mood) {
      case GlowMood.balanced:
        return 'Balanced Mind';
      case GlowMood.anxious:
        return 'Anxiety Relief';
      case GlowMood.burnoutRisk:
        return 'Recovery & Restoration';
    }
  }

  Color _getMoodColor() {
    switch (widget.mood) {
      case GlowMood.balanced:
        return const Color(0xFF8B5CF6); // Purple
      case GlowMood.anxious:
        return const Color(0xFF3B82F6); // Blue
      case GlowMood.burnoutRisk:
        return const Color(0xFF6B7280); // Grey
    }
  }

  @override
  void dispose() {
    // Don't dispose audioService here as it might be used elsewhere
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor();
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1F1B2E),
              const Color(0xFF2D2640),
              moodColor.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Soothing Sounds',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _getMoodDisplayName(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.timer, color: Colors.white),
                      onPressed: _showSleepTimer,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _buildContent(moodColor),
              ),

              // Playback Controls
              if (_playlist != null && !_isLoading)
                _buildPlaybackControls(moodColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color moodColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(moodColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading soothing sounds...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: moodColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_playlist == null || _playlist!.tracks.isEmpty) {
      return const Center(
        child: Text(
          'No sounds available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Playlist view
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _playlist!.tracks.length,
      itemBuilder: (context, index) {
        final track = _playlist!.tracks[index];
        final isCurrentTrack = _currentTrack?.id == track.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrentTrack 
                ? moodColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentTrack 
                  ? moodColor.withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: moodColor.withOpacity(0.2),
                border: Border.all(
                  color: moodColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                isCurrentTrack && _isPlaying 
                    ? Icons.graphic_eq 
                    : Icons.music_note,
                color: moodColor,
              ),
            ),
            title: Text(
              track.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: track.durationSeconds != null
                ? Text(
                    _formatDuration(Duration(seconds: track.durationSeconds!)),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  )
                : null,
            trailing: isCurrentTrack
                ? Icon(Icons.volume_up, color: moodColor, size: 20)
                : null,
            onTap: () async {
              setState(() => _currentTrackIndex = index);
              await _audioService.loadPlaylist(_playlist!, startIndex: index);
              await _audioService.play();
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls(Color moodColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Current track info
          if (_currentTrack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Text(
                    _currentTrack!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: moodColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      thumbColor: moodColor,
                      overlayColor: moodColor.withOpacity(0.3),
                    ),
                    child: Slider(
                      value: _position.inSeconds.toDouble(),
                      max: (_duration?.inSeconds ?? 1).toDouble(),
                      onChanged: (value) {
                        _audioService.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(_duration ?? Duration.zero),
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: _shuffle ? moodColor : Colors.white60,
                ),
                onPressed: () {
                  setState(() => _shuffle = !_shuffle);
                  _audioService.setShuffle(_shuffle);
                },
              ),

              // Previous
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                iconSize: 36,
                onPressed: () => _audioService.previous(),
              ),

              // Play/Pause
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodColor,
                  boxShadow: [
                    BoxShadow(
                      color: moodColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 36,
                  onPressed: () => _audioService.togglePlayPause(),
                ),
              ),

              // Next
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                iconSize: 36,
                onPressed: () => _audioService.next(),
              ),

              // Loop mode
              IconButton(
                icon: Icon(
                  _loopMode == LoopMode.off
                      ? Icons.repeat
                      : _loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                  color: _loopMode == LoopMode.off ? Colors.white60 : moodColor,
                ),
                onPressed: () {
                  _audioService.cycleLoopMode();
                  setState(() => _loopMode = _audioService.loopMode);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
