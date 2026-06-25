import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_model.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/remote_bill_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/remote_plan_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/remote_analytics_repository.dart';
import '../../data/repositories/remote_income_repository.dart';
import 'auth_provider.dart';
import 'package:intl/intl.dart';

// ─── Repository Providers ───────────────────────────────────────────────────
final incomeRepositoryProvider = Provider((ref) => IncomeRepository());
final remoteIncomeRepositoryProvider =
    Provider((ref) => RemoteIncomeRepository());
final billRepositoryProvider = Provider((ref) => BillRepository());
final remoteBillRepositoryProvider = Provider((ref) => RemoteBillRepository());
final planRepositoryProvider = Provider((ref) => PlanRepository());
final remotePlanRepositoryProvider = Provider((ref) => RemotePlanRepository());
final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());
final remoteAnalyticsRepositoryProvider =
    Provider((ref) => RemoteAnalyticsRepository());

// ─── Income Groups ───────────────────────────────────────────────────────────
final incomeGroupsProvider =
    AsyncNotifierProvider<IncomeGroupsNotifier, List<IncomeGroupModel>>(
        IncomeGroupsNotifier.new);

final sharedIncomeGroupsProvider =
    AsyncNotifierProvider<SharedIncomeGroupsNotifier, List<IncomeGroupModel>>(
        SharedIncomeGroupsNotifier.new);

class IncomeGroupsNotifier extends AsyncNotifier<List<IncomeGroupModel>> {
  @override
  Future<List<IncomeGroupModel>> build() async {
    return ref.read(incomeRepositoryProvider).getGroups();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(incomeRepositoryProvider).getGroups());
  }

  Future<bool> create({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final group = await ref
          .read(incomeRepositoryProvider)
          .createGroup(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
          );
      state = AsyncData([group, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(incomeRepositoryProvider).deleteGroup(id);
      state =
          AsyncData(state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class SharedIncomeGroupsNotifier extends AsyncNotifier<List<IncomeGroupModel>> {
  @override
  Future<List<IncomeGroupModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.hasRemoteSession) return const [];
    return ref.read(remoteIncomeRepositoryProvider).getGroups();
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (!auth.hasRemoteSession) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(remoteIncomeRepositoryProvider).getGroups());
  }

  Future<bool> create({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final group = await ref
          .read(remoteIncomeRepositoryProvider)
          .createGroup(
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
          );
      state = AsyncData([group, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(remoteIncomeRepositoryProvider).deleteGroup(id);
      state =
          AsyncData(state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Incomes ─────────────────────────────────────────────────────────────────
class IncomesState {
  final List<IncomeModel> incomes;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const IncomesState({
    this.incomes = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  IncomesState copyWith({
    List<IncomeModel>? incomes,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) =>
      IncomesState(
        incomes: incomes ?? this.incomes,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        error: error,
      );
}

class IncomesNotifier extends StateNotifier<IncomesState> {
  final IncomeRepository _localRepo;
  final RemoteIncomeRepository _remoteRepo;
  final bool _isOnline;

  IncomesNotifier(this._localRepo, this._remoteRepo, this._isOnline)
      : super(const IncomesState()) {
    loadInitial();
  }

  String? _category;
  int? _groupId;

  Future<void> loadInitial({String? category, int? groupId}) async {
    _category = category;
    _groupId = groupId;
    state = const IncomesState(isLoading: true);
    try {
      final localResult = await _localRepo.getIncomes(
          category: category, incomeGroupId: groupId, page: 1);
      
      List<IncomeModel> merged = localResult.data;
      bool hasMore = localResult.page < localResult.totalPages;

      if (_isOnline) {
        try {
          final remoteResult = await _remoteRepo.getIncomes(
              category: category, incomeGroupId: groupId, page: 1);
          merged = [...merged, ...remoteResult.data];
          merged.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
          hasMore = hasMore || remoteResult.page < remoteResult.totalPages;
        } catch (_) {}
      }

      state = IncomesState(
        incomes: merged,
        hasMore: hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = IncomesState(error: e.toString());
    }
  }

  Future<bool> create({
    required String title,
    required double amount,
    required String category,
    DateTime? incomeDate,
    String? notes,
    int? incomeGroupId,
    String? imagePath,
    bool isRemote = false,
  }) async {
    try {
      IncomeModel income;
      if (isRemote && _isOnline) {
        income = await _remoteRepo.createIncome(
          title: title,
          amount: amount,
          category: category,
          incomeDate: incomeDate,
          notes: notes,
          incomeGroupId: incomeGroupId,
        );
      } else {
        income = await _localRepo.createIncome(
          title: title,
          amount: amount,
          category: category,
          incomeDate: incomeDate,
          notes: notes,
          incomeGroupId: incomeGroupId,
          imagePath: imagePath,
        );
      }
      state = state.copyWith(incomes: [income, ...state.incomes]..sort((a, b) => b.incomeDate.compareTo(a.incomeDate)));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id, {bool isRemote = false}) async {
    try {
      if (isRemote && _isOnline) {
        await _remoteRepo.deleteIncome(id);
      } else {
        await _localRepo.deleteIncome(id);
      }
      state = state.copyWith(
          incomes: state.incomes.where((i) => !(i.id == id && i.isRemote == isRemote)).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update(int id,
      {required String title,
      required double amount,
      required String category,
      DateTime? incomeDate,
      String? notes,
      int? incomeGroupId,
      bool isRemote = false}) async {
    try {
      IncomeModel updated;
      if (isRemote && _isOnline) {
        updated = await _remoteRepo.updateIncome(id,
            title: title,
            amount: amount,
            category: category,
            incomeDate: incomeDate,
            notes: notes,
            incomeGroupId: incomeGroupId);
      } else {
        updated = await _localRepo.updateIncome(id,
            title: title,
            amount: amount,
            category: category,
            incomeDate: incomeDate,
            notes: notes,
            incomeGroupId: incomeGroupId);
      }
      state = state.copyWith(
          incomes: state.incomes.map((i) => (i.id == id && i.isRemote == isRemote) ? updated : i).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final incomesProvider =
    StateNotifierProvider<IncomesNotifier, IncomesState>((ref) {
  final auth = ref.watch(authProvider);
  return IncomesNotifier(
    ref.read(incomeRepositoryProvider),
    ref.read(remoteIncomeRepositoryProvider),
    auth.hasRemoteSession,
  );
});

final groupIncomesProvider =
    FutureProvider.family<List<IncomeModel>, IncomeGroupModel>((ref, group) async {
  if (group.isRemote) {
    final result = await ref
        .read(remoteIncomeRepositoryProvider)
        .getIncomes(incomeGroupId: group.id);
    return result.data;
  }
  final result = await ref
      .read(incomeRepositoryProvider)
      .getIncomes(incomeGroupId: group.id);
  return result.data;
});

final sharedIncomeCollaboratorsProvider =
    FutureProvider.family<List<CollaboratorModel>, int>((ref, groupId) async {
  return ref.read(remoteIncomeRepositoryProvider).getCollaborators(groupId);
});

// ─── Personal Incomes (offline only, no group) ────────────────────────────────

/// Personal-only incomes — local only, [incomeGroupId] is null.
///
/// Fetches all local incomes then filters client-side to [incomeGroupId] == null
/// because the local SQLite repo treats null as "no filter" (not "where null").
final personalIncomesProvider =
    StateNotifierProvider<PersonalIncomesNotifier, IncomesState>((ref) {
  return PersonalIncomesNotifier(ref.read(incomeRepositoryProvider));
});

class PersonalIncomesNotifier extends StateNotifier<IncomesState> {
  final IncomeRepository _repo;

  PersonalIncomesNotifier(this._repo) : super(const IncomesState()) {
    loadInitial();
  }

  String? _category;

  Future<void> loadInitial({String? category}) async {
    _category = category;
    state = const IncomesState(isLoading: true);
    try {
      final result = await _repo.getIncomes(
        category: category,
        page: 1,
        limit: 200,
      );
      // Filter to personal-only (no group) client-side
      final personal =
          result.data.where((i) => i.incomeGroupId == null).toList();
      state = IncomesState(
        incomes: personal,
        hasMore: false,
        currentPage: 1,
      );
    } catch (e) {
      state = IncomesState(error: e.toString());
    }
  }

  // Personal list is loaded fully in one shot — no pagination needed
  Future<void> loadMore() async {}

  Future<bool> create({
    required String title,
    required double amount,
    required String category,
    DateTime? incomeDate,
    String? notes,
  }) async {
    try {
      final income = await _repo.createIncome(
        title: title,
        amount: amount,
        category: category,
        incomeDate: incomeDate,
        notes: notes,
        incomeGroupId: null,
      );
      state = state.copyWith(
        incomes: ([income, ...state.incomes]
          ..sort((a, b) => b.incomeDate.compareTo(a.incomeDate))),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.deleteIncome(id);
      state = state.copyWith(
        incomes: state.incomes.where((i) => i.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ─── Group incomes ─────────────────────────────────────────────────────────────

/// Incomes for a local (offline) group. Keyed by group ID.
/// Used by [IncomeGroupDetailScreen] when [group.isRemote] == false.
final localGroupIncomesProvider =
    FutureProvider.family<List<IncomeModel>, int>((ref, groupId) async {
  final result = await ref
      .read(incomeRepositoryProvider)
      .getIncomes(incomeGroupId: groupId);
  return result.data;
});

/// Incomes for a remote (collaborative) group. Keyed by group ID.
/// Used by [IncomeGroupDetailScreen] when [group.isRemote] == true.
final remoteGroupIncomesProvider =
    FutureProvider.family<List<IncomeModel>, int>((ref, groupId) async {
  final result = await ref
      .read(remoteIncomeRepositoryProvider)
      .getIncomes(incomeGroupId: groupId);
  return result.data;
});

// ─── Bills ───────────────────────────────────────────────────────────────────
final billsProvider =
    AsyncNotifierProvider<BillsNotifier, List<BillModel>>(BillsNotifier.new);

class BillsNotifier extends AsyncNotifier<List<BillModel>> {
  @override
  Future<List<BillModel>> build() async {
    final localBills = await ref.read(billRepositoryProvider).getBills();
    final auth = ref.watch(authProvider);
    if (auth.hasRemoteSession) {
      try {
        final remoteBills = await ref.read(remoteBillRepositoryProvider).getBills();
        return [...localBills, ...remoteBills];
      } catch (_) {
        return localBills;
      }
    }
    return localBills;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<bool> create(
      {required String title,
      required double amount,
      required int dueDay,
      String? notes,
      bool remote = false}) async {
    try {
      BillModel bill;
      if (remote) {
        bill = await ref.read(remoteBillRepositoryProvider).createBill(
            title: title, amount: amount, dueDay: dueDay, notes: notes);
      } else {
        bill = await ref.read(billRepositoryProvider).createBill(
            title: title, amount: amount, dueDay: dueDay, notes: notes);
      }
      state = AsyncData([bill, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateBill(int id,
      {required String title,
      required double amount,
      required int dueDay,
      String? notes,
      bool remote = false}) async {
    try {
      BillModel updated;
      if (remote) {
        updated = await ref.read(remoteBillRepositoryProvider).updateBill(id,
            title: title, amount: amount, dueDay: dueDay, notes: notes);
      } else {
        updated = await ref.read(billRepositoryProvider).updateBill(id,
            title: title, amount: amount, dueDay: dueDay, notes: notes);
      }
      state = AsyncData(
          state.valueOrNull?.map((b) => (b.id == id && b.isRemote == remote) ? updated : b).toList() ??
              []);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id, {bool remote = false}) async {
    try {
      if (remote) {
        await ref.read(remoteBillRepositoryProvider).deleteBill(id);
      } else {
        await ref.read(billRepositoryProvider).deleteBill(id);
      }
      state =
          AsyncData(state.valueOrNull?.where((b) => !(b.id == id && b.isRemote == remote)).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Bill payments for selected month
final selectedBillMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

final billPaymentsProvider =
    FutureProvider.family<List<BillPaymentStatus>, String>((ref, month) async {
  final localPayments = await ref.read(billRepositoryProvider).getPaymentsForMonth(month);
  final auth = ref.watch(authProvider);
  if (auth.hasRemoteSession) {
    try {
      final remotePayments = await ref.read(remoteBillRepositoryProvider).getPaymentsForMonth(month);
      return [...localPayments, ...remotePayments];
    } catch (_) {
      return localPayments;
    }
  }
  return localPayments;
});

// ─── Plans ───────────────────────────────────────────────────────────────────
final plansProvider =
    AsyncNotifierProvider<PlansNotifier, List<PlanModel>>(PlansNotifier.new);

final sharedPlansProvider =
    AsyncNotifierProvider<SharedPlansNotifier, List<PlanModel>>(
        SharedPlansNotifier.new);

class PlansNotifier extends AsyncNotifier<List<PlanModel>> {
  @override
  Future<List<PlanModel>> build() async {
    return ref.read(planRepositoryProvider).getPlans();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(planRepositoryProvider).getPlans());
  }

  Future<bool> create({
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final plan = await ref.read(planRepositoryProvider).createPlan(
            title: title,
            description: description,
            targetAmount: targetAmount,
            startDate: startDate,
            endDate: endDate,
          );
      state = AsyncData([plan, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(planRepositoryProvider).deletePlan(id);
      state =
          AsyncData(state.valueOrNull?.where((p) => p.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class SharedPlansNotifier extends AsyncNotifier<List<PlanModel>> {
  @override
  Future<List<PlanModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.hasRemoteSession) return const [];
    return ref.read(remotePlanRepositoryProvider).getPlans();
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (!auth.hasRemoteSession) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(remotePlanRepositoryProvider).getPlans());
  }

  Future<bool> create({
    required String title,
    String? description,
    double? targetAmount,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final plan = await ref.read(remotePlanRepositoryProvider).createPlan(
            title: title,
            description: description,
            targetAmount: targetAmount,
            startDate: startDate,
            endDate: endDate,
          );
      state = AsyncData([plan, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(remotePlanRepositoryProvider).deletePlan(id);
      state =
          AsyncData(state.valueOrNull?.where((p) => p.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final planDetailProvider =
    FutureProvider.family<PlanWithItems, PlanModel>((ref, plan) async {
  if (plan.isRemote) {
    return ref.read(remotePlanRepositoryProvider).getPlan(plan.id);
  }
  return ref.read(planRepositoryProvider).getPlan(plan.id);
});

// ─── Analytics ───────────────────────────────────────────────────────────────
final cashFlowProvider = FutureProvider<CashFlow>((ref) async {
  final now = DateTime.now();
  final start =
      DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
  final lastDay = DateTime(now.year, now.month % 12 + 1, 0);
  final end = DateFormat('yyyy-MM-dd').format(lastDay);
  
  final localCf = await ref
      .read(analyticsRepositoryProvider)
      .getCashFlow(startDate: start, endDate: end);
      
  final auth = ref.watch(authProvider);
  if (auth.hasRemoteSession) {
    try {
      final remoteCf = await ref
          .read(remoteAnalyticsRepositoryProvider)
          .getCashFlow(startDate: start, endDate: end);
          
      return CashFlow(
        totalIncome: localCf.totalIncome + remoteCf.totalIncome,
        totalExpenses: localCf.totalExpenses + remoteCf.totalExpenses,
        totalPaidBills: localCf.totalPaidBills + remoteCf.totalPaidBills,
        cashFlow: localCf.cashFlow + remoteCf.cashFlow,
      );
    } catch (_) {
      return localCf;
    }
  }
  return localCf;
});

final categoryAnalyticsProvider =
    FutureProvider<List<CategoryAnalytics>>((ref) async {
  final now = DateTime.now();
  final start =
      DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
  final lastDay = DateTime(now.year, now.month % 12 + 1, 0);
  final end = DateFormat('yyyy-MM-dd').format(lastDay);
  
  final localCats = await ref
      .read(analyticsRepositoryProvider)
      .getByCategory(startDate: start, endDate: end);
      
  final auth = ref.watch(authProvider);
  if (auth.hasRemoteSession) {
    try {
      final remoteCats = await ref
          .read(remoteAnalyticsRepositoryProvider)
          .getByCategory(startDate: start, endDate: end);
          
      // Merge categories
      final map = <String, CategoryAnalytics>{};
      for (var c in localCats) {
        map[c.category] = c;
      }
      for (var c in remoteCats) {
        if (map.containsKey(c.category)) {
          final existing = map[c.category]!;
          map[c.category] = CategoryAnalytics(
            category: c.category,
            expenseCount: existing.expenseCount + c.expenseCount,
            totalSpent: existing.totalSpent + c.totalSpent,
          );
        } else {
          map[c.category] = c;
        }
      }
      return map.values.toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    } catch (_) {
      return localCats;
    }
  }
  return localCats;
});

final monthlyTrendsProvider = FutureProvider<List<MonthlyTrend>>((ref) async {
  final localTrends = await ref.read(analyticsRepositoryProvider).getMonthlyTrends();
  
  final auth = ref.watch(authProvider);
  if (auth.hasRemoteSession) {
    try {
      final remoteTrends = await ref.read(remoteAnalyticsRepositoryProvider).getMonthlyTrends();
      
      // Merge trends
      final map = <DateTime, MonthlyTrend>{};
      for (var t in localTrends) {
        map[t.month] = t;
      }
      for (var t in remoteTrends) {
        if (map.containsKey(t.month)) {
          final existing = map[t.month]!;
          map[t.month] = MonthlyTrend(
            month: t.month,
            expenseCount: existing.expenseCount + t.expenseCount,
            totalSpent: existing.totalSpent + t.totalSpent,
          );
        } else {
          map[t.month] = t;
        }
      }
      return map.values.toList()..sort((a, b) => a.month.compareTo(b.month));
    } catch (_) {
      return localTrends;
    }
  }
  return localTrends;
});
