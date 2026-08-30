import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/remote_expense_repository.dart';
import 'auth_provider.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());
final remoteExpenseRepositoryProvider =
    Provider((ref) => RemoteExpenseRepository());

// ─── Expense Groups ───────────────────────────────────────────────────────────

final expenseGroupsProvider =
    AsyncNotifierProvider<ExpenseGroupsNotifier, List<ExpenseGroupModel>>(
        ExpenseGroupsNotifier.new);

final sharedExpenseGroupsProvider =
    AsyncNotifierProvider<SharedExpenseGroupsNotifier, List<ExpenseGroupModel>>(
        SharedExpenseGroupsNotifier.new);

class ExpenseGroupsNotifier extends AsyncNotifier<List<ExpenseGroupModel>> {
  @override
  Future<List<ExpenseGroupModel>> build() async {
    return ref.read(expenseRepositoryProvider).getGroups();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(expenseRepositoryProvider).getGroups());
  }

  Future<bool> create({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final group = await ref.read(expenseRepositoryProvider).createGroup(
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
      await ref.read(expenseRepositoryProvider).deleteGroup(id);
      state = AsyncData(
          state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class SharedExpenseGroupsNotifier
    extends AsyncNotifier<List<ExpenseGroupModel>> {
  @override
  Future<List<ExpenseGroupModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.hasRemoteSession) return const [];
    return ref.read(remoteExpenseRepositoryProvider).getGroups();
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (!auth.hasRemoteSession) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(remoteExpenseRepositoryProvider).getGroups());
  }

  Future<bool> create({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final group =
          await ref.read(remoteExpenseRepositoryProvider).createGroup(
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
      await ref.read(remoteExpenseRepositoryProvider).deleteGroup(id);
      state = AsyncData(
          state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Shared expenses state ────────────────────────────────────────────────────

class ExpensesState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ExpensesState({
    this.expenses = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  ExpensesState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) =>
      ExpensesState(
        expenses: expenses ?? this.expenses,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        error: error,
      );
}

// ─── All Expenses (personal + group, local + remote) ─────────────────────────

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _localRepo;
  final RemoteExpenseRepository _remoteRepo;
  final bool _isOnline;

  ExpensesNotifier(this._localRepo, this._remoteRepo, this._isOnline)
      : super(const ExpensesState()) {
    loadInitial();
  }

  String? _category;
  int? _groupId;

  Future<void> loadInitial({String? category, int? groupId}) async {
    _category = category;
    _groupId = groupId;
    state = const ExpensesState(isLoading: true);
    try {
      final localResult = await _localRepo.getExpenses(
        category: category,
        expenseGroupId: groupId,
        page: 1,
      );

      var merged = localResult.data;
      var hasMore = localResult.page < localResult.totalPages;

      if (_isOnline) {
        try {
          final remoteResult = await _remoteRepo.getExpenses(
            category: category,
            expenseGroupId: groupId,
            page: 1,
          );
          merged = [...merged, ...remoteResult.data]
            ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          hasMore = hasMore || remoteResult.page < remoteResult.totalPages;
        } catch (_) {}
      }

      state = ExpensesState(
        expenses: merged,
        hasMore: hasMore,
        currentPage: 1,
      );
    } catch (e) {
      state = ExpensesState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final localResult = await _localRepo.getExpenses(
        category: _category,
        expenseGroupId: _groupId,
        page: nextPage,
      );

      var more = localResult.data;
      var hasMore = nextPage < localResult.totalPages;

      if (_isOnline) {
        try {
          final remoteResult = await _remoteRepo.getExpenses(
            category: _category,
            expenseGroupId: _groupId,
            page: nextPage,
          );
          more = [...more, ...remoteResult.data];
          hasMore = hasMore || nextPage < remoteResult.totalPages;
        } catch (_) {}
      }

      state = state.copyWith(
        expenses: ([...state.expenses, ...more]
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate))),
        hasMore: hasMore,
        currentPage: nextPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
    String? imagePath,
    bool isRemote = false,
  }) async {
    try {
      final expense = isRemote && _isOnline
          ? await _remoteRepo.createExpense(
              title: title,
              amount: amount,
              category: category,
              expenseDate: expenseDate,
              notes: notes,
              expenseGroupId: expenseGroupId,
            )
          : await _localRepo.createExpense(
              title: title,
              amount: amount,
              category: category,
              expenseDate: expenseDate,
              notes: notes,
              expenseGroupId: expenseGroupId,
              imagePath: imagePath,
            );

      state = state.copyWith(
        expenses: ([expense, ...state.expenses]
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate))),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update(
    int id, {
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    int? expenseGroupId,
    String? imagePath,
    bool isRemote = false,
  }) async {
    try {
      final updated = isRemote && _isOnline
          ? await _remoteRepo.updateExpense(id,
              title: title,
              amount: amount,
              category: category,
              expenseDate: expenseDate,
              notes: notes,
              expenseGroupId: expenseGroupId)
          : await _localRepo.updateExpense(id,
              title: title,
              amount: amount,
              category: category,
              expenseDate: expenseDate,
              notes: notes,
              expenseGroupId: expenseGroupId,
              imagePath: imagePath);

      state = state.copyWith(
        expenses: state.expenses
            .map((e) => (e.id == id && e.isRemote == isRemote) ? updated : e)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id, {bool isRemote = false}) async {
    try {
      if (isRemote && _isOnline) {
        await _remoteRepo.deleteExpense(id);
      } else {
        await _localRepo.deleteExpense(id);
      }
      state = state.copyWith(
        expenses: state.expenses
            .where((e) => !(e.id == id && e.isRemote == isRemote))
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// All expenses (personal + group, local + remote).
/// Used by [ExpensesHubScreen] recent strip.
final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  final auth = ref.watch(authProvider);
  return ExpensesNotifier(
    ref.read(expenseRepositoryProvider),
    ref.read(remoteExpenseRepositoryProvider),
    auth.hasRemoteSession,
  );
});

// ─── Personal Expenses (offline only, no group) ───────────────────────────────

/// Personal-only expenses — local only, [expenseGroupId] is null.
///
/// Fetches all local expenses then filters client-side to [expenseGroupId] == null
/// because the local SQLite repo treats null as "no filter" (not "where null").
final personalExpensesProvider =
    StateNotifierProvider<PersonalExpensesNotifier, ExpensesState>((ref) {
  return PersonalExpensesNotifier(ref.read(expenseRepositoryProvider));
});

class PersonalExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _repo;

  PersonalExpensesNotifier(this._repo) : super(const ExpensesState()) {
    loadInitial();
  }

  String? _category;

  Future<void> loadInitial({String? category}) async {
    _category = category;
    state = const ExpensesState(isLoading: true);
    try {
      final result = await _repo.getExpenses(
        category: category,
        page: 1,
        limit: 200,
      );
      // Filter to personal-only (no group) client-side
      final personal =
          result.data.where((e) => e.expenseGroupId == null).toList();
      state = ExpensesState(
        expenses: personal,
        hasMore: false,
        currentPage: 1,
      );
    } catch (e) {
      state = ExpensesState(error: e.toString());
    }
  }

  // Personal list is always loaded fully in one shot — no pagination needed
  Future<void> loadMore() async {}

  Future<bool> create({
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final expense = await _repo.createExpense(
        title: title,
        amount: amount,
        category: category,
        expenseDate: expenseDate,
        notes: notes,
        expenseGroupId: null,
        imagePath: imagePath,
      );
      state = state.copyWith(
        expenses: ([expense, ...state.expenses]
          ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate))),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> update(
    int id, {
    required String title,
    required double amount,
    required String category,
    DateTime? expenseDate,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final updated = await _repo.updateExpense(
        id,
        title: title,
        amount: amount,
        category: category,
        expenseDate: expenseDate,
        notes: notes,
        expenseGroupId: null,
        imagePath: imagePath,
      );
      state = state.copyWith(
        expenses:
            state.expenses.map((e) => e.id == id ? updated : e).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.deleteExpense(id);
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ─── Group expenses ───────────────────────────────────────────────────────────

/// Expenses for a local (offline) group. Keyed by group ID.
/// Used by [GroupDetailScreen] when [group.isRemote] == false.
final localGroupExpensesProvider =
    FutureProvider.family<List<ExpenseModel>, int>((ref, groupId) async {
  final result = await ref
      .read(expenseRepositoryProvider)
      .getExpenses(expenseGroupId: groupId);
  return result.data;
});

/// Expenses for a remote (collaborative) group. Keyed by group ID.
/// Used by [GroupDetailScreen] when [group.isRemote] == true.
final remoteGroupExpensesProvider =
    FutureProvider.family<List<ExpenseModel>, int>((ref, groupId) async {
  final result = await ref
      .read(remoteExpenseRepositoryProvider)
      .getExpenses(expenseGroupId: groupId);
  return result.data;
});

// ─── Collaborators ────────────────────────────────────────────────────────────

/// Collaborators for a remote group. Used by [GroupDetailScreen] collaborators tab.
final sharedExpenseCollaboratorsProvider =
    FutureProvider.family<List<CollaboratorModel>, int>((ref, groupId) async {
  return ref.read(remoteExpenseRepositoryProvider).getCollaborators(groupId);
});
