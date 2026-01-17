import 'package:flutter/material.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/models/mood_playlist.dart';
import 'package:glowmind/services/freesound_service.dart';
import 'package:glowmind/services/audio_player_service.dart';
import 'package:glowmind/theme.dart';

class PlaylistPage extends StatefulWidget {
  final GlowMood mood;
  
  const PlaylistPage({super.key, required this.mood});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final _playlistService = MoodPlaylistService.instance;
  final _freesoundService = FreeSoundService.instance;
  final _audioPlayer = AudioPlayerService.instance;
  
  List<MoodPlaylistItem> _playlist = [];
  final Map<String, FreeSoundTrack?> _loadedTracks = {};
  final Map<String, bool> _loadingStates = {};
  int? _playingIndex;
  
  @override
  void initState() {
    super.initState();
    _loadPlaylist();
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _audioPlayer.stateStream.listen((state) {
      if (mounted) setState(() {});
    });
    
    _audioPlayer.indexStream.listen((index) {
      if (mounted) {
        setState(() {
          _playingIndex = index;
        });
      }
    });
  }

  Future<void> _loadPlaylist() async {
    await _playlistService.loadPlaylists();
    setState(() {
      _playlist = _playlistService.getPlaylistForMood(widget.mood);
    });
  }

  Future<void> _playTrack(int index) async {
    final item = _playlist[index];
    
    // Check if track is already loaded
    if (_loadedTracks.containsKey(item.freesoundId) && _loadedTracks[item.freesoundId] != null) {
      final track = _loadedTracks[item.freesoundId]!;
      await _audioPlayer.playTrack(track.previewUrl, track.name);
      setState(() {
        _playingIndex = index;
      });
      return;
    }
    
    // Load track from FreeSound
    setState(() {
      _loadingStates[item.freesoundId] = true;
    });
    
    final track = await _freesoundService.getSound(item.freesoundId);
    
    setState(() {
      _loadingStates[item.freesoundId] = false;
      _loadedTracks[item.freesoundId] = track;
    });
    
    if (track != null && track.previewUrl.isNotEmpty) {
      await _audioPlayer.playTrack(track.previewUrl, item.name);
      setState(() {
        _playingIndex = index;
      });
    } else {
      _showError('Unable to load sound preview');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  String _formatDuration(dynamic duration) {
    final int minutes;
    final int seconds;
    
    if (duration is int) {
      // Duration in seconds (from playlist metadata)
      minutes = duration ~/ 60;
      seconds = duration % 60;
    } else if (duration is Duration) {
      // Duration object (from audio player)
      minutes = duration.inMinutes;
      seconds = duration.inSeconds % 60;
    } else {
      return '0:00';
    }
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getMoodColor() {
    switch (widget.mood) {
      case GlowMood.balanced:
        return AppGlowColors.purple;
      case GlowMood.anxious:
        return AppGlowColors.blueAccent;
      case GlowMood.burnoutRisk:
        return AppGlowColors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(moodColor),
              Expanded(
                child: _playlist.isEmpty
                    ? _buildLoadingState()
                    : _buildPlaylist(moodColor),
              ),
              if (_audioPlayer.state != PlayerState.stopped)
                _buildBottomPlayer(moodColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Color moodColor) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: moodColor.withOpacity(0.2),
                border: Border.all(color: moodColor.withOpacity(0.5)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MoodPlaylistService.getMoodDisplayName(widget.mood),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: moodColor.withOpacity(0.5), blurRadius: 10),
                    ],
                  ),
                ),
                Text(
                  '${_playlist.length} soothing sounds',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _getMoodColor()),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading playlist...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist(Color moodColor) {
    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: _playlist.length,
      itemBuilder: (context, index) {
        return _buildTrackCard(_playlist[index], index, moodColor);
      },
    );
  }

  Widget _buildTrackCard(MoodPlaylistItem item, int index, Color moodColor) {
    final isPlaying = _playingIndex == index && _audioPlayer.isPlaying;
    final isPaused = _playingIndex == index && _audioPlayer.isPaused;
    final isLoading = _loadingStates[item.freesoundId] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          colors: isPlaying
              ? [moodColor.withOpacity(0.3), moodColor.withOpacity(0.1)]
              : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
        ),
        border: Border.all(
          color: isPlaying ? moodColor.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: isPlaying ? 2 : 1,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: moodColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: isLoading ? null : () => _handleTrackTap(index),
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Row(
              children: [
                _buildPlayButton(isPlaying, isPaused, isLoading, moodColor),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(item.duration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: moodColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton(bool isPlaying, bool isPaused, bool isLoading, Color moodColor) {
    if (isLoading) {
      return SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          color: moodColor,
          strokeWidth: 2,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isPlaying
              ? [moodColor, moodColor.withOpacity(0.7)]
              : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: moodColor.withOpacity(0.5),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Future<void> _handleTrackTap(int index) async {
    if (_playingIndex == index) {
      // Toggle play/pause
      if (_audioPlayer.isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } else {
      // Play new track
      await _playTrack(index);
    }
  }

  Widget _buildBottomPlayer(Color moodColor) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _audioPlayer.currentTrackName ?? 'No track playing',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        return Text(
                          _formatDuration(position),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildControlButton(
                icon: _audioPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
                onTap: () async {
                  if (_audioPlayer.isPlaying) {
                    await _audioPlayer.pause();
                  } else {
                    await _audioPlayer.resume();
                  }
                  setState(() {});
                },
                color: moodColor,
                isPrimary: true,
              ),
              _buildControlButton(
                icon: Icons.stop,
                onTap: () async {
                  await _audioPlayer.stop();
                  setState(() {
                    _playingIndex = null;
                  });
                },
                color: Colors.white54,
              ),
              _buildControlButton(
                icon: _getLoopIcon(),
                onTap: _cyclePlaybackMode,
                color: _audioPlayer.mode != PlaybackMode.single ? moodColor : Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<Duration>(
            stream: _audioPlayer.positionStream,
            builder: (context, posSnapshot) {
              return StreamBuilder<Duration>(
                stream: _audioPlayer.durationStream,
                builder: (context, durSnapshot) {
                  final position = posSnapshot.data ?? Duration.zero;
                  final duration = durSnapshot.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(moodColor),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isPrimary ? 12 : 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isPrimary ? 24 : 18,
        ),
      ),
    );
  }

  IconData _getLoopIcon() {
    switch (_audioPlayer.mode) {
      case PlaybackMode.single:
        return Icons.repeat;
      case PlaybackMode.loopOne:
        return Icons.repeat_one;
      case PlaybackMode.loopAll:
        return Icons.repeat;
      case PlaybackMode.shuffle:
        return Icons.shuffle;
    }
  }

  void _cyclePlaybackMode() {
    final modes = PlaybackMode.values;
    final currentIndex = modes.indexOf(_audioPlayer.mode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    _audioPlayer.setPlaybackMode(nextMode);
    setState(() {});

    // Show snackbar with mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playback mode: ${_getModeName(nextMode)}'),
        duration: const Duration(seconds: 1),
        backgroundColor: _getMoodColor().withOpacity(0.8),
      ),
    );
  }

  String _getModeName(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.single:
        return 'Play once';
      case PlaybackMode.loopOne:
        return 'Loop track';
      case PlaybackMode.loopAll:
        return 'Loop all';
      case PlaybackMode.shuffle:
        return 'Shuffle';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
