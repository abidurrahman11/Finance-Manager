import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/bill_model.dart';
import '../../../data/repositories/bill_repository.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly Tracker'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Manage Bills'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBillForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
        backgroundColor: AppTheme.warning,
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _MonthlyTrackerTab(),
          _ManageBillsTab(),
        ],
      ),
    );
  }

  void _showBillForm(BuildContext context, WidgetRef ref,
      {BillModel? bill}) {
    final titleCtrl = TextEditingController(text: bill?.title ?? '');
    final amountCtrl =
        TextEditingController(text: bill?.amount.toString() ?? '');
    final notesCtrl = TextEditingController(text: bill?.notes ?? '');
    int dueDay = bill?.dueDay ?? 1;

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
            Text(bill != null ? 'Edit Bill' : 'New Recurring Bill',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Bill Name',
                hint: 'e.g. Netflix, Rent',
                controller: titleCtrl),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Amount',
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
            Row(children: [
              const Text('Due day of month:',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.textSecondary),
                  onPressed: () =>
                      setLocal(() => dueDay = (dueDay - 1).clamp(1, 31))),
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Text('$dueDay',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primary),
                  onPressed: () =>
                      setLocal(() => dueDay = (dueDay + 1).clamp(1, 31))),
            ]),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Notes (optional)', controller: notesCtrl, maxLines: 2),
            const SizedBox(height: 20),
            AppButton(
              label: bill != null ? 'Update Bill' : 'Create Bill',
              color: AppTheme.warning,
              icon: bill != null ? Icons.save : Icons.add,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty ||
                    amountCtrl.text.trim().isEmpty) return;
                if (bill != null) {
                  await ref.read(billsProvider.notifier).updateBill(bill.id,
                      title: titleCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text),
                      dueDay: dueDay,
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null);
                } else {
                  await ref.read(billsProvider.notifier).create(
                      title: titleCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text),
                      dueDay: dueDay,
                      notes: notesCtrl.text.trim().isNotEmpty
                          ? notesCtrl.text.trim()
                          : null);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Monthly Tracker Tab ─────────────────────────────────────────────────────
class _MonthlyTrackerTab extends ConsumerStatefulWidget {
  const _MonthlyTrackerTab();

  @override
  ConsumerState<_MonthlyTrackerTab> createState() =>
      _MonthlyTrackerTabState();
}

class _MonthlyTrackerTabState extends ConsumerState<_MonthlyTrackerTab> {
  DateTime _month = DateTime.now();

  String get _monthKey => DateFormat('yyyy-MM').format(_month);

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(billPaymentsProvider(_monthKey));

    return Column(children: [
      // Month selector
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: AppTheme.background,
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
            onPressed: () => setState(() =>
                _month = DateTime(_month.year, _month.month - 1)),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_month),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
            onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1)),
          ),
        ]),
      ),

      // Summary bar
      paymentsAsync.when(
        data: (payments) {
          final paid = payments.where((p) => p.isPaid).length;
          final total = payments.length;
          final paidAmount = payments
              .where((p) => p.isPaid)
              .fold(0.0, (s, p) => s + (p.paidAmount ?? p.expectedAmount));
          final totalAmount =
              payments.fold(0.0, (s, p) => s + p.expectedAmount);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surfaceVariant,
            child: Row(children: [
              _SummaryPill(
                label: '$paid/$total paid',
                color: AppTheme.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 12),
              _SummaryPill(
                label: CurrencyFormatter.format(paidAmount),
                color: AppTheme.income,
                icon: Icons.paid_outlined,
              ),
              const Spacer(),
              _SummaryPill(
                label: CurrencyFormatter.format(totalAmount - paidAmount),
                color: AppTheme.warning,
                icon: Icons.pending_outlined,
              ),
            ]),
          );
        },
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox.shrink(),
      ),

      // Bills list
      Expanded(
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long,
                title: 'No bills found',
                subtitle: 'Add recurring bills to track monthly payments',
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(billPaymentsProvider(_monthKey)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BillPaymentCard(
                    payment: payments[i],
                    onToggle: () =>
                        _togglePayment(ctx, payments[i]),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text(e.toString(),
                  style: const TextStyle(color: AppTheme.error))),
        ),
      ),

      // Reset button
      Padding(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          label: 'Reset All to Pending',
          isOutlined: true,
          icon: Icons.refresh,
          onPressed: () async {
            final ok = await showConfirmDialog(context,
                title: 'Reset Payments',
                message:
                    'Mark all bills as pending for the current month?',
                confirmLabel: 'Reset',
                confirmColor: AppTheme.warning);
            if (ok) {
              final repo = BillRepository();
              await repo.resetMonthlyPayments();
              ref.invalidate(billPaymentsProvider(_monthKey));
            }
          },
        ),
      ),
    ]);
  }

  Future<void> _togglePayment(
      BuildContext context, BillPaymentStatus payment) async {
    final newStatus = payment.isPaid ? 'pending' : 'paid';
    try {
      final repo = BillRepository();
      await repo.markPayment(payment.billId,
          month: _monthKey, status: newStatus);
      ref.invalidate(billPaymentsProvider(_monthKey));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error));
      }
    }
  }
}

// ─── Manage Bills Tab ─────────────────────────────────────────────────────────
class _ManageBillsTab extends ConsumerWidget {
  const _ManageBillsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);

    return bills.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No recurring bills',
            subtitle: 'Add bills to track your monthly obligations',
          );
        }
        final totalMonthly =
            list.fold(0.0, (s, b) => s + b.amount);
        return Column(children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A2D0A), Color(0xFF2D2200)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_outlined,
                  color: AppTheme.warning, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Monthly',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
                Text(CurrencyFormatter.format(totalMonthly),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning)),
              ]),
              const Spacer(),
              Text('${list.length} bills',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(billsProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BillManageCard(
                    bill: list[i],
                    onEdit: () => _showEditForm(ctx, ref, list[i]),
                    onDelete: () async {
                      final ok = await showConfirmDialog(ctx,
                          title: 'Delete Bill',
                          message: 'Delete "${list[i].title}"?');
                      if (ok) {
                        ref
                            .read(billsProvider.notifier)
                            .delete(list[i].id);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  void _showEditForm(BuildContext context, WidgetRef ref, BillModel bill) {
    final state = context.findAncestorStateOfType<_BillsScreenState>();
    state?._showBillForm(context, ref, bill: bill);
  }
}

// ─── Bill Payment Card ────────────────────────────────────────────────────────
class _BillPaymentCard extends StatelessWidget {
  final BillPaymentStatus payment;
  final VoidCallback onToggle;

  const _BillPaymentCard({required this.payment, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.isPaid;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? AppTheme.success.withOpacity(0.4)
              : AppTheme.warning.withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppTheme.success.withOpacity(0.15)
                  : Colors.transparent,
              border: Border.all(
                color: isPaid ? AppTheme.success : AppTheme.textSecondary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isPaid
                ? const Icon(Icons.check, color: AppTheme.success, size: 16)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payment.title,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: isPaid
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    decoration:
                        isPaid ? TextDecoration.lineThrough : null)),
            Row(children: [
              Text('Due: ${payment.dueDay}${_ordinal(payment.dueDay)}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11)),
              if (payment.billNotes != null &&
                  payment.billNotes!.isNotEmpty) ...[
                const Text(' • ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Flexible(
                    child: Text(payment.billNotes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11))),
              ]
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            CurrencyFormatter.format(payment.paidAmount ?? payment.expectedAmount),
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isPaid ? AppTheme.success : AppTheme.warning),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPaid ? 'PAID' : 'PENDING',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isPaid ? AppTheme.success : AppTheme.warning),
            ),
          ),
        ]),
      ]),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ─── Bill Manage Card ─────────────────────────────────────────────────────────
class _BillManageCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BillManageCard(
      {required this.bill, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.receipt_outlined,
              color: AppTheme.warning, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bill.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    fontSize: 14)),
            Text('Due: ${bill.dueDay}${_ordinal(bill.dueDay)} of each month',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ),
        Text(CurrencyFormatter.format(bill.amount),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.warning,
                fontSize: 14)),
        const SizedBox(width: 4),
        PopupMenuButton(
          color: AppTheme.surfaceVariant,
          icon: const Icon(Icons.more_vert,
              color: AppTheme.textSecondary, size: 20),
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: AppTheme.textPrimary)),
                ])),
            const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 16, color: AppTheme.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ])),
          ],
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
        ),
      ]),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryPill(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
