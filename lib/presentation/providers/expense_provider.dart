import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider((ref) => ExpenseRepository());

// Expense Groups
final expenseGroupsProvider =
    AsyncNotifierProvider<ExpenseGroupsNotifier, List<ExpenseGroupModel>>(
        ExpenseGroupsNotifier.new);

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
    } catch (e) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await ref.read(expenseRepositoryProvider).deleteGroup(id);
      state = AsyncData(
          state.valueOrNull?.where((g) => g.id != id).toList() ?? []);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Expenses list state
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
  }) {
    return ExpensesState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  final ExpenseRepository _repo;

  ExpensesNotifier(this._repo) : super(const ExpensesState()) {
    loadInitial();
  }

  String? _category;
  int? _groupId;

  Future<void> loadInitial({String? category, int? groupId}) async {
    _category = category;
    _groupId = groupId;
    state = const ExpensesState(isLoading: true);
    try {
      final result = await _repo.getExpenses(
        category: category,
        expenseGroupId: groupId,
        page: 1,
      );
      state = ExpensesState(
        expenses: result.data,
        hasMore: result.page < result.totalPages,
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
      final result = await _repo.getExpenses(
        category: _category,
        expenseGroupId: _groupId,
        page: nextPage,
      );
      state = state.copyWith(
        expenses: [...state.expenses, ...result.data],
        hasMore: nextPage < result.totalPages,
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
  }) async {
    try {
      final expense = await _repo.createExpense(
        title: title,
        amount: amount,
        category: category,
        expenseDate: expenseDate,
        notes: notes,
        expenseGroupId: expenseGroupId,
        imagePath: imagePath,
      );
      state = state.copyWith(expenses: [expense, ...state.expenses]);
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
  }) async {
    try {
      final updated = await _repo.updateExpense(
        id,
        title: title,
        amount: amount,
        category: category,
        expenseDate: expenseDate,
        notes: notes,
        expenseGroupId: expenseGroupId,
        imagePath: imagePath,
      );
      state = state.copyWith(
        expenses: state.expenses.map((e) => e.id == id ? updated : e).toList(),
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
          expenses: state.expenses.where((e) => e.id != id).toList());
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, ExpensesState>((ref) {
  return ExpensesNotifier(ref.read(expenseRepositoryProvider));
});
