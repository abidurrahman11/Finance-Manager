import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/expenses/expenses_screen.dart';
import 'presentation/screens/expenses/expense_form_screen.dart';
import 'presentation/screens/expenses/expense_groups_screen.dart';
import 'presentation/screens/incomes/incomes_screen.dart';
import 'presentation/screens/incomes/income_form_screen.dart';
import 'presentation/screens/incomes/income_groups_screen.dart';
import 'presentation/screens/bills/bills_screen.dart';
import 'presentation/screens/plans/plans_screen.dart';
import 'presentation/screens/plans/plan_detail_screen.dart';
import 'presentation/screens/analytics/analytics_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'data/models/expense_model.dart';
import 'data/models/income_model.dart';
import 'data/models/plan_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isUnknown = authState.status == AuthStatus.unknown;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/forgot-password');

      if (isUnknown) return null;
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // Main shell with bottom nav. 6 tabs
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (_, __) => const ExpensesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final groupId = state.extra as int?;
                  return ExpenseFormScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final expense = state.extra as ExpenseModel;
                  return ExpenseFormScreen(expense: expense);
                },
              ),
              GoRoute(
                path: 'groups',
                builder: (_, __) => const ExpenseGroupsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/incomes',
            builder: (_, __) => const IncomesScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final groupId = state.extra as int?;
                  return IncomeFormScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (_, state) {
                  final income = state.extra as IncomeModel;
                  return IncomeFormScreen(income: income);
                },
              ),
              GoRoute(
                path: 'groups',
                builder: (_, __) => const IncomeGroupsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/bills',
            builder: (_, __) => const BillsScreen(),
          ),
          GoRoute(
            path: '/plans',
            builder: (_, __) => const PlansScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final plan = state.extra as PlanModel;
                  return PlanDetailScreen(plan: plan);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({super.key, required this.child, required this.location});

  int _getIndex() {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/expenses')) return 1;
    if (location.startsWith('/incomes')) return 2;
    if (location.startsWith('/bills')) return 3;
    if (location.startsWith('/plans')) return 4;
    if (location.startsWith('/analytics')) return 5;
    return 0; // default to home for profile and other routes
  }

  @override
  Widget build(BuildContext context) {
    final idx = _getIndex();
    // Hide bottom nav on profile screen
    final showNav = !location.startsWith('/profile');

    return Scaffold(
      body: child,
      bottomNavigationBar: showNav
          ? NavigationBar(
              selectedIndex: idx,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go('/dashboard');
                  case 1:
                    context.go('/expenses');
                  case 2:
                    context.go('/incomes');
                  case 3:
                    context.go('/bills');
                  case 4:
                    context.go('/plans');
                  case 5:
                    context.go('/analytics');
                }
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.arrow_upward_outlined),
                    selectedIcon: Icon(Icons.arrow_upward),
                    label: 'Expenses'),
                NavigationDestination(
                    icon: Icon(Icons.arrow_downward_outlined),
                    selectedIcon: Icon(Icons.arrow_downward),
                    label: 'Income'),
                NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: 'Bills'),
                NavigationDestination(
                    icon: Icon(Icons.flag_outlined),
                    selectedIcon: Icon(Icons.flag),
                    label: 'Plans'),
                NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: 'Analytics'),
              ],
            )
          : null,
    );
  }
}
