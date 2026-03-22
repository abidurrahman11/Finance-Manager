import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/income_model.dart';
import '../../../data/repositories/income_repository.dart';

class IncomeGroupsScreen extends ConsumerWidget {
  const IncomeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(incomeGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Income Groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        backgroundColor: AppTheme.income,
      ),
      body: groups.when(
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.folder_outlined,
                title: 'No income groups',
                subtitle: 'Group income sources to track them together',
                actionLabel: 'Create Group',
                onAction: () => _showCreate(context, ref),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(incomeGroupsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final g = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GroupCard(
                        group: g,
                        onTap: () => _showGroupDetails(context, ref, g),
                        onDelete: g.isOwner
                            ? () async {
                                final ok = await showConfirmDialog(ctx,
                                    title: 'Delete Group',
                                    message:
                                        'Delete "${g.title}"? All incomes in this group will be unlinked.');
                                if (ok) {
                                  ref
                                      .read(incomeGroupsProvider.notifier)
                                      .delete(g.id);
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

  void _showCreate(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Income Group',
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
              await ref.read(incomeGroupsProvider.notifier).create(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : null,
                  );
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.income),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(
      BuildContext context, WidgetRef ref, IncomeGroupModel group) {
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
  final IncomeGroupModel group;
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
                color: AppTheme.income.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder, color: AppTheme.income, size: 22),
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
                            ? AppTheme.income.withOpacity(0.15)
                            : AppTheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        group.role.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: group.isOwner
                                ? AppTheme.income
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
  final IncomeGroupModel group;
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
      final list =
          await IncomeRepository().getCollaborators(widget.group.id);
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
      await IncomeRepository().addCollaborator(
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
      await IncomeRepository()
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
            if (widget.group.canEdit)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/incomes/new', extra: widget.group.id);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Income'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.income,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8)),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        if (widget.group.isOwner)
          TabBar(
            controller: _tabCtrl,
            indicatorColor: AppTheme.income,
            labelColor: AppTheme.income,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Incomes'),
              Tab(text: 'Collaborators'),
            ],
          )
        else
          const Divider(height: 1),
        const SizedBox(height: 4),
        Expanded(
          child: widget.group.isOwner
              ? TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _IncomesTab(group: widget.group),
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
              : _IncomesTab(group: widget.group),
        ),
      ]),
    );
  }
}

// ─── Incomes Tab ──────────────────────────────────────────────────────────────
class _IncomesTab extends ConsumerWidget {
  final IncomeGroupModel group;
  const _IncomesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incomesProvider);
    final groupIncomes = state.incomes
        .where((i) => i.incomeGroupId == group.id)
        .toList();

    if (state.isLoading && state.incomes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupIncomes.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.savings_outlined,
              size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          const Text('No income in this group',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          if (group.canEdit)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/incomes/new', extra: group.id);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.income),
            ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groupIncomes.length,
      itemBuilder: (ctx, i) {
        final inc = groupIncomes[i];
        final color =
            AppTheme.categoryColors[i % AppTheme.categoryColors.length];
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
                  color: AppTheme.income.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.savings_outlined,
                  color: AppTheme.income, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inc.title,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                    Text(
                        '${inc.category} • ${DateFormatter.formatDate(inc.incomeDate)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
            ),
            Text(CurrencyFormatter.format(inc.amount),
                style: const TextStyle(
                    color: AppTheme.income,
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
          ElevatedButton(
              onPressed: onAdd,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.income),
              child: const Text('Invite')),
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
                    backgroundColor: AppTheme.income.withOpacity(0.2),
                    child: Text((c['name'] as String)[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.income))),
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
                        color: AppTheme.income.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(c['role'] as String,
                        style: const TextStyle(
                            color: AppTheme.income, fontSize: 11)),
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
