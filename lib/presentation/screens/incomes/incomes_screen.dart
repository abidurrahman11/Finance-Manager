import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/income_model.dart';
import '../../../core/utils/category_utils.dart';

class IncomesScreen extends ConsumerStatefulWidget {
  const IncomesScreen({super.key});

  @override
  ConsumerState<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends ConsumerState<IncomesScreen> {
  String? _selectedCategory;
  int? _selectedGroupId;
  String? _selectedGroupName;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      // Pagination can be added here if IncomesNotifier gets loadMore()
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    ref.read(incomesProvider.notifier).loadInitial(
          category: _selectedCategory,
          groupId: _selectedGroupId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomesProvider);
    final groupsAsync = ref.watch(incomeGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectedGroupName != null
            ? Text(_selectedGroupName!)
            : const Text('Income'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Groups',
            onPressed: () => context.push('/incomes/groups'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/incomes/new', extra: _selectedGroupId),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
        backgroundColor: AppTheme.income,
      ),
      body: Column(children: [
        // Group filter row
        groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All Groups',
                    selected: _selectedGroupId == null,
                    color: AppTheme.income,
                    onTap: () {
                      setState(() {
                        _selectedGroupId = null;
                        _selectedGroupName = null;
                      });
                      _reload();
                    },
                  ),
                  ...groups.map((g) => _FilterChip(
                        label: g.title,
                        selected: _selectedGroupId == g.id,
                        color: AppTheme.income,
                        onTap: () {
                          setState(() {
                            _selectedGroupId = g.id;
                            _selectedGroupName = g.title;
                            _selectedCategory = null;
                          });
                          _reload();
                        },
                      )),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Category filter chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'All',
                selected: _selectedCategory == null,
                color: AppTheme.income,
                onTap: () {
                  setState(() => _selectedCategory = null);
                  _reload();
                },
              ),
              ...AppConstants.incomeCategories.map((cat) => _FilterChip(
                    label: cat,
                    selected: _selectedCategory == cat,
                    color: AppTheme.income,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _reload();
                    },
                  )),
            ],
          ),
        ),
        const Divider(height: 1),

        // Income list
        Expanded(
          child: state.isLoading && state.incomes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.incomes.isEmpty
                  ? EmptyState(
                      icon: Icons.savings_outlined,
                      title: 'No income recorded',
                      subtitle: 'Start by adding your first income entry',
                      actionLabel: 'Add Income',
                      onAction: () => context.push('/incomes/new',
                          extra: _selectedGroupId),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.incomes.length,
                        itemBuilder: (context, i) {
                          final inc = state.incomes[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _IncomeTile(
                              income: inc,
                              colorIndex: i,
                              onEdit: () =>
                                  context.push('/incomes/edit', extra: inc),
                              onDelete: () async {
                                final ok = await showConfirmDialog(context,
                                    title: 'Delete Income',
                                    message:
                                        'Delete "${inc.title}"? This cannot be undone.');
                                if (ok) {
                                  ref
                                      .read(incomesProvider.notifier)
                                      .delete(inc.id, isRemote: inc.isRemote);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─── Income Tile ──────────────────────────────────────────────────────────────
class _IncomeTile extends StatefulWidget {
  final IncomeModel income;
  final int colorIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IncomeTile({
    required this.income,
    required this.colorIndex,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_IncomeTile> createState() => _IncomeTileState();
}

class _IncomeTileState extends State<_IncomeTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme
        .categoryColors[widget.colorIndex % AppTheme.categoryColors.length];
    final categoryIcon = CategoryUtils.getIncomeIcon(widget.income.category);

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(categoryIcon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.income.title,
                          maxLines: _isExpanded ? null : 1,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(children: [
                        CategoryBadge(
                            category: widget.income.category, color: color),
                        const SizedBox(width: 6),
                        Text(DateFormatter.formatDate(widget.income.incomeDate),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ]),
                      if (!_isExpanded &&
                          widget.income.notes != null &&
                          widget.income.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(widget.income.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                        ),
                    ]),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(widget.income.amount),
                    style: const TextStyle(
                        color: AppTheme.income,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ]),
            if (_isExpanded) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              if (widget.income.notes != null &&
                  widget.income.notes!.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(widget.income.notes!,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal)),
        ),
      ),
    );
  }
}
