import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/repositories/plan_repository.dart';

class PlanDetailScreen extends ConsumerWidget {
  final PlanModel plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(planDetailProvider(plan.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          if (plan.isOwner)
            IconButton(
              icon: const Icon(Icons.people_outline),
              onPressed: () => _showCollaborators(context, ref),
            ),
        ],
      ),
      floatingActionButton: plan.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showAddItem(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              backgroundColor: AppTheme.primary,
            )
          : null,
      body: detailAsync.when(
        data: (planWithItems) => _PlanDetailBody(
          planWithItems: planWithItems,
          canEdit: plan.canEdit,
          onRefresh: () => ref.invalidate(planDetailProvider(plan.id)),
          onDeleteItem: (item) => _deleteItem(context, ref, item),
          onUpdateSpent: (item) => _showUpdateSpent(context, ref, planWithItems.plan, item),
          onEditItem: (item) => _showEditItem(context, ref, planWithItems.plan, item),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  Future<void> _deleteItem(
      BuildContext context, WidgetRef ref, PlanItemModel item) async {
    final ok = await showConfirmDialog(context,
        title: 'Remove Category', message: 'Remove "${item.category}"?');
    if (ok) {
      try {
        await PlanRepository().deleteItem(plan.id, item.id);
        ref.invalidate(planDetailProvider(plan.id));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.error));
        }
      }
    }
  }

  void _showAddItem(BuildContext context, WidgetRef ref) {
    String category = AppConstants.expenseCategories.first;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add Budget Category',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceVariant,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: AppConstants.expenseCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Budget Amount',
              hint: '0.00',
              controller: amountCtrl,
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
            AppTextField(
                label: 'Notes (optional)',
                controller: notesCtrl,
                maxLines: 2),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add Category',
              icon: Icons.add,
              onPressed: () async {
                if (amountCtrl.text.trim().isEmpty) return;
                try {
                  await PlanRepository().addItem(plan.id,
                      category: category,
                      expectedAmount: double.parse(amountCtrl.text),
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null);
                  ref.invalidate(planDetailProvider(plan.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error));
                  }
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showEditItem(BuildContext context, WidgetRef ref, PlanModel p,
      PlanItemModel item) {
    String category = item.category;
    final amountCtrl =
        TextEditingController(text: item.expectedAmount.toString());
    final notesCtrl = TextEditingController(text: item.notes ?? '');

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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Edit Budget Category',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceVariant,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  items: AppConstants.expenseCategories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => category = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Budget Amount',
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Notes', controller: notesCtrl, maxLines: 2),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save Changes',
              icon: Icons.save,
              onPressed: () async {
                try {
                  await PlanRepository().updateItem(p.id, item.id,
                      category: category,
                      expectedAmount: double.parse(amountCtrl.text),
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null);
                  ref.invalidate(planDetailProvider(p.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error));
                  }
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showUpdateSpent(BuildContext context, WidgetRef ref, PlanModel p,
      PlanItemModel item) {
    final amountCtrl = TextEditingController();
    String operation = 'add';

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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Update Spent — ${item.category}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Current: ${CurrencyFormatter.format(item.spentAmount)} / ${CurrencyFormatter.format(item.expectedAmount)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setLocal(() => operation = 'add'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: operation == 'add'
                          ? AppTheme.expense.withOpacity(0.15)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: operation == 'add'
                              ? AppTheme.expense
                              : Colors.transparent),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: operation == 'add'
                                  ? AppTheme.expense
                                  : AppTheme.textSecondary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text('Add Spent',
                              style: TextStyle(
                                  color: operation == 'add'
                                      ? AppTheme.expense
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setLocal(() => operation = 'subtract'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: operation == 'subtract'
                          ? AppTheme.income.withOpacity(0.15)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: operation == 'subtract'
                              ? AppTheme.income
                              : Colors.transparent),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_circle_outline,
                              color: operation == 'subtract'
                                  ? AppTheme.income
                                  : AppTheme.textSecondary,
                              size: 18),
                          const SizedBox(width: 6),
                          Text('Subtract',
                              style: TextStyle(
                                  color: operation == 'subtract'
                                      ? AppTheme.income
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Amount',
              controller: amountCtrl,
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
            const SizedBox(height: 20),
            AppButton(
              label: 'Update',
              icon: Icons.update,
              onPressed: () async {
                if (amountCtrl.text.trim().isEmpty) return;
                try {
                  await PlanRepository().updateSpent(p.id, item.id,
                      amount: double.parse(amountCtrl.text),
                      operation: operation);
                  ref.invalidate(planDetailProvider(p.id));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppTheme.error));
                  }
                }
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showCollaborators(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CollaboratorsSheet(planId: plan.id),
    );
  }
}

// ─── Plan Detail Body ─────────────────────────────────────────────────────────
class _PlanDetailBody extends StatelessWidget {
  final PlanWithItems planWithItems;
  final bool canEdit;
  final VoidCallback onRefresh;
  final void Function(PlanItemModel) onDeleteItem;
  final void Function(PlanItemModel) onUpdateSpent;
  final void Function(PlanItemModel) onEditItem;

  const _PlanDetailBody({
    required this.planWithItems,
    required this.canEdit,
    required this.onRefresh,
    required this.onDeleteItem,
    required this.onUpdateSpent,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    final p = planWithItems.plan;
    final items = planWithItems.items;
    final overallPct = planWithItems.overallProgress;
    final totalSpent = planWithItems.totalSpent;
    final totalExpected = planWithItems.totalExpected;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // Header card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: overallPct > 1.0
                      ? [const Color(0xFF3A1E1E), const Color(0xFF4A1515)]
                      : [const Color(0xFF1E1E3A), const Color(0xFF151540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                overallPct > 1.0
                                    ? 'Over Budget!'
                                    : '${(overallPct * 100).toStringAsFixed(0)}% used',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: overallPct > 1.0
                                        ? AppTheme.error
                                        : AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(totalSpent),
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: overallPct > 1.0
                                        ? AppTheme.error
                                        : AppTheme.textPrimary),
                              ),
                              Text(
                                'of ${CurrencyFormatter.format(totalExpected)} budgeted',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                              ),
                            ]),
                      ),
                      CircularPercentIndicator(
                        radius: 40,
                        lineWidth: 8,
                        percent: overallPct.clamp(0.0, 1.0),
                        center: Text(
                          '${(overallPct * 100).clamp(0, 999).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: overallPct > 0.9
                                  ? AppTheme.error
                                  : AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        progressColor: overallPct > 1.0
                            ? AppTheme.error
                            : overallPct > 0.8
                                ? AppTheme.warning
                                : AppTheme.primary,
                        backgroundColor: AppTheme.divider,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallPct.clamp(0.0, 1.0),
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallPct > 1.0
                              ? AppTheme.error
                              : overallPct > 0.8
                                  ? AppTheme.warning
                                  : AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    if (p.targetAmount != null) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.flag,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${CurrencyFormatter.format(p.targetAmount!)}  •  Remaining: ${CurrencyFormatter.format((p.targetAmount! - totalSpent).clamp(0, double.infinity))}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ]),
                    ],
                  ]),
            ),
          ),

          // Items section header
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                items.isEmpty ? 'No categories yet' : 'Budget Categories',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
            ),
          ),

          // Items list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final item = items[i];
                final color = AppTheme
                    .categoryColors[i % AppTheme.categoryColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: _PlanItemCard(
                    item: item,
                    color: color,
                    canEdit: canEdit,
                    onDelete: () => onDeleteItem(item),
                    onUpdateSpent: () => onUpdateSpent(item),
                    onEdit: () => onEditItem(item),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Plan Item Card ───────────────────────────────────────────────────────────
class _PlanItemCard extends StatelessWidget {
  final PlanItemModel item;
  final Color color;
  final bool canEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateSpent;
  final VoidCallback onEdit;

  const _PlanItemCard({
    required this.item,
    required this.color,
    required this.canEdit,
    required this.onDelete,
    required this.onUpdateSpent,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = item.progressPercent;
    final isOver = item.isOverBudget;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOver
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.category_outlined, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14)),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(item.notes!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                ]),
          ),
          if (canEdit)
            Row(children: [
              GestureDetector(
                onTap: onUpdateSpent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.edit_note,
                      color: AppTheme.primary, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.tune,
                    color: AppTheme.textSecondary, size: 18),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 18),
              ),
            ]),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            CurrencyFormatter.format(item.spentAmount),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isOver ? AppTheme.error : AppTheme.textPrimary),
          ),
          Text(
            'of ${CurrencyFormatter.format(item.expectedAmount)}',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOver
                  ? AppTheme.error
                  : pct > 0.8
                      ? AppTheme.warning
                      : color,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '${(pct * 100).toStringAsFixed(0)}% used',
            style: TextStyle(
                color: isOver ? AppTheme.error : AppTheme.textSecondary,
                fontSize: 11),
          ),
          Text(
            isOver
                ? '${CurrencyFormatter.format(item.spentAmount - item.expectedAmount)} over'
                : '${CurrencyFormatter.format(item.remaining)} left',
            style: TextStyle(
                color: isOver ? AppTheme.error : AppTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }
}

// ─── Collaborators Sheet ──────────────────────────────────────────────────────
class _CollaboratorsSheet extends ConsumerStatefulWidget {
  final int planId;
  const _CollaboratorsSheet({required this.planId});

  @override
  ConsumerState<_CollaboratorsSheet> createState() =>
      _CollaboratorsSheetState();
}

class _CollaboratorsSheetState
    extends ConsumerState<_CollaboratorsSheet> {
  List<CollaboratorModel> _collaborators = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  String _role = 'viewer';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list =
          await PlanRepository().getCollaborators(widget.planId);
      if (mounted) {
        setState(() {
          _collaborators = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    try {
      await PlanRepository()
          .addCollaborator(widget.planId, _emailCtrl.text.trim(), _role);
      _emailCtrl.clear();
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Collaborator added'),
            backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _remove(int userId) async {
    try {
      await PlanRepository().removeCollaborator(widget.planId, userId);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Plan Collaborators',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: AppTextField(
                    label: 'User email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _role,
              dropdownColor: AppTheme.surfaceVariant,
              style: const TextStyle(color: AppTheme.textPrimary),
              items: ['viewer', 'editor']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _add, child: const Text('Invite')),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_collaborators.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No collaborators yet.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: ctrl,
                itemCount: _collaborators.length,
                itemBuilder: (_, i) {
                  final c = _collaborators[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(c.name[0].toUpperCase(),
                            style:
                                const TextStyle(color: AppTheme.primary))),
                    title: Text(c.name,
                        style: const TextStyle(color: AppTheme.textPrimary)),
                    subtitle: Text(c.email,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(c.role,
                            style: const TextStyle(
                                color: AppTheme.primary, fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppTheme.error, size: 18),
                        onPressed: () => _remove(c.userId),
                      ),
                    ]),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
