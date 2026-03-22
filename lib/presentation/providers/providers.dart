import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_model.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/analytics_model.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import 'package:intl/intl.dart';

// ─── Repository Providers ───────────────────────────────────────────────────
final incomeRepositoryProvider = Provider((ref) => IncomeRepository());
final billRepositoryProvider = Provider((ref) => BillRepository());
final planRepositoryProvider = Provider((ref) => PlanRepository());
final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

// ─── Income Groups ───────────────────────────────────────────────────────────
final incomeGroupsProvider =
    AsyncNotifierProvider<IncomeGroupsNotifier, List<IncomeGroupModel>>(
        IncomeGroupsNotifier.new);

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

  Future<bool> create({required String title, String? description}) async {
    try {
      final group = await ref
          .read(incomeRepositoryProvider)
          .createGroup(title: title, description: description);
      state = AsyncData([group, ...state.valueOrNull ?? []]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(incomeRepositoryProvider).deleteGroup(id);
      state = AsyncData(
          state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
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
  final IncomeRepository _repo;
  IncomesNotifier(this._repo) : super(const IncomesState()) {
    loadInitial();
  }

  String? _category;
  int? _groupId;

  Future<void> loadInitial({String? category, int? groupId}) async {
    _category = category;
    _groupId = groupId;
    state = const IncomesState(isLoading: true);
    try {
      final result = await _repo.getIncomes(
          category: category, incomeGroupId: groupId, page: 1);
      state = IncomesState(
        incomes: result.data,
        hasMore: result.page < result.totalPages,
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
  }) async {
    try {
      final income = await _repo.createIncome(
        title: title,
        amount: amount,
        category: category,
        incomeDate: incomeDate,
        notes: notes,
        incomeGroupId: incomeGroupId,
        imagePath: imagePath,
      );
      state = state.copyWith(incomes: [income, ...state.incomes]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.deleteIncome(id);
      state =
          state.copyWith(incomes: state.incomes.where((i) => i.id != id).toList());
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
      String? notes}) async {
    try {
      final updated = await _repo.updateIncome(id,
          title: title,
          amount: amount,
          category: category,
          incomeDate: incomeDate,
          notes: notes);
      state = state.copyWith(
          incomes: state.incomes.map((i) => i.id == id ? updated : i).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final incomesProvider =
    StateNotifierProvider<IncomesNotifier, IncomesState>((ref) {
  return IncomesNotifier(ref.read(incomeRepositoryProvider));
});

// ─── Bills ───────────────────────────────────────────────────────────────────
final billsProvider = AsyncNotifierProvider<BillsNotifier, List<BillModel>>(
    BillsNotifier.new);

class BillsNotifier extends AsyncNotifier<List<BillModel>> {
  @override
  Future<List<BillModel>> build() async {
    return ref.read(billRepositoryProvider).getBills();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(billRepositoryProvider).getBills());
  }

  Future<bool> create(
      {required String title,
      required double amount,
      required int dueDay,
      String? notes}) async {
    try {
      final bill = await ref.read(billRepositoryProvider).createBill(
          title: title, amount: amount, dueDay: dueDay, notes: notes);
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
      String? notes}) async {
    try {
      final updated = await ref.read(billRepositoryProvider).updateBill(id,
          title: title, amount: amount, dueDay: dueDay, notes: notes);
      state = AsyncData(state.valueOrNull
              ?.map((b) => b.id == id ? updated : b)
              .toList() ??
          []);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(billRepositoryProvider).deleteBill(id);
      state = AsyncData(
          state.valueOrNull?.where((b) => b.id != id).toList() ?? []);
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
  return ref.read(billRepositoryProvider).getPaymentsForMonth(month);
});

// ─── Plans ───────────────────────────────────────────────────────────────────
final plansProvider = AsyncNotifierProvider<PlansNotifier, List<PlanModel>>(
    PlansNotifier.new);

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
      state = AsyncData(
          state.valueOrNull?.where((p) => p.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final planDetailProvider =
    FutureProvider.family<PlanWithItems, int>((ref, id) async {
  return ref.read(planRepositoryProvider).getPlan(id);
});

// ─── Analytics ───────────────────────────────────────────────────────────────
final cashFlowProvider = FutureProvider<CashFlow>((ref) async {
  final now = DateTime.now();
  final start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
  // Last day of current month: day-0 of next month
  final lastDay = DateTime(now.year, now.month % 12 + 1, 0);
  final end = DateFormat('yyyy-MM-dd').format(lastDay);
  return ref
      .read(analyticsRepositoryProvider)
      .getCashFlow(startDate: start, endDate: end);
});

final categoryAnalyticsProvider =
    FutureProvider<List<CategoryAnalytics>>((ref) async {
  final now = DateTime.now();
  final start = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
  final lastDay = DateTime(now.year, now.month % 12 + 1, 0);
  final end = DateFormat('yyyy-MM-dd').format(lastDay);
  return ref
      .read(analyticsRepositoryProvider)
      .getByCategory(startDate: start, endDate: end);
});

final monthlyTrendsProvider =
    FutureProvider<List<MonthlyTrend>>((ref) async {
  return ref.read(analyticsRepositoryProvider).getMonthlyTrends();
});
