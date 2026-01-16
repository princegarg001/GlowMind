import 'package:flutter/material.dart';
import 'package:glowmind/theme.dart';

class MoodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const MoodChip({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: scheme.onSurface),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.withColor(scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
