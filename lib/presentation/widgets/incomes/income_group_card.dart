import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/income_model.dart';
import 'income_group_type_badge.dart';

/// A tappable card representing a single [IncomeGroupModel].
///
/// Mirrors [GroupCard] for expenses — shows title, description, date range
/// (if set), type badge, and role. Provides an optional delete action shown
/// as a trailing icon button — only supplied when the current user is the
/// group owner.
class IncomeGroupCard extends StatelessWidget {
  final IncomeGroupModel group;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const IncomeGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (group.isRemote ? AppTheme.primary : AppTheme.secondary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  group.isRemote ? Icons.cloud_outlined : Icons.folder_outlined,
                  color: group.isRemote ? AppTheme.primary : AppTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + role badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!group.isOwner) ...[
                          const SizedBox(width: 6),
                          _RoleBadge(role: group.role),
                        ],
                      ],
                    ),

                    // Description
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        group.description!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Footer row: type badge + optional date range
                    Row(
                      children: [
                        IncomeGroupTypeBadge(isRemote: group.isRemote),
                        if (group.startDate != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            _dateRange(group),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete action (owners only)
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.textSecondary),
                  onPressed: onDelete,
                  splashRadius: 18,
                  tooltip: 'Delete group',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange(IncomeGroupModel g) {
    final start = DateFormatter.formatDate(g.startDate!);
    if (g.endDate == null) return 'From $start';
    return '$start – ${DateFormatter.formatDate(g.endDate!)}';
  }
}

// ─── Role badge ───────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
