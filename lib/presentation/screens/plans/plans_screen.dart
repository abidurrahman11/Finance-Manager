import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/plan_model.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Plans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlan(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
        backgroundColor: AppTheme.primary,
      ),
      body: plans.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.flag_outlined,
                title: 'No budget plans',
                subtitle:
                    'Create a plan to set spending targets and track progress',
                actionLabel: 'Create Plan',
                onAction: () => _showCreatePlan(context, ref),
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(plansProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final plan = list[i];
                    final color = AppTheme
                        .categoryColors[i % AppTheme.categoryColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: plan,
                        color: color,
                        onTap: () =>
                            context.push('/plans/${plan.id}', extra: plan),
                        onDelete: plan.isOwner
                            ? () async {
                                final ok = await showConfirmDialog(ctx,
                                    title: 'Delete Plan',
                                    message: 'Delete "${plan.title}"?');
                                if (ok) {
                                  ref
                                      .read(plansProvider.notifier)
                                      .delete(plan.id);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  void _showCreatePlan(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('New Budget Plan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Plan Title',
                  hint: 'e.g. January Budget',
                  controller: titleCtrl),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Description (optional)',
                  controller: descCtrl,
                  maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Target Amount (optional)',
                hint: '0.00',
                controller: targetCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('\$',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16))),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    date: startDate,
                    onPick: (d) => setLocal(() => startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    date: endDate,
                    onPick: (d) => setLocal(() => endDate = d),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              AppButton(
                label: 'Create Plan',
                icon: Icons.flag,
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final ok = await ref.read(plansProvider.notifier).create(
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim().isNotEmpty
                            ? descCtrl.text.trim()
                            : null,
                        targetAmount: targetCtrl.text.trim().isNotEmpty
                            ? double.tryParse(targetCtrl.text)
                            : null,
                        startDate: startDate,
                        endDate: endDate,
                      );
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PlanCard(
      {required this.plan,
      required this.color,
      required this.onTap,
      this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.flag, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary)),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Text(plan.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(plan.role.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.error, size: 18)),
            ],
          ]),
          if (plan.targetAmount != null) ...[
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Target',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  Text(CurrencyFormatter.format(plan.targetAmount!),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
          ],
          if (plan.startDate != null || plan.endDate != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${plan.startDate != null ? DateFormatter.formatDate(plan.startDate!) : '?'} → ${plan.endDate != null ? DateFormatter.formatDate(plan.endDate!) : '?'}',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('View details →',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DateField(
      {required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: AppTheme.primary)),
                child: child!));
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              date != null
                  ? DateFormat('MMM d, yy').format(date!)
                  : label,
              style: TextStyle(
                  color: date != null
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}
