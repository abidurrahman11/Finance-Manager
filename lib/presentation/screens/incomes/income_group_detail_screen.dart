import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/incomes/income_list_tile.dart';
import '../../widgets/incomes/income_group_type_badge.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/income_model.dart';
import '../../../data/models/plan_model.dart'; // CollaboratorModel lives here

/// Full-screen detail view for a single [IncomeGroupModel].
///
/// Local groups  → 1 tab  : Incomes
/// Remote groups → 3 tabs : Incomes | Collaborators | Summary
///
/// FAB adds an income pre-targeted to this group.
/// Owner-only actions (delete group) live in the AppBar overflow menu.
///
/// Mirrors [GroupDetailScreen] for expenses exactly.
class IncomeGroupDetailScreen extends ConsumerStatefulWidget {
  final IncomeGroupModel group;
  const IncomeGroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<IncomeGroupDetailScreen> createState() =>
      _IncomeGroupDetailScreenState();
}

class _IncomeGroupDetailScreenState
    extends ConsumerState<IncomeGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  bool get _isRemote => widget.group.isRemote;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _isRemote ? 3 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            IncomeGroupTypeBadge(isRemote: group.isRemote),
          ],
        ),
        actions: [
          if (group.isOwner)
            PopupMenuButton<_GroupAction>(
              icon: const Icon(Icons.more_vert),
              color: AppTheme.surface,
              onSelected: (action) {
                if (action == _GroupAction.delete) _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _GroupAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppTheme.error),
                      SizedBox(width: 10),
                      Text('Delete group',
                          style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: _isRemote
            ? TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.income,
                labelColor: AppTheme.income,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Incomes'),
                  Tab(text: 'Collaborators'),
                  Tab(text: 'Summary'),
                ],
              )
            : null,
      ),
      floatingActionButton: group.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/incomes/new', extra: group),
              icon: const Icon(Icons.add),
              label: const Text('Add Income'),
              backgroundColor: AppTheme.income,
            )
          : null,
      body: _isRemote
          ? TabBarView(
              controller: _tabCtrl,
              children: [
                _IncomesTab(group: group),
                _CollaboratorsTab(group: group),
                _SummaryTab(group: group),
              ],
            )
          : _IncomesTab(group: group),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Group',
      message:
          'Delete "${widget.group.title}"? All incomes in this group will be unlinked.',
    );
    if (!ok || !mounted) return;

    if (widget.group.isRemote) {
      await ref
          .read(sharedIncomeGroupsProvider.notifier)
          .delete(widget.group.id);
    } else {
      await ref
          .read(incomeGroupsProvider.notifier)
          .delete(widget.group.id);
    }

    if (mounted) context.pop();
  }
}

enum _GroupAction { delete }

// ─── Incomes tab ──────────────────────────────────────────────────────────────

class _IncomesTab extends ConsumerStatefulWidget {
  final IncomeGroupModel group;
  const _IncomesTab({required this.group});

  @override
  ConsumerState<_IncomesTab> createState() => _IncomesTabState();
}

class _IncomesTabState extends ConsumerState<_IncomesTab> {
  String? _selectedCategory;

  /// Selects the right FutureProvider based on group type.
  ///
  /// Both [localGroupIncomesProvider] and [remoteGroupIncomesProvider] are
  /// FutureProvider.family<List<IncomeModel>, int>, so calling them with an
  /// int produces an AutoDisposeFutureProvider<List<IncomeModel>>, which
  /// implements ProviderListenable<AsyncValue<List<IncomeModel>>>.
  ProviderListenable<AsyncValue<List<IncomeModel>>> get _provider =>
      widget.group.isRemote
          ? remoteGroupIncomesProvider(widget.group.id)
          : localGroupIncomesProvider(widget.group.id);

  /// Invalidates the provider so the list re-fetches from the DB/API.
  void _invalidate() {
    if (widget.group.isRemote) {
      ref.invalidate(remoteGroupIncomesProvider(widget.group.id));
    } else {
      ref.invalidate(localGroupIncomesProvider(widget.group.id));
    }
  }

  /// Deletes a single income entry from the correct backend and refreshes the list.
  Future<void> _deleteIncome(IncomeModel income) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Income',
      message: 'Delete "${income.title}"? This cannot be undone.',
    );
    if (!ok || !mounted) return;

    try {
      if (income.isRemote) {
        await ref
            .read(remoteIncomeRepositoryProvider)
            .deleteIncome(income.id);
      } else {
        await ref
            .read(incomeRepositoryProvider)
            .deleteIncome(income.id);
      }
      _invalidate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomesAsync = ref.watch(_provider);

    return incomesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      data: (incomes) {
        final filtered = _selectedCategory == null
            ? incomes
            : incomes
                .where((i) => i.category == _selectedCategory)
                .toList();

        return Column(
          children: [
            // ── Category filter chips ───────────────────────────────
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () =>
                        setState(() => _selectedCategory = null),
                  ),
                  ...AppConstants.incomeCategories.map(
                    (cat) => _FilterChip(
                      label: cat,
                      selected: _selectedCategory == cat,
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── List or empty state ─────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.savings_outlined,
                      title: 'No incomes',
                      subtitle: _selectedCategory != null
                          ? 'No $_selectedCategory income in this group.'
                          : 'Tap the button below to add the first income.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _invalidate(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final inc = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: IncomeListTile(
                              income: inc,
                              colorIndex: i,
                              onEdit: () {
                                // Invalidate on pop so edits are immediately
                                // visible without a manual pull-to-refresh.
                                context
                                    .push('/incomes/edit', extra: inc)
                                    .then((_) => _invalidate());
                              },
                              onDelete: () => _deleteIncome(inc),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Collaborators tab ────────────────────────────────────────────────────────

class _CollaboratorsTab extends ConsumerStatefulWidget {
  final IncomeGroupModel group;
  const _CollaboratorsTab({required this.group});

  @override
  ConsumerState<_CollaboratorsTab> createState() => _CollaboratorsTabState();
}

class _CollaboratorsTabState extends ConsumerState<_CollaboratorsTab> {
  final _emailCtrl = TextEditingController();
  bool _inviting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    setState(() => _inviting = true);
    try {
      await ref
          .read(remoteIncomeRepositoryProvider)
          .addCollaborator(widget.group.id, email, 'editor');
      _emailCtrl.clear();
      ref.invalidate(sharedIncomeCollaboratorsProvider(widget.group.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collaboratorsAsync =
        ref.watch(sharedIncomeCollaboratorsProvider(widget.group.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.group.isOwner) ...[
          const Text(
            'Invite collaborator',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Email address',
                  hint: 'colleague@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 10),
              _inviting
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      onPressed: _invite,
                      icon: const Icon(Icons.send, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.income,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
        ],

        const Text(
          'Members',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        collaboratorsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            e.toString(),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          data: (members) {
            if (members.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No collaborators yet. Invite someone above.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Column(
              children: members
                  .map(
                    (m) => _CollaboratorTile(
                      key: ValueKey(m.userId),
                      member: m,
                      groupId: widget.group.id,
                      isOwner: widget.group.isOwner,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CollaboratorTile extends ConsumerWidget {
  final CollaboratorModel member;
  final int groupId;
  final bool isOwner;

  const _CollaboratorTile({
    super.key,
    required this.member,
    required this.groupId,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.income.withValues(alpha: 0.2),
        child: Text(
          member.email.isNotEmpty ? member.email[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppTheme.income,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.email,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      ),
      subtitle: Text(
        member.role,
        style:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: isOwner && member.role != 'owner'
          ? IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppTheme.error,
                size: 20,
              ),
              tooltip: 'Remove',
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Remove Collaborator',
                  message: 'Remove ${member.email} from this group?',
                  confirmLabel: 'Remove',
                );
                if (ok) {
                  await ref
                      .read(remoteIncomeRepositoryProvider)
                      .removeCollaborator(groupId, member.userId);
                  ref.invalidate(
                      sharedIncomeCollaboratorsProvider(groupId));
                }
              },
            )
          : null,
    );
  }
}

// ─── Summary tab ──────────────────────────────────────────────────────────────

class _SummaryTab extends ConsumerWidget {
  final IncomeGroupModel group;
  const _SummaryTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(remoteGroupIncomesProvider(group.id));

    return incomesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      data: (incomes) {
        if (incomes.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No data yet',
            subtitle: 'Add incomes to this group to see a summary.',
          );
        }

        final total = incomes.fold(0.0, (s, i) => s + i.amount);

        final Map<String, double> byCategory = {};
        for (final inc in incomes) {
          byCategory[inc.category] =
              (byCategory[inc.category] ?? 0) + inc.amount;
        }
        final sortedCategories = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryStatCard(
              label: 'Group total',
              value: CurrencyFormatter.format(total),
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
            const Text(
              'By category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...sortedCategories.asMap().entries.map((entry) {
              final color = AppTheme.categoryColors[
                  entry.key % AppTheme.categoryColors.length];
              final pct = total > 0 ? entry.value.value / total : 0.0;
              return _CategoryBar(
                category: entry.value.key,
                amount: entry.value.value,
                percent: pct,
                color: color,
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _SummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.income.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.income, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.income,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;
  final Color color;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 12),
              ),
              Text(
                '${CurrencyFormatter.format(amount)} · ${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.income : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
