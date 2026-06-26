import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/income_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/analytics_model.dart';
import '../../data/models/reminder_model.dart';
import '../../data/repositories/income_repository.dart';
import '../../data/repositories/reminder_repository.dart';
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
final reminderRepositoryProvider = Provider((ref) => ReminderRepository());
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

// ─── Reminders ───────────────────────────────────────────────────────────────
class RemindersState {
  final List<ReminderModel> reminders;
  final bool isLoading;
  final String? error;

  const RemindersState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  RemindersState copyWith({
    List<ReminderModel>? reminders,
    bool? isLoading,
    String? error,
  }) =>
      RemindersState(
        reminders: reminders ?? this.reminders,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class RemindersNotifier extends StateNotifier<RemindersState> {
  final ReminderRepository _repo;

  RemindersNotifier(this._repo) : super(const RemindersState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reminders = await _repo.getReminders();
      state = RemindersState(reminders: reminders);
    } catch (e) {
      state = RemindersState(error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> create({
    required String title,
    String? notes,
    required ReminderType type,
    required ReminderPriority priority,
    DateTime? dueDate,
  }) async {
    try {
      final reminder = await _repo.createReminderDirect(
        title: title,
        notes: notes,
        type: ReminderModel.typeToString(type),
        priority: ReminderModel.priorityToString(priority),
        dueDate: dueDate,
      );
      // Insert at front, then re-sort: pending first, then by created_at desc
      final updated = [reminder, ...state.reminders];
      _sortReminders(updated);
      state = state.copyWith(reminders: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update(
    int id, {
    required String title,
    String? notes,
    required ReminderType type,
    required ReminderPriority priority,
    required bool isCompleted,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    try {
      final updated = await _repo.updateReminder(
        id,
        title: title,
        notes: notes,
        type: ReminderModel.typeToString(type),
        priority: ReminderModel.priorityToString(priority),
        isCompleted: isCompleted,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
      );
      final list = state.reminders.map((r) => r.id == id ? updated : r).toList();
      _sortReminders(list);
      state = state.copyWith(reminders: list);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleCompleted(int id) async {
    final reminder = state.reminders.firstWhere((r) => r.id == id);
    final newCompleted = !reminder.isCompleted;
    try {
      await _repo.toggleCompleted(id, isCompleted: newCompleted);
      final list = state.reminders
          .map((r) => r.id == id ? r.copyWith(isCompleted: newCompleted) : r)
          .toList();
      _sortReminders(list);
      state = state.copyWith(reminders: list);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.deleteReminder(id);
      state = state.copyWith(
        reminders: state.reminders.where((r) => r.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void _sortReminders(List<ReminderModel> list) {
    list.sort((a, b) {
      // Pending before completed
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // Among pending: high priority first
      if (!a.isCompleted) {
        final pa = _priorityOrder(a.priority);
        final pb = _priorityOrder(b.priority);
        if (pa != pb) return pa.compareTo(pb);
      }
      // Then by created_at descending
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  int _priorityOrder(ReminderPriority p) {
    switch (p) {
      case ReminderPriority.high:
        return 0;
      case ReminderPriority.medium:
        return 1;
      case ReminderPriority.low:
        return 2;
    }
  }
}

final remindersProvider =
    StateNotifierProvider<RemindersNotifier, RemindersState>((ref) {
  return RemindersNotifier(ref.read(reminderRepositoryProvider));
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
