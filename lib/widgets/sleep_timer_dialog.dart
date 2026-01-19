import 'package:flutter/material.dart';
import 'package:glowmind/models/music_models.dart';

/// Dialog for setting a sleep timer
class SleepTimerDialog extends StatefulWidget {
  final SleepTimer? currentTimer;
  final ValueChanged<Duration>? onStart;
  final VoidCallback? onCancel;
  final bool alarmEnabled;
  final ValueChanged<bool>? onAlarmToggle;

  const SleepTimerDialog({
    super.key,
    this.currentTimer,
    this.onStart,
    this.onCancel,
    this.alarmEnabled = true,
    this.onAlarmToggle,
  });

  @override
  State<SleepTimerDialog> createState() => _SleepTimerDialogState();
}

class _SleepTimerDialogState extends State<SleepTimerDialog> {
  Duration? _selectedDuration;
  bool _showCustomPicker = false;
  int _customMinutes = 30;
  late bool _alarmEnabled;

  @override
  void initState() {
    super.initState();
    _alarmEnabled = widget.alarmEnabled;
  }

  final List<Duration> _presets = [
    const Duration(minutes: 5),
    const Duration(minutes: 10),
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(minutes: 45),
    const Duration(hours: 1),
    const Duration(hours: 2),
  ];

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h';
    } else {
      return '${d.inMinutes}m';
    }
  }

  Widget _buildPresetButton(Duration duration) {
    final isSelected = _selectedDuration == duration;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
          _showCustomPicker = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          _formatDuration(duration),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveTimer = widget.currentTimer != null && !widget.currentTimer!.isExpired;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1F1B2E),
              const Color(0xFF2D2640),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sleep Timer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Active timer display
            if (hasActiveTimer) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final remaining = widget.currentTimer!.remaining;
                        final minutes = remaining.inMinutes.toString().padLeft(2, '0');
                        final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
                        return Text(
                          '$minutes:$seconds',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Timer Active',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  widget.onCancel?.call();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Cancel Timer'),
              ),
            ] else ...[
              // Preset buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _presets.map(_buildPresetButton).toList(),
              ),

              const SizedBox(height: 16),

              // Custom button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCustomPicker = true;
                    _selectedDuration = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _showCustomPicker
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showCustomPicker
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: _showCustomPicker ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),

              // Custom picker
              if (_showCustomPicker) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _customMinutes = (_customMinutes - 5).clamp(5, 180);
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_customMinutes min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _customMinutes = (_customMinutes + 5).clamp(5, 180);
                        });
                      },
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Alarm toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _alarmEnabled
                        ? const Color(0xFFF59E0B).withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _alarmEnabled
                            ? const Color(0xFFF59E0B).withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.alarm,
                        color: _alarmEnabled
                            ? const Color(0xFFF59E0B)
                            : Colors.white54,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wake Alarm',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Play alarm when timer ends',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _alarmEnabled,
                      onChanged: (value) {
                        setState(() => _alarmEnabled = value);
                        widget.onAlarmToggle?.call(value);
                      },
                      activeColor: const Color(0xFFF59E0B),
                      thumbColor: WidgetStateProperty.all(Colors.white),
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Start button
              ElevatedButton(
                onPressed: (_selectedDuration != null || _showCustomPicker)
                    ? () {
                        final duration = _showCustomPicker
                            ? Duration(minutes: _customMinutes)
                            : _selectedDuration!;
                        widget.onStart?.call(duration);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  disabledForegroundColor: Colors.white.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Start Timer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
