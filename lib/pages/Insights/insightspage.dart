import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';
import 'package:glowmind/state/music_state.dart';
import 'package:glowmind/theme.dart';
import 'package:provider/provider.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _range = 0; // 0=Day, 1=Week, 2=Month
  bool _isLoading = true;
  int _currentStreak = 0;
  Map<String, int> _moodDurations = {};

  int get _daysBack {
    switch (_range) {
      case 0:
        return 1;
      case 1:
        return 7;
      case 2:
        return 30;
      default:
        return 7;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load mood history immediately when page opens
    _loadInsightsData();
  }

  Future<void> _loadInsightsData() async {
    setState(() => _isLoading = true);

    try {
      final musicState = context.read<MusicState>();
      await musicState.loadMoodHistory();

      // Load additional stats
      final streak = await musicState.getCurrentStreak();
      final durations = await musicState.getMoodDurations(daysBack: _daysBack);

      if (mounted) {
        setState(() {
          _currentStreak = streak;
          _moodDurations = durations;
        });
      }
    } catch (e) {
      debugPrint('InsightsPage: Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Mood History',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear all your mood history? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final musicState = context.read<MusicState>();
      await musicState.clearMoodHistory();
      await _loadInsightsData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Mood history cleared'),
            backgroundColor: const Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _onRangeChanged(int newRange) {
    if (_range != newRange) {
      setState(() {
        _range = newRange;
      });
      // Reload durations for new time range
      _loadDurations();
    }
  }

  Future<void> _loadDurations() async {
    try {
      final musicState = context.read<MusicState>();
      final durations = await musicState.getMoodDurations(daysBack: _daysBack);
      if (mounted) {
        setState(() {
          _moodDurations = durations;
        });
      }
    } catch (e) {
      debugPrint('Error loading durations: $e');
    }
  }

  List<FlSpot> _getGlowData(List<Map<String, dynamic>> moodTrend) {
    if (moodTrend.isEmpty) {
      // Return dummy data if no history
      return List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    }
    return moodTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble());
    }).toList();
  }

  String _getMostFrequentMood(Map<String, int> moodCounts) {
    if (moodCounts.isEmpty) return 'None';
    final sorted = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final moodName = sorted.first.key;
    // Convert enum name to display name
    try {
      final mood = MoodType.values.firstWhere((m) => m.name == moodName);
      return mood.displayName;
    } catch (_) {
      return moodName;
    }
  }

  double _getMoodBalance(Map<String, int> moodCounts) {
    if (moodCounts.isEmpty) return 0.5;
    final total = moodCounts.values.reduce((a, b) => a + b);
    if (total == 0) return 0.5;

    // Calculate balance based on variety of moods used
    final uniqueMoods = moodCounts.length;
    final maxMoods = MoodType.values.length;
    return uniqueMoods / maxMoods;
  }

  Color _getMoodColor(String moodName) {
    switch (moodName) {
      case 'sleep':
        return const Color(0xFF6366F1);
      case 'study':
        return const Color(0xFF3B82F6);
      case 'party':
        return const Color(0xFFEC4899);
      case 'meditate':
        return const Color(0xFF10B981);
      case 'deepFocus':
        return const Color(0xFF06B6D4);
      case 'nature':
        return const Color(0xFF84CC16);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicState = context.watch<MusicState>();
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).padding.bottom;

    // Get data directly from musicState for reactive updates
    final moodCounts = musicState.getMoodCounts(daysBack: _daysBack);
    final moodTrend =
        musicState.getMoodTrend(days: _daysBack == 1 ? 7 : _daysBack);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF8B5CF6),
                blurRadius: 25,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Back to Home",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading insights...',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInsightsData,
                    color: const Color(0xFF8B5CF6),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: screenHeight - padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _header(),
                            const SizedBox(height: 20),
                            _rangeToggle(),
                            const SizedBox(height: 24),
                            _glowLineChart(moodTrend, moodCounts),
                            const SizedBox(height: 24),
                            _statsRow(moodCounts),
                            const SizedBox(height: 20),
                            _timeSpentCard(),
                            const SizedBox(height: 20),
                            _moodBreakdown(moodCounts),
                            const SizedBox(height: 20),
                            _emotionRhythm(musicState),
                            const SizedBox(height: 80), // space for button
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Insights",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            shadows: [Shadow(color: Color(0xFF8B5CF6), blurRadius: 14)],
          ),
        ),
        Row(
          children: [
            // Streak badge
            if (_currentStreak > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFF6B6B), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$_currentStreak day${_currentStreak > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            // Clear history button
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              tooltip: 'Clear history',
            ),
          ],
        ),
      ],
    );
  }

  Widget _rangeToggle() {
    final labels = ["Day", "Week", "Month"];
    return Row(
      children: List.generate(3, (i) {
        final active = _range == i;
        return GestureDetector(
          onTap: () => _onRangeChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])
                  : null,
              color: active ? null : Colors.white10,
              boxShadow: active
                  ? [const BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 20)]
                  : [],
            ),
            child: Text(labels[i], style: const TextStyle(color: Colors.white)),
          ),
        );
      }),
    );
  }

  Widget _glowLineChart(
      List<Map<String, dynamic>> moodTrend, Map<String, int> moodCounts) {
    final data = _getGlowData(moodTrend);
    final maxY = data.isEmpty
        ? 10.0
        : data.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final totalCount = moodCounts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mood Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Show total count for quick insight
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalCount total',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < moodTrend.length) {
                          final date =
                              moodTrend[value.toInt()]['date'] as DateTime;
                          return Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    barWidth: 4,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          const Color(0xFF4F46E5).withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF8B5CF6),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(Map<String, int> moodCounts) {
    final balance = _getMoodBalance(moodCounts);
    final mostFrequent = _getMostFrequentMood(moodCounts);
    final totalSessions = moodCounts.values.fold(0, (a, b) => a + b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _circleStat("Mood Balance", balance)),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardStyle(),
            child: Column(
              children: [
                Text(
                  '$totalSessions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sessions',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Top: $mostFrequent',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleStat(String title, double value) {
    return Container(
      height: 140,
      decoration: _cardStyle(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 70,
            width: 70,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }

  Widget _timeSpentCard() {
    if (_moodDurations.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSeconds = _moodDurations.values.fold(0, (a, b) => a + b);
    final sortedMoods = _moodDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time Spent',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${_formatDuration(totalSeconds)}',
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedMoods.take(5).map((entry) {
            final percentage =
                totalSeconds > 0 ? entry.value / totalSeconds : 0.0;
            final color = _getMoodColor(entry.key);
            String displayName;
            try {
              final mood =
                  MoodType.values.firstWhere((m) => m.name == entry.key);
              displayName = mood.displayName;
            } catch (_) {
              displayName = entry.key;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    _formatDuration(entry.value),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _moodBreakdown(Map<String, int> moodCounts) {
    if (moodCounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardStyle(),
        child: const Center(
          child: Text(
            'No mood data yet.\nStart exploring moods to see insights!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = moodCounts.values.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedMoods.map((entry) {
            final percentage = total > 0 ? entry.value / total : 0.0;
            final color = _getMoodColor(entry.key);
            String displayName;
            try {
              final mood =
                  MoodType.values.firstWhere((m) => m.name == entry.key);
              displayName = mood.displayName;
            } catch (_) {
              displayName = entry.key;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${entry.value} (${(percentage * 100).toInt()}%)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emotionRhythm(MusicState musicState) {
    final history = musicState.moodHistory;
    final recentHistory =
        history.length > 20 ? history.sublist(history.length - 20) : history;

    if (recentHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Mood Flow',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentHistory.length,
            itemBuilder: (_, i) {
              final entry = recentHistory[i];
              final color = _getMoodColor(entry.mood);
              return Tooltip(
                message: entry.mood,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: color, blurRadius: 10)],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: const Color(0xFF140F28).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF6D4AFF).withValues(alpha: 0.4)),
      boxShadow: const [
        BoxShadow(color: Color(0xFF8B5CF6), blurRadius: 25),
      ],
    );
  }
}
