import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Horizontal scrolling category filter chip row.
/// Used in PersonalExpensesScreen and GroupDetailScreen (Expenses tab).
class ExpenseFilterChips extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const ExpenseFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            selected: selectedCategory == null,
            onTap: () => onCategoryChanged(null),
          ),
          ...AppConstants.expenseCategories.map(
            (cat) => _Chip(
              label: cat,
              selected: selectedCategory == cat,
              onTap: () => onCategoryChanged(cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.expense : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
