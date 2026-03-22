import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpenseGroupsScreen extends ConsumerWidget {
  const ExpenseGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(expenseGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        backgroundColor: AppTheme.primary,
      ),
      body: groups.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.folder_outlined,
                title: 'No groups yet',
                subtitle: 'Create a group to organise shared expenses',
                actionLabel: 'Create Group',
                onAction: () => _showCreateGroupDialog(context, ref),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(expenseGroupsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final group = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupCard(
                        group: group,
                        onTap: () => _showGroupDetails(context, ref, group),
                        onDelete: group.isOwner
                            ? () async {
                                final ok = await showConfirmDialog(ctx,
                                    title: 'Delete Group',
                                    message:
                                        'Delete "${group.title}"? All expenses in this group will be unlinked.');
                                if (ok) {
                                  ref
                                      .read(expenseGroupsProvider.notifier)
                                      .delete(group.id);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Expense Group',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(label: 'Title', controller: titleCtrl),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Description (optional)',
              controller: descCtrl,
              maxLines: 2),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(expenseGroupsProvider.notifier).create(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : null,
                  );
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(
      BuildContext context, WidgetRef ref, ExpenseGroupModel group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _GroupDetailsSheet(group: group),
    );
  }
}

// ─── Group Card ───────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final ExpenseGroupModel group;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _GroupCard(
      {required this.group, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14)),
                  if (group.description != null &&
                      group.description!.isNotEmpty)
                    Text(group.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: group.isOwner
                            ? AppTheme.primary.withOpacity(0.15)
                            : AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        group.role.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: group.isOwner
                                ? AppTheme.primary
                                : AppTheme.secondary),
                      ),
                    ),
                    if (group.startDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatDate(group.startDate!),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ]),
                ]),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 20),
              onPressed: onDelete,
            ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}

// ─── Group Details Sheet ──────────────────────────────────────────────────────
class _GroupDetailsSheet extends ConsumerStatefulWidget {
  final ExpenseGroupModel group;
  const _GroupDetailsSheet({required this.group});

  @override
  ConsumerState<_GroupDetailsSheet> createState() =>
      _GroupDetailsSheetState();
}

class _GroupDetailsSheetState extends ConsumerState<_GroupDetailsSheet>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _collaborators = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  String _role = 'viewer';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: widget.group.isOwner ? 2 : 1, vsync: this);
    _loadCollaborators();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollaborators() async {
    try {
      final repo = ExpenseRepository();
      final list = await repo.getCollaborators(widget.group.id);
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

  Future<void> _addCollaborator() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    try {
      await ExpenseRepository().addCollaborator(
          widget.group.id, _emailCtrl.text.trim(), _role);
      _emailCtrl.clear();
      _loadCollaborators();
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

  Future<void> _removeCollaborator(int userId, String name) async {
    final ok = await showConfirmDialog(context,
        title: 'Remove Collaborator',
        message: 'Remove $name from this group?',
        confirmLabel: 'Remove');
    if (!ok) return;
    try {
      await ExpenseRepository()
          .removeCollaborator(widget.group.id, userId);
      _loadCollaborators();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Collaborator removed'),
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2)),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.group.title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    if (widget.group.description != null)
                      Text(widget.group.description!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                  ]),
            ),
            // Add Expense to this group
            if (widget.group.canEdit)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Push to expense form with this group pre-selected
                  context.push('/expenses/new', extra: widget.group.id);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.expense,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        // Tabs: Expenses | Collaborators (owner only)
        if (widget.group.isOwner)
          TabBar(
            controller: _tabCtrl,
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Collaborators'),
            ],
          )
        else
          const Divider(height: 1),
        const SizedBox(height: 4),
        // Tab content
        Expanded(
          child: widget.group.isOwner
              ? TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ExpensesTab(group: widget.group),
                    _CollaboratorsTab(
                      collaborators: _collaborators,
                      loading: _loading,
                      emailCtrl: _emailCtrl,
                      role: _role,
                      onRoleChanged: (v) => setState(() => _role = v),
                      onAdd: _addCollaborator,
                      onRemove: _removeCollaborator,
                    ),
                  ],
                )
              : _ExpensesTab(group: widget.group),
        ),
      ]),
    );
  }
}

// ─── Expenses Tab (filtered by group) ────────────────────────────────────────
class _ExpensesTab extends ConsumerWidget {
  final ExpenseGroupModel group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filter expenses by group using the provider
    final state = ref.watch(expensesProvider);
    final groupExpenses = state.expenses
        .where((e) => e.expenseGroupId == group.id)
        .toList();

    if (state.isLoading && state.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupExpenses.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          const Text('No expenses in this group',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          if (group.canEdit)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/expenses/new', extra: group.id);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.expense),
            ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groupExpenses.length,
      itemBuilder: (ctx, i) {
        final exp = groupExpenses[i];
        final color = AppTheme.categoryColors[i % AppTheme.categoryColors.length];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Icon(Icons.shopping_bag_outlined, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp.title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    Text(
                        '${exp.category} • ${DateFormatter.formatDate(exp.expenseDate)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
            ),
            Text(CurrencyFormatter.format(exp.amount),
                style: const TextStyle(
                    color: AppTheme.expense,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        );
      },
    );
  }
}

// ─── Collaborators Tab ────────────────────────────────────────────────────────
class _CollaboratorsTab extends StatelessWidget {
  final List<Map<String, dynamic>> collaborators;
  final bool loading;
  final TextEditingController emailCtrl;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onAdd;
  final Future<void> Function(int userId, String name) onRemove;

  const _CollaboratorsTab({
    required this.collaborators,
    required this.loading,
    required this.emailCtrl,
    required this.role,
    required this.onRoleChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Add collaborator row
        Row(children: [
          Expanded(
              child: AppTextField(
                  label: 'Email address',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: role,
            dropdownColor: AppTheme.surfaceVariant,
            style: const TextStyle(color: AppTheme.textPrimary),
            items: ['viewer', 'editor']
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => onRoleChanged(v!),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onAdd, child: const Text('Invite')),
        ]),
        const Divider(height: 24),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (collaborators.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No collaborators yet.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          )
        else
          ...collaborators.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text((c['name'] as String)[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.primary))),
                title: Text(c['name'] as String,
                    style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(c['email'] as String,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(c['role'] as String,
                        style: const TextStyle(
                            color: AppTheme.primary, fontSize: 11)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.error, size: 20),
                    tooltip: 'Remove',
                    onPressed: () =>
                        onRemove(c['user_id'] as int, c['name'] as String),
                  ),
                ]),
              )),
      ],
    );
  }
}
