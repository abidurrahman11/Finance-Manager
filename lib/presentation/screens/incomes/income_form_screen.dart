import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/models/income_model.dart';

/// Add or edit an income entry.
///
/// Mirrors [ExpenseFormScreen] in layout and behaviour:
/// - A coloured group context banner is shown when [group] is non-null.
/// - Category is selected via a Wrap of chip buttons (not a dropdown).
/// - On save, the appropriate provider is invalidated so the group detail
///   screen refreshes immediately without a manual pull-to-refresh.
class IncomeFormScreen extends ConsumerStatefulWidget {
  final IncomeModel? income;
  final IncomeGroupModel? group;

  const IncomeFormScreen({super.key, this.income, this.group});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCategory = AppConstants.incomeCategories.first;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final inc = widget.income!;
      _titleCtrl.text = inc.title;
      _amountCtrl.text = inc.amount.toString();
      _notesCtrl.text = inc.notes ?? '';
      _selectedCategory = inc.category;
      _selectedDate = inc.incomeDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.income),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// Invalidates the group incomes provider that corresponds to the income
  /// being edited or the group being added to.
  ///
  /// Called after every successful save so the group detail screen
  /// immediately reflects the change.
  void _invalidateGroupIncomes(int groupId, bool isRemote) {
    if (isRemote) {
      ref.invalidate(remoteGroupIncomesProvider(groupId));
    } else {
      ref.invalidate(localGroupIncomesProvider(groupId));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final title = _titleCtrl.text.trim();
    final amount = double.parse(_amountCtrl.text);
    final notes =
        _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null;

    bool ok;

    if (_isEditing) {
      // ── Edit existing income ──────────────────────────────────────
      //
      // Pass incomeGroupId from the existing model so the repo preserves
      // group membership. Without this the UPDATE would clear income_group_id,
      // causing the income to vanish from the group list on next refresh.
      final existingGroupId = widget.income!.incomeGroupId;

      ok = await ref.read(incomesProvider.notifier).update(
            widget.income!.id,
            title: title,
            amount: amount,
            category: _selectedCategory,
            incomeDate: _selectedDate,
            notes: notes,
            incomeGroupId: existingGroupId,
            isRemote: widget.income!.isRemote,
          );

      // Invalidate the group list so the caller screen refreshes on pop.
      if (ok && existingGroupId != null) {
        _invalidateGroupIncomes(existingGroupId, widget.income!.isRemote);
      }

      // Also refresh personal list when it was a personal income.
      if (ok && existingGroupId == null) {
        ref.read(personalIncomesProvider.notifier).loadInitial();
      }
    } else if (widget.group?.isRemote == true) {
      // ── New income in a collaborative (remote) group ──────────────
      try {
        await ref.read(remoteIncomeRepositoryProvider).createIncome(
              title: title,
              amount: amount,
              category: _selectedCategory,
              incomeDate: _selectedDate,
              notes: notes,
              incomeGroupId: widget.group!.id,
            );
        _invalidateGroupIncomes(widget.group!.id, true);
        ok = true;
      } catch (_) {
        ok = false;
      }
    } else {
      // ── New personal or local-group income ────────────────────────
      ok = await ref.read(incomesProvider.notifier).create(
            title: title,
            amount: amount,
            category: _selectedCategory,
            incomeDate: _selectedDate,
            notes: notes,
            incomeGroupId: widget.group?.id,
          );

      if (ok) {
        if (widget.group == null) {
          ref.read(personalIncomesProvider.notifier).loadInitial();
        } else {
          _invalidateGroupIncomes(widget.group!.id, false);
        }
      }
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Income updated' : 'Income added'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Income' : 'New Income'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Group context banner ──────────────────────────────
              if (widget.group != null) ...[
                _GroupBanner(group: widget.group!),
                const SizedBox(height: 20),
              ],

              // ── Title ─────────────────────────────────────────────
              AppTextField(
                label: 'Title',
                hint: 'e.g. Monthly salary',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Amount ────────────────────────────────────────────
              AppTextField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    '\$',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null)
                    return 'Enter a valid number';
                  if (double.parse(v) <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Category picker (chips, matching expense pattern) ──
              const _FieldLabel(label: 'Category'),
              const SizedBox(height: 8),
              _CategoryPicker(
                selected: _selectedCategory,
                onChanged: (cat) =>
                    setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 16),

              // ── Date ──────────────────────────────────────────────
              AppTextField(
                label: 'Date',
                controller: TextEditingController(
                  text: DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
                readOnly: true,
                onTap: _pickDate,
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 16),

              // ── Notes ─────────────────────────────────────────────
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Any additional details...',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              AppButton(
                label: _isEditing ? 'Update Income' : 'Add Income',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.save : Icons.add,
                color: AppTheme.income,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Group context banner ─────────────────────────────────────────────────────

class _GroupBanner extends StatelessWidget {
  final IncomeGroupModel group;
  const _GroupBanner({required this.group});

  @override
  Widget build(BuildContext context) {
    final color = group.isRemote ? AppTheme.primary : AppTheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            group.isRemote ? Icons.cloud_outlined : Icons.folder_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adding to group',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  group.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              group.isRemote ? 'Collaborative' : 'Offline',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category picker (chip grid) ─────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.incomeCategories.map((cat) {
        final isSelected = cat == selected;
        final icon = CategoryUtils.getIncomeIcon(cat);
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.income.withValues(alpha: 0.15)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? AppTheme.income : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? AppTheme.income
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.income
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
