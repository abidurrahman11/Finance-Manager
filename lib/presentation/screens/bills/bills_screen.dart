import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/reminder_model.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          if (state.reminders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StatsChip(reminders: state.reminders),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
        backgroundColor: AppTheme.primary,
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, RemindersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(state.error!,
            style: const TextStyle(color: AppTheme.error)),
      );
    }

    if (state.reminders.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No reminders yet',
        subtitle:
            'Add reminders for expenses, income, tasks or anything you want to track.',
      );
    }

    // Split into pending and completed
    final pending =
        state.reminders.where((r) => !r.isCompleted).toList();
    final completed =
        state.reminders.where((r) => r.isCompleted).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(remindersProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionLabel(
              label: 'Pending',
              count: pending.length,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 8),
            ...pending.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReminderCard(
                    reminder: r,
                    onToggle: () =>
                        ref.read(remindersProvider.notifier).toggleCompleted(r.id),
                    onEdit: () => _showReminderForm(context, ref, reminder: r),
                    onDelete: () => _confirmDelete(context, ref, r),
                  ),
                )),
            const SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _SectionLabel(
              label: 'Completed',
              count: completed.length,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            ...completed.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReminderCard(
                    reminder: r,
                    onToggle: () =>
                        ref.read(remindersProvider.notifier).toggleCompleted(r.id),
                    onEdit: () => _showReminderForm(context, ref, reminder: r),
                    onDelete: () => _confirmDelete(context, ref, r),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ReminderModel reminder) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Reminder',
      message: 'Delete "${reminder.title}"? This cannot be undone.',
    );
    if (ok) {
      ref.read(remindersProvider.notifier).delete(reminder.id);
    }
  }

  void _showReminderForm(BuildContext context, WidgetRef ref,
      {ReminderModel? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReminderFormSheet(reminder: reminder, ref: ref),
    );
  }
}

// ─── Reminder Form Sheet ──────────────────────────────────────────────────────

class _ReminderFormSheet extends StatefulWidget {
  final ReminderModel? reminder;
  final WidgetRef ref;

  const _ReminderFormSheet({this.reminder, required this.ref});

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late ReminderType _type;
  late ReminderPriority _priority;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _type = r?.type ?? ReminderType.task;
    _priority = r?.priority ?? ReminderPriority.medium;
    _dueDate = r?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reminder != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            isEditing ? 'Edit Reminder' : 'New Reminder',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Title field
          AppTextField(
            label: 'Title',
            hint: 'e.g. Pay electricity bill',
            controller: _titleCtrl,
          ),
          const SizedBox(height: 14),

          // Type selector
          _FormLabel('Type'),
          const SizedBox(height: 8),
          _TypeSelector(
            selected: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 14),

          // Priority selector
          _FormLabel('Priority'),
          const SizedBox(height: 8),
          _PrioritySelector(
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),
          const SizedBox(height: 14),

          // Due date
          _FormLabel('Due Date (optional)'),
          const SizedBox(height: 8),
          _DueDatePicker(
            selected: _dueDate,
            onChanged: (d) => setState(() => _dueDate = d),
            onClear: () => setState(() => _dueDate = null),
          ),
          const SizedBox(height: 14),

          // Notes
          AppTextField(
            label: 'Notes (optional)',
            hint: 'Any additional details…',
            controller: _notesCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Save button
          AppButton(
            label: isEditing ? 'Save Changes' : 'Create Reminder',
            icon: isEditing ? Icons.save_outlined : Icons.add,
            isLoading: _isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final notifier = widget.ref.read(remindersProvider.notifier);
    bool ok;

    if (widget.reminder != null) {
      ok = await notifier.update(
        widget.reminder!.id,
        title: title,
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : null,
        type: _type,
        priority: _priority,
        isCompleted: widget.reminder!.isCompleted,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      );
    } else {
      ok = await notifier.create(
        title: title,
        notes: _notesCtrl.text.trim().isNotEmpty
            ? _notesCtrl.text.trim()
            : null,
        type: _type,
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

// ─── Reminder Card ────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final completed = reminder.isCompleted;
    final typeInfo = _typeInfo(reminder.type);
    final priorityColor = _priorityColor(reminder.priority);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.surface.withValues(alpha: 0.6)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? AppTheme.divider
              : priorityColor.withValues(alpha: 0.35),
          width: completed ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: completed
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: completed
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: completed
                      ? const Icon(Icons.check,
                          color: AppTheme.success, size: 14)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: completed
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeInfo.icon,
                                size: 11, color: typeInfo.color),
                            const SizedBox(width: 3),
                            Text(
                              typeInfo.label,
                              style: TextStyle(
                                color: typeInfo.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (reminder.notes != null &&
                      reminder.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reminder.notes!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Priority indicator
                      if (!completed) ...[
                        _PriorityDot(priority: reminder.priority),
                        const SizedBox(width: 6),
                        Text(
                          _priorityLabel(reminder.priority),
                          style: TextStyle(
                              color: priorityColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (!completed && reminder.dueDate != null)
                        const Text(' · ',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11)),
                      if (reminder.dueDate != null)
                        Row(children: [
                          Icon(
                            Icons.event_outlined,
                            size: 11,
                            color: _dueDateColor(
                                reminder.dueDate!, reminder.isCompleted),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('MMM d').format(reminder.dueDate!),
                            style: TextStyle(
                              color: _dueDateColor(
                                  reminder.dueDate!, reminder.isCompleted),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]),
                    ],
                  ),
                ],
              ),
            ),

            // Actions menu
            SizedBox(
              width: 32,
              child: PopupMenuButton<String>(
                color: AppTheme.surfaceVariant,
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textSecondary, size: 18),
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('Edit',
                          style: TextStyle(color: AppTheme.textPrimary)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 16, color: AppTheme.error),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppTheme.error)),
                    ]),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  _TypeInfo _typeInfo(ReminderType type) {
    switch (type) {
      case ReminderType.expense:
        return _TypeInfo(
            icon: Icons.arrow_upward, color: AppTheme.expense, label: 'Expense');
      case ReminderType.income:
        return _TypeInfo(
            icon: Icons.arrow_downward, color: AppTheme.income, label: 'Income');
      case ReminderType.task:
        return _TypeInfo(
            icon: Icons.task_alt_outlined,
            color: AppTheme.primary,
            label: 'Task');
      case ReminderType.custom:
        return _TypeInfo(
            icon: Icons.label_outline,
            color: AppTheme.secondary,
            label: 'Custom');
    }
  }

  Color _priorityColor(ReminderPriority p) {
    switch (p) {
      case ReminderPriority.high:
        return AppTheme.error;
      case ReminderPriority.medium:
        return AppTheme.warning;
      case ReminderPriority.low:
        return AppTheme.textSecondary;
    }
  }

  String _priorityLabel(ReminderPriority p) {
    switch (p) {
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.low:
        return 'Low';
    }
  }

  Color _dueDateColor(DateTime dueDate, bool isCompleted) {
    if (isCompleted) return AppTheme.textSecondary;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return AppTheme.error;
    if (due.isAtSameMomentAs(today)) return AppTheme.warning;
    return AppTheme.textSecondary;
  }
}

// ─── Type Selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final ReminderType selected;
  final ValueChanged<ReminderType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReminderType.values.map((type) {
        final info = _info(type);
        final isSelected = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? info.color.withValues(alpha: 0.18)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isSelected ? info.color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(info.icon,
                    size: 14,
                    color: isSelected
                        ? info.color
                        : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? info.color
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

  _TypeInfo _info(ReminderType type) {
    switch (type) {
      case ReminderType.expense:
        return _TypeInfo(
            icon: Icons.arrow_upward, color: AppTheme.expense, label: 'Expense');
      case ReminderType.income:
        return _TypeInfo(
            icon: Icons.arrow_downward, color: AppTheme.income, label: 'Income');
      case ReminderType.task:
        return _TypeInfo(
            icon: Icons.task_alt_outlined,
            color: AppTheme.primary,
            label: 'Task');
      case ReminderType.custom:
        return _TypeInfo(
            icon: Icons.label_outline,
            color: AppTheme.secondary,
            label: 'Custom');
    }
  }
}

// ─── Priority Selector ────────────────────────────────────────────────────────

class _PrioritySelector extends StatelessWidget {
  final ReminderPriority selected;
  final ValueChanged<ReminderPriority> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  static const _items = [
    (priority: ReminderPriority.high, label: 'High', color: AppTheme.error),
    (priority: ReminderPriority.medium, label: 'Medium', color: AppTheme.warning),
    (priority: ReminderPriority.low, label: 'Low', color: AppTheme.textSecondary),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items.map((item) {
        final isSelected = selected == item.priority;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(item.priority),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.15)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? item.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? item.color : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Due Date Picker ──────────────────────────────────────────────────────────

class _DueDatePicker extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;
  final VoidCallback onClear;

  const _DueDatePicker({
    required this.selected,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primary,
                surface: AppTheme.surfaceVariant,
                onSurface: AppTheme.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected != null
                    ? DateFormat('MMMM d, yyyy').format(selected!)
                    : 'Select a due date',
                style: TextStyle(
                  color: selected != null
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats Chip (AppBar) ──────────────────────────────────────────────────────

class _StatsChip extends StatelessWidget {
  final List<ReminderModel> reminders;

  const _StatsChip({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final total = reminders.length;
    final done = reminders.where((r) => r.isCompleted).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$done/$total done',
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionLabel(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ─── Priority Dot ─────────────────────────────────────────────────────────────

class _PriorityDot extends StatelessWidget {
  final ReminderPriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: _color(),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _color() {
    switch (priority) {
      case ReminderPriority.high:
        return AppTheme.error;
      case ReminderPriority.medium:
        return AppTheme.warning;
      case ReminderPriority.low:
        return AppTheme.textSecondary;
    }
  }
}

// ─── Form Label ───────────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600),
    );
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

class _TypeInfo {
  final IconData icon;
  final Color color;
  final String label;

  const _TypeInfo({required this.icon, required this.color, required this.label});
}
