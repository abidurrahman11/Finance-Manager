import 'package:flutter/material.dart';
import '../common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/models/income_model.dart';

/// An expandable list tile that shows a single [IncomeModel].
///
/// Mirrors [ExpenseListTile] exactly — tapping toggles an expanded section
/// with full notes and edit/delete actions. Amount is shown in [AppTheme.income]
/// green to distinguish income tiles at a glance.
class IncomeListTile extends StatefulWidget {
  final IncomeModel income;
  final int colorIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IncomeListTile({
    super.key,
    required this.income,
    required this.colorIndex,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<IncomeListTile> createState() => _IncomeListTileState();
}

class _IncomeListTileState extends State<IncomeListTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme
        .categoryColors[widget.colorIndex % AppTheme.categoryColors.length];
    final categoryIcon = CategoryUtils.getIncomeIcon(widget.income.category);

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // ── Collapsed row ─────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.income.title,
                        maxLines: _isExpanded ? null : 1,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          CategoryBadge(
                            category: widget.income.category,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormatter.formatDate(widget.income.incomeDate),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (!_isExpanded &&
                          widget.income.notes != null &&
                          widget.income.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.income.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${CurrencyFormatter.format(widget.income.amount)}',
                      style: const TextStyle(
                        color: AppTheme.income,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),

            // ── Expanded section ──────────────────────────────────
            if (_isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),

              if (widget.income.notes != null &&
                  widget.income.notes!.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.income.notes!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
