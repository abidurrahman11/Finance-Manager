import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';

/// A small pill badge that indicates whether an income group is offline or
/// collaborative (online).
///
/// Mirrors [GroupTypeBadge] for expenses — used on [IncomeGroupCard],
/// [IncomeGroupDetailScreen] AppBar, and the income form banner so the user
/// always knows which context they're operating in.
class IncomeGroupTypeBadge extends StatelessWidget {
  final bool isRemote;

  const IncomeGroupTypeBadge({super.key, required this.isRemote});

  @override
  Widget build(BuildContext context) {
    final color = isRemote ? AppTheme.primary : AppTheme.secondary;
    final label = isRemote ? 'Collaborative' : 'Offline';
    final icon = isRemote ? Icons.cloud_outlined : Icons.folder_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
