import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';

/// Dedicated screen for creating a new expense group.
///
/// Users first pick the group type — offline or collaborative — via two
/// large, clearly-described selector cards, then fill in title, optional
/// description, and optional date range. No dialogs, no toggles buried
/// inside a form. The collaborative card is disabled when the user has no
/// remote session and shows a clear "Sign in required" hint.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // null = no selection yet; false = offline; true = collaborative
  bool? _isRemote;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_isRemote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a group type first'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final title = _titleCtrl.text.trim();
    final desc =
        _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null;

    final bool ok;
    if (_isRemote!) {
      ok = await ref.read(sharedExpenseGroupsProvider.notifier).create(
            title: title,
            description: desc,
            startDate: _startDate,
            endDate: _endDate,
          );
    } else {
      ok = await ref.read(expenseGroupsProvider.notifier).create(
            title: title,
            description: desc,
            startDate: _startDate,
            endDate: _endDate,
          );
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (ok) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create group. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRemoteSession = ref.watch(authProvider).hasRemoteSession;

    return Scaffold(
      appBar: AppBar(title: const Text('New Expense Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Step 1: type selector ─────────────────────────────
              const _StepLabel(step: '1', label: 'Choose group type'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.folder_outlined,
                      label: 'Offline',
                      description:
                          'Stored on this device. Great for personal budgeting.',
                      color: AppTheme.secondary,
                      selected: _isRemote == false,
                      enabled: true,
                      onTap: () => setState(() => _isRemote = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      icon: Icons.cloud_outlined,
                      label: 'Collaborative',
                      description: hasRemoteSession
                          ? 'Share with others and track together online.'
                          : 'Sign in to use collaborative groups.',
                      color: AppTheme.primary,
                      selected: _isRemote == true,
                      enabled: hasRemoteSession,
                      onTap: hasRemoteSession
                          ? () => setState(() => _isRemote = true)
                          : () => context
                              .push('/login?returnTo=/expenses/groups/new'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Step 2: details ───────────────────────────────────
              const _StepLabel(step: '2', label: 'Group details'),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Group title',
                hint: 'e.g. Monthly household, Trip to Paris',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Description (optional)',
                hint: 'What is this group for?',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // ── Step 3: optional date range ───────────────────────
              const _StepLabel(step: '3', label: 'Date range (optional)'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Start date',
                      controller: TextEditingController(
                        text: _startDate != null
                            ? DateFormat('MMM d, yyyy').format(_startDate!)
                            : '',
                      ),
                      readOnly: true,
                      hint: 'Pick date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'End date',
                      controller: TextEditingController(
                        text: _endDate != null
                            ? DateFormat('MMM d, yyyy').format(_endDate!)
                            : '',
                      ),
                      readOnly: true,
                      hint: 'Pick date',
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              AppButton(
                label: 'Create Group',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.folder_outlined,
                color: _isRemote == true
                    ? AppTheme.primary
                    : AppTheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Type selector card ───────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppTheme.textSecondary;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? effectiveColor.withValues(alpha: 0.12)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? effectiveColor : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: effectiveColor, size: 20),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle, color: effectiveColor, size: 16),
                  if (!enabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? effectiveColor : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step label ───────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String step;
  final String label;

  const _StepLabel({required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
