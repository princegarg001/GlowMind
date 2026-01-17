import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/theme.dart';
import 'package:glowmind/nav.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/widgets/glow_background.dart';
import 'package:glowmind/widgets/mood_chip.dart';
import 'package:glowmind/widgets/breathing_orb.dart';
import 'package:glowmind/widgets/welcome_overlay.dart';

class GlowHomePage extends StatefulWidget {
  const GlowHomePage({super.key});

  @override
  State<GlowHomePage> createState() => _GlowHomePageState();
}

class _GlowHomePageState extends State<GlowHomePage> with TickerProviderStateMixin {
  bool _showOrb = false;
  bool _ritualMode = false;
  bool _showWelcome = true;
  int _behaviorScore = 50;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _updateBehavior({int delta = 0}) {
    setState(() {
      _behaviorScore = (_behaviorScore + delta).clamp(0, 100);
    });
  }

  Color _stateColor() {
    if (_behaviorScore < 30) return Colors.grey.shade600;
    if (_behaviorScore < 70) return Colors.blue.shade400;
    return const Color(0xFF8B5CF6);
  }

  double _pulseSpeed() {
    if (_behaviorScore < 30) return 0.4;
    if (_behaviorScore < 70) return 0.8;
    return 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final glowColor = _stateColor();

    return Scaffold(
      body: Stack(
        children: [
          GlowBackground(
            glow: app.glow,
            child: const SizedBox.expand(),
          ),

          // Living background pulse
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                return Opacity(
                  opacity: 0.2 + (_pulseCtrl.value * 0.2),
                  child: Container(color: glowColor),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Top bar with Insights button added
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GlowMind',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Color(0xFF8B5CF6), blurRadius: 12)
                              ],
                            ),
                      ),
                      Row(
                        children: [
                          // Glowing Insights Button
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.insights),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.9),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF8B5CF6),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.insights,
                                  color: Colors.white, size: 20),
                            ),
                          ),

                          // Settings Button (unchanged)
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () => context.push(AppRoutes.settings),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Central Glow Orb
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onLongPress: () => setState(() => _showOrb = true),
                        child: AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            return Container(
                              height:
                                  220 + (_pulseCtrl.value * 20 * _pulseSpeed()),
                              width:
                                  220 + (_pulseCtrl.value * 20 * _pulseSpeed()),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: glowColor.withValues(alpha: 0.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(alpha: 0.8),
                                    blurRadius: 80,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Mood chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MoodChip(
                          label: '😌',
                          icon: Icons.circle,
                          onTap: () => _updateBehavior(delta: 15)),
                      const SizedBox(width: 10),
                      MoodChip(
                          label: '🙂',
                          icon: Icons.circle,
                          onTap: () => _updateBehavior(delta: 5)),
                      const SizedBox(width: 10),
                      MoodChip(
                          label: '😔',
                          icon: Icons.circle,
                          onTap: () => _updateBehavior(delta: -20)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Ritual Mode Button
                  GestureDetector(
                    onTap: () => setState(() => _ritualMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
                        boxShadow: [
                          BoxShadow(
                              color: glowColor.withValues(alpha: 0.5), blurRadius: 30),
                        ],
                      ),
                      child: const Text('Start Glow Ritual',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Emotion Timeline
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (_, i) {
                        final c =
                            i.isEven ? const Color(0xFF8B5CF6) : Colors.blueGrey;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 18,
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: c.withValues(alpha: 0.8), blurRadius: 10)
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Healing orb
          if (_showOrb)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: BreathingOrb(
                      onCompleted: () => setState(() => _showOrb = false)),
                ),
              ),
            ),

          // Ritual Mode
          if (_ritualMode)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B061A), Color(0xFF1A0F3D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _ritualMode = false),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        return Container(
                          height: 260 + (_pulseCtrl.value * 40),
                          width: 260 + (_pulseCtrl.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0xFF8B5CF6), blurRadius: 120),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Welcome overlay - shown on first load
          if (_showWelcome)
            Positioned.fill(
              child: WelcomeOverlay(
                onComplete: () => setState(() => _showWelcome = false),
              ),
            ),
        ],
      ),
    );
  }
}
