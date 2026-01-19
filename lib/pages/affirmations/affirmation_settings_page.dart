import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/affirmation.dart';
import '../../state/affirmation_state.dart';
import '../../theme.dart';

class AffirmationSettingsPage extends StatefulWidget {
  const AffirmationSettingsPage({super.key});

  @override
  State<AffirmationSettingsPage> createState() => _AffirmationSettingsPageState();
}

class _AffirmationSettingsPageState extends State<AffirmationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B061A), Color(0xFF1A0F3D), Color(0xFF0F0720)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<AffirmationState>(
                  builder: (context, state, _) {
                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildNotificationSection(state),
                        const SizedBox(height: 28),
                        _buildCategoriesSection(state),
                        const SizedBox(height: 28),
                        _buildDataSection(state),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Customize your affirmation experience",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.close, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(AffirmationState state) {
    return _buildSection(
      title: "Reminders",
      icon: Icons.notifications_outlined,
      children: [
        _buildNotificationTile(
          title: "Morning Affirmation",
          subtitle: "Start your day with positivity",
          icon: Icons.wb_sunny_outlined,
          iconColor: const Color(0xFFF59E0B),
          isEnabled: state.settings.morningNotifications,
          time: state.settings.morningTime,
          onToggle: (value) {
            HapticFeedback.lightImpact();
            state.updateSettings(morningNotifications: value);
          },
          onTimeTap: () => _showTimePicker(
            context,
            state.settings.morningTime,
            (time) => state.updateSettings(morningTime: time),
          ),
        ),
        const SizedBox(height: 16),
        _buildNotificationTile(
          title: "Evening Reflection",
          subtitle: "End your day with gratitude",
          icon: Icons.nightlight_outlined,
          iconColor: const Color(0xFF8B5CF6),
          isEnabled: state.settings.eveningNotifications,
          time: state.settings.eveningTime,
          onToggle: (value) {
            HapticFeedback.lightImpact();
            state.updateSettings(eveningNotifications: value);
          },
          onTimeTap: () => _showTimePicker(
            context,
            state.settings.eveningTime,
            (time) => state.updateSettings(eveningTime: time),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(AffirmationState state) {
    return _buildSection(
      title: "Preferred Categories",
      icon: Icons.category_outlined,
      children: [
        Text(
          "Select categories you'd like to focus on",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AffirmationCategory.values.map((category) {
            final isSelected = state.settings.preferredCategories.contains(category);
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                final categories = List<AffirmationCategory>.from(
                  state.settings.preferredCategories,
                );
                if (isSelected) {
                  categories.remove(category);
                } else {
                  categories.add(category);
                }
                state.updateSettings(preferredCategories: categories);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            category.color,
                            category.color.withValues(alpha: 0.7),
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : category.color.withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: category.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected ? Colors.white : category.color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.displayName,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.8),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check, color: Colors.white, size: 16),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataSection(AffirmationState state) {
    return _buildSection(
      title: "Data & Privacy",
      icon: Icons.shield_outlined,
      children: [
        _buildActionTile(
          title: "Export Affirmations",
          subtitle: "Save your collection to a file",
          icon: Icons.download_outlined,
          iconColor: const Color(0xFF10B981),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Export feature coming soon!"),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          title: "Clear All Data",
          subtitle: "Delete all affirmations and recordings",
          icon: Icons.delete_outline,
          iconColor: const Color(0xFFEF4444),
          onTap: () => _showClearDataDialog(state),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
    required TimeOfDay time,
    required Function(bool) onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? iconColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: iconColor,
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      color: iconColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    TimeOfDay currentTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              surface: Color(0xFF1A0F3D),
            ),
            dialogBackgroundColor: const Color(0xFF0F0720),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      HapticFeedback.lightImpact();
      onTimeSelected(time);
    }
  }

  void _showClearDataDialog(AffirmationState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text(
              "Clear All Data?",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          "This will permanently delete all your affirmations, favorites, and voice recordings. This action cannot be undone.",
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
              HapticFeedback.heavyImpact();
              state.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("All data cleared"),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text(
              "Delete All",
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }
}
