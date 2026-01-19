import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/affirmation.dart';
import '../../state/affirmation_state.dart';
import '../../state/music_state.dart';
import '../../theme.dart';
import 'affirmation_card.dart';
import 'affirmation_settings_page.dart';
import 'record_affirmation_page.dart';

class AffirmationsPage extends StatefulWidget {
  const AffirmationsPage({super.key});

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _favoritesPageController;
  late AnimationController _breatheController;
  late AnimationController _shimmerController;
  int _currentFavoriteIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesPageController = PageController(viewportFraction: 0.88);
    
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AffirmationState>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _favoritesPageController.dispose();
    _breatheController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D), Color(0xFF0F0720)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ..._buildParticles(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTabBar(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(15, (index) {
      final random = math.Random(index);
      return Positioned(
        left: random.nextDouble() * MediaQuery.of(context).size.width,
        top: random.nextDouble() * MediaQuery.of(context).size.height,
        child: AnimatedBuilder(
          animation: _breatheController,
          builder: (context, child) {
            return Opacity(
              opacity: 0.1 + (_breatheController.value * 0.2),
              child: Container(
                width: 4 + random.nextDouble() * 6,
                height: 4 + random.nextDouble() * 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFF8B5CF6),
                    const Color(0xFFEC4899),
                    random.nextDouble(),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF59E0B)],
                ).createShader(bounds),
                child: const Text(
                  "Affirmations",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Speak your truth into existence ✨",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.tune_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AffirmationSettingsPage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        tabs: const [
          Tab(text: "Today"),
          Tab(text: "Favorites"),
          Tab(text: "My Voice"),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Consumer<AffirmationState>(
      builder: (context, state, _) {
        if (state.isLoading && state.affirmations.isEmpty) {
          return _buildLoadingState();
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(state),
            _buildFavoritesTab(state),
            _buildVoiceTab(state),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breatheController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (_breatheController.value * 0.2),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: _breatheController.value * 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            "Preparing your affirmations...",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab(AffirmationState state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Daily affirmation card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: state.dailyAffirmation != null
                ? AffirmationCard(
                    affirmation: state.dailyAffirmation!,
                    isLarge: true,
                    breatheController: _breatheController,
                    onFavorite: () => state.toggleFavorite(state.dailyAffirmation!),
                    onShare: () => _shareAffirmation(state.dailyAffirmation!),
                  )
                : _buildGeneratePrompt(),
          ),
          const SizedBox(height: 32),
          
          // Category quick picks
          _buildCategorySection(state),
          const SizedBox(height: 24),
          
          // Recent affirmations
          if (state.affirmations.isNotEmpty) _buildRecentSection(state),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGeneratePrompt() {
    return AnimatedBuilder(
      animation: _breatheController,
      builder: (context, child) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C3AED).withValues(alpha: 0.3),
                const Color(0xFF4F46E5).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.3 + _breatheController.value * 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: _breatheController.value * 5,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Ready for today's affirmation?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Personalized based on your mood journey",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _generateAffirmation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Generate",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(AffirmationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            "Quick Affirmation",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: AffirmationCategory.values.length,
            itemBuilder: (context, index) {
              final category = AffirmationCategory.values[index];
              return _buildCategoryChip(category, state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(AffirmationCategory category, AffirmationState state) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final affirmation = await state.generateForCategory(category);
        if (mounted) {
          _showAffirmationSnackbar(affirmation);
        }
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              category.color.withValues(alpha: 0.3),
              category.color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: category.color.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.displayName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(AffirmationState state) {
    final recentAffirmations = state.affirmations.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${state.affirmations.length} total",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: recentAffirmations.length,
            itemBuilder: (context, index) {
              return _buildMiniCard(recentAffirmations[index], state);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(Affirmation affirmation, AffirmationState state) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F1635).withValues(alpha: 0.9),
            const Color(0xFF140F28).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: affirmation.category.color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: affirmation.category.color.withValues(alpha: 0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: affirmation.category.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  affirmation.category.icon,
                  color: affirmation.category.color,
                  size: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => state.toggleFavorite(affirmation),
                child: Icon(
                  affirmation.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: affirmation.isFavorite
                      ? const Color(0xFFEC4899)
                      : Colors.white38,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              affirmation.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatDate(affirmation.createdAt),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(AffirmationState state) {
    if (state.favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: "No favorites yet",
        subtitle: "Tap ♡ on affirmations you love",
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _favoritesPageController,
            itemCount: state.favorites.length,
            onPageChanged: (index) => setState(() => _currentFavoriteIndex = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                child: AffirmationCard(
                  affirmation: state.favorites[index],
                  isLarge: true,
                  breatheController: _breatheController,
                  onFavorite: () => state.toggleFavorite(state.favorites[index]),
                  onShare: () => _shareAffirmation(state.favorites[index]),
                ),
              );
            },
          ),
        ),
        // Page indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              state.favorites.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentFavoriteIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentFavoriteIndex == index
                      ? const Color(0xFF8B5CF6)
                      : Colors.white24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceTab(AffirmationState state) {
    if (state.voiceAffirmations.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEmptyState(
            icon: Icons.mic_none,
            title: "Record your own affirmations",
            subtitle: "Hearing your own voice is powerful",
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _openRecordingPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Record Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: state.voiceAffirmations.length,
      itemBuilder: (context, index) {
        return _buildVoiceItem(state.voiceAffirmations[index], state);
      },
    );
  }

  Widget _buildVoiceItem(Affirmation affirmation, AffirmationState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F1635).withValues(alpha: 0.9),
            const Color(0xFF140F28).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (affirmation.audioPath != null) {
                HapticFeedback.lightImpact();
                state.playAffirmation(affirmation.audioPath!);
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  affirmation.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      affirmation.category.icon,
                      color: affirmation.category.color,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(affirmation.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(affirmation, state),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 56,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (_tabController.index == 2) {
          _openRecordingPage();
        } else {
          _generateAffirmation();
        }
      },
      child: AnimatedBuilder(
        animation: _breatheController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                  blurRadius: 25 + (_breatheController.value * 10),
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _tabController.index == 2 ? Icons.mic_rounded : Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _tabController.index == 2 ? "Record" : "New Affirmation",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _generateAffirmation() async {
    HapticFeedback.mediumImpact();
    final musicState = context.read<MusicState>();
    final moodCounts = musicState.getMoodCounts(daysBack: 30);
    final currentMood = musicState.currentMood.name;

    await context.read<AffirmationState>().generateNewAffirmation(
          moodCounts: moodCounts,
          currentMood: currentMood,
        );
  }

  void _openRecordingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordAffirmationPage()),
    );
  }

  void _shareAffirmation(Affirmation affirmation) {
    HapticFeedback.lightImpact();
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Share feature coming soon!"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAffirmationSnackbar(Affirmation affirmation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${affirmation.text}"',
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        backgroundColor: affirmation.category.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _confirmDelete(Affirmation affirmation, AffirmationState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Recording?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              state.deleteAffirmation(affirmation);
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.day}/${date.month}";
  }
}
