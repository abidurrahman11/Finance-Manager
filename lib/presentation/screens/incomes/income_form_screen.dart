import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/income_model.dart';

class IncomeFormScreen extends ConsumerStatefulWidget {
  final IncomeModel? income;
  final int? groupId;
  const IncomeFormScreen({super.key, this.income, this.groupId});

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = AppConstants.incomeCategories.first;
  DateTime _date = DateTime.now();
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
      _category = inc.category;
      _date = inc.incomeDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    bool ok;
    if (_isEditing) {
      ok = await ref.read(incomesProvider.notifier).update(
            widget.income!.id,
            title: _titleCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text),
            category: _category,
            incomeDate: _date,
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          );
    } else {
      ok = await ref.read(incomesProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text),
            category: _category,
            incomeDate: _date,
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
            incomeGroupId: widget.groupId,
          );
    }
    setState(() => _isLoading = false);
    if (ok && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Income updated' : 'Income added'),
          backgroundColor: AppTheme.success));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Something went wrong'),
          backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Income' : 'New Income')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
              label: 'Title',
              hint: 'e.g. Monthly salary',
              controller: _titleCtrl,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Amount',
              hint: '0.00',
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('\$',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount required';
                if (double.tryParse(v) == null) return 'Enter valid amount';
                if (double.parse(v) <= 0) return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceVariant,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: AppConstants.incomeCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Date',
              controller: TextEditingController(
                  text: DateFormat('MMM d, yyyy').format(_date)),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                                primary: AppTheme.income)),
                        child: child!));
                if (picked != null) setState(() => _date = picked);
              },
              prefixIcon: const Icon(Icons.calendar_today_outlined,
                  color: AppTheme.textSecondary, size: 18),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Notes (optional)',
              controller: _notesCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: _isEditing ? 'Update Income' : 'Add Income',
              onPressed: _submit,
              isLoading: _isLoading,
              icon: _isEditing ? Icons.save : Icons.add,
              color: AppTheme.income,
            ),
          ]),
        ),
      ),
    );
  }
}
