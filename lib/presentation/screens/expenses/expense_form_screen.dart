import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/expense_model.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  final int? groupId;

  const ExpenseFormScreen({super.key, this.expense, this.groupId});

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool ok;
    if (_isEditing) {
      ok = await ref.read(expensesProvider.notifier).update(
            widget.expense!.id,
            title: _titleCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text),
            category: _selectedCategory,
            expenseDate: _selectedDate,
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
            imagePath: _imagePath,
          );
    } else {
      ok = await ref.read(expensesProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text),
            category: _selectedCategory,
            expenseDate: _selectedDate,
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
            expenseGroupId: widget.groupId,
            imagePath: _imagePath,
          );
    }

    setState(() => _isLoading = false);
    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Expense updated' : 'Expense added'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: AppTheme.error),
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
              AppTextField(
                label: 'Title',
                hint: 'e.g. Grocery shopping',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Amount',
                hint: '0.00',
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('\$',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter valid amount';
                  if (double.parse(v) <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceVariant,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: AppConstants.expenseCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Date picker
              AppTextField(
                label: 'Date',
                controller: TextEditingController(
                    text: DateFormat('MMM d, yyyy').format(_selectedDate)),
                readOnly: true,
                onTap: _pickDate,
                prefixIcon: const Icon(Icons.calendar_today_outlined,
                    color: AppTheme.textSecondary, size: 18),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Any additional details...',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _imagePath != null
                            ? AppTheme.success
                            : AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          _imagePath != null
                              ? Icons.check_circle
                              : Icons.attach_file,
                          color: _imagePath != null
                              ? AppTheme.success
                              : AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                          _imagePath != null ? 'Image selected' : 'Attach receipt (optional)',
                          style: TextStyle(
                              color: _imagePath != null
                                  ? AppTheme.success
                                  : AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
