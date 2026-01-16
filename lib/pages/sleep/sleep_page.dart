import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:glowmind/state/app_state.dart';
import 'package:glowmind/models/models.dart';
import 'package:glowmind/theme.dart';
import 'package:go_router/go_router.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  TimeOfDay _bed = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Sleep', style: Theme.of(context).textTheme.titleLarge?.withColor(scheme.onSurface))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Set your usual times', style: Theme.of(context).textTheme.titleMedium?.withColor(scheme.onSurface)),
          const SizedBox(height: 16),
          _TimeRow(label: 'Bedtime', time: _bed, onPick: (t) => setState(() => _bed = t)),
          const SizedBox(height: 12),
          _TimeRow(label: 'Wake time', time: _wake, onPick: (t) => setState(() => _wake = t)),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              final bedtime = TimeOfDaySimple(hour: _bed.hour, minute: _bed.minute);
              final wakeTime = TimeOfDaySimple(hour: _wake.hour, minute: _wake.minute);
              await context.read<AppState>().setSleepProfile(bedtime, wakeTime);
              if (mounted) context.pop();
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Save'),
          ),
        ]),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label; final TimeOfDay time; final ValueChanged<TimeOfDay> onPick;
  const _TimeRow({required this.label, required this.time, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall?.withColor(scheme.onSurface))),
      OutlinedButton.icon(
        onPressed: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          if (picked != null) onPick(picked);
        },
        icon: Icon(Icons.schedule, color: scheme.primary),
        label: Text(time.format(context), style: Theme.of(context).textTheme.labelLarge?.withColor(scheme.onSurface)),
      ),
    ]);
  }
}
