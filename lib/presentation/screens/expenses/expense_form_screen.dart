import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/category_utils.dart';
import '../../../data/models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';

/// Add or edit an expense.
///
/// Always receives a typed [ExpenseGroupModel?] via the router's extra — never
/// a raw int. When [group] is non-null a coloured context banner is shown so
/// the user always knows which group they are saving into.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  final ExpenseGroupModel? group;

  const ExpenseFormScreen({super.key, this.expense, this.group});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _selectedCategory = AppConstants.expenseCategories.first;
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  bool _isLoading = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.expense!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toString();
      _notesCtrl.text = e.notes ?? '';
      _selectedCategory = e.category;
      _selectedDate = e.expenseDate;
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
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _imagePath = file.path);
  }

  /// Invalidates the group expenses provider that corresponds to the
  /// expense being edited or the group being added to.
  ///
  /// Called after every successful save so the group detail screen
  /// immediately reflects the change without requiring a manual refresh.
  void _invalidateGroupExpenses(int groupId, bool isRemote) {
    if (isRemote) {
      ref.invalidate(remoteGroupExpensesProvider(groupId));
    } else {
      ref.invalidate(localGroupExpensesProvider(groupId));
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
      // ── Edit existing expense ─────────────────────────────────────
      //
      // CRITICAL: pass expenseGroupId from the existing expense model so
      // the repository preserves group membership. Without this the repo
      // receives null and the UPDATE would clear expense_group_id, causing
      // the expense to vanish from the group's list on next refresh.
      final existingGroupId = widget.expense!.expenseGroupId;

      ok = await ref.read(expensesProvider.notifier).update(
            widget.expense!.id,
            title: title,
            amount: amount,
            category: _selectedCategory,
            expenseDate: _selectedDate,
            notes: notes,
            imagePath: _imagePath,
            isRemote: widget.expense!.isRemote,
            expenseGroupId: existingGroupId, // ← preserve group membership
          );

      // Invalidate the group list so the caller screen refreshes on pop.
      if (ok && existingGroupId != null) {
        _invalidateGroupExpenses(existingGroupId, widget.expense!.isRemote);
      }

      // Also refresh personal list when it was a personal expense.
      if (ok && existingGroupId == null) {
        ref.read(personalExpensesProvider.notifier).loadInitial();
      }
    } else if (widget.group?.isRemote == true) {
      // ── New expense in a collaborative (remote) group ─────────────
      try {
        await ref.read(remoteExpenseRepositoryProvider).createExpense(
              title: title,
              amount: amount,
              category: _selectedCategory,
              expenseDate: _selectedDate,
              notes: notes,
              expenseGroupId: widget.group!.id,
            );
        _invalidateGroupExpenses(widget.group!.id, true);
        ok = true;
      } catch (_) {
        ok = false;
      }
    } else {
      // ── New personal or local-group expense ───────────────────────
      ok = await ref.read(expensesProvider.notifier).create(
            title: title,
            amount: amount,
            category: _selectedCategory,
            expenseDate: _selectedDate,
            notes: notes,
            expenseGroupId: widget.group?.id,
            imagePath: _imagePath,
          );

      if (ok) {
        if (widget.group == null) {
          ref.read(personalExpensesProvider.notifier).loadInitial();
        } else {
          _invalidateGroupExpenses(widget.group!.id, false);
        }
      }
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Expense updated' : 'Expense added'),
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
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
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
                hint: 'e.g. Grocery shopping',
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
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  if (double.parse(v) <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Category picker ───────────────────────────────────
              const _FieldLabel(label: 'Category'),
              const SizedBox(height: 8),
              _CategoryPicker(
                selected: _selectedCategory,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
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
              const SizedBox(height: 16),

              // ── Receipt ───────────────────────────────────────────
              _ReceiptPicker(
                imagePath: _imagePath,
                onPick: _pickImage,
                onRemove: () => setState(() => _imagePath = null),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              AppButton(
                label: _isEditing ? 'Update Expense' : 'Add Expense',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: _isEditing ? Icons.save : Icons.add,
                color: AppTheme.expense,
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
  final ExpenseGroupModel group;
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

// ─── Category picker ──────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.expenseCategories.map((cat) {
        final isSelected = cat == selected;
        final icon = CategoryUtils.getExpenseIcon(cat);
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.expense.withValues(alpha: 0.15)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? AppTheme.expense : Colors.transparent,
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
                      ? AppTheme.expense
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
                        ? AppTheme.expense
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

// ─── Receipt picker ───────────────────────────────────────────────────────────

class _ReceiptPicker extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ReceiptPicker({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: imagePath == null ? onPick : null,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imagePath != null ? AppTheme.success : AppTheme.divider,
          ),
        ),
        child: imagePath == null
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_file,
                      color: AppTheme.textSecondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Attach receipt (optional)',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Receipt attached',
                    style: TextStyle(color: AppTheme.success),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        color: AppTheme.textSecondary, size: 18),
                  ),
                ],
              ),
      ),
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
