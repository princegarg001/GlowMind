import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/services/freesound_service.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:provider/provider.dart';

/// Playlist manager page accessible via right swipe from mood pages
class PlaylistManagerPage extends StatefulWidget {
  const PlaylistManagerPage({super.key});

  @override
  State<PlaylistManagerPage> createState() => _PlaylistManagerPageState();
}

class _PlaylistManagerPageState extends State<PlaylistManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F3D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Playlists',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Now Playing'),
            Tab(text: 'All Playlists'),
            Tab(text: 'Surprise Me'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NowPlayingTab(),
          _AllPlaylistsTab(),
          _SurpriseMeTab(),
        ],
      ),
    );
  }
}

/// Now Playing tab - shows current queue
class _NowPlayingTab extends StatelessWidget {
  const _NowPlayingTab();

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final playlist = musicState.currentPlaylist;
    final currentTrack = musicState.currentTrack;

    if (playlist == null || playlist.tracks.isEmpty) {
      return const Center(
        child: Text(
          'No playlist loaded',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current playlist info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playlist.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${playlist.tracks.length} tracks',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Track list
        ...playlist.tracks.asMap().entries.map((entry) {
          final index = entry.key;
          final track = entry.value;
          final isCurrent = track.id == currentTrack?.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withOpacity(0.1),
                ),
                child: Center(
                  child: isCurrent
                      ? const Icon(Icons.music_note, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              title: Text(
                track.name,
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white70,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: track.attribution != null
                  ? Text(
                      track.attribution!,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: isCurrent
                  ? const Icon(Icons.equalizer, color: Colors.white)
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

/// All Playlists tab - browse and edit playlists
class _AllPlaylistsTab extends StatelessWidget {
  const _AllPlaylistsTab();

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final playlists = musicState.getCurrentMoodPlaylists();

    if (playlists.isEmpty) {
      return const Center(
        child: Text(
          'No playlists available',
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: playlist.isDefault
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.queue_music, color: Colors.white),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (playlist.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${playlist.tracks.length} tracks',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
            onTap: () {
              musicState.playPlaylist(playlist);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

/// Surprise Me tab - auto-generate playlist
class _SurpriseMeTab extends StatefulWidget {
  const _SurpriseMeTab();

  @override
  State<_SurpriseMeTab> createState() => _SurpriseMeTabState();
}

class _SurpriseMeTabState extends State<_SurpriseMeTab> {
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _error;
  Playlist? _generatedPlaylist;

  Future<void> _generatePlaylist(BuildContext context) async {
    final musicState = context.read<MusicState>();
    final appState = context.read<AppState>();
    final userId = appState.user?.id ?? 'guest';

    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedPlaylist = null;
    });

    try {
      final freesound = FreesoundService();
      // Use random playlist generation instead of mood-based
      final playlist = await freesound.createRandomPlaylist(
        userId,
        trackCount: 10,
      );

      if (playlist.tracks.isEmpty) {
        throw Exception('No sounds found. Please try again.');
      }

      if (!mounted) return;
      setState(() {
        _generatedPlaylist = playlist;
      });
      
      await musicState.playPlaylist(playlist);
    } catch (e) {
      debugPrint('Error generating playlist: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().contains('Exception: ') 
            ? e.toString().split('Exception: ')[1] 
            : 'Failed to generate playlist. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _savePlaylist(BuildContext context) async {
    if (_generatedPlaylist == null) return;
    
    final musicState = context.read<MusicState>();
    
    if (!mounted) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await musicState.addPlaylist(_generatedPlaylist!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "${_generatedPlaylist!.name}" to your playlists'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving playlist: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save playlist. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: _isGenerating
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 32),
            const Text(
              'Surprise Me!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _generatedPlaylist != null
                  ? 'Playing "${_generatedPlaylist!.name}" with ${_generatedPlaylist!.tracks.length} tracks'
                  : 'Generate a unique surprise playlist from Freesound',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: scheme.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            
            // Generate button
            ElevatedButton(
              onPressed: (_isGenerating || _isSaving) ? null : () => _generatePlaylist(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                _isGenerating 
                    ? 'Generating...' 
                    : _generatedPlaylist != null 
                        ? 'Generate New' 
                        : 'Generate Playlist',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            // Save button (shown after generation)
            if (_generatedPlaylist != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => _savePlaylist(context),
                icon: _isSaving 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save to My Playlists',
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: scheme.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
