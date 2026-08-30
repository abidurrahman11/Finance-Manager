import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/verify_email_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/expenses/expenses_hub_screen.dart';
import 'presentation/screens/expenses/expense_form_screen.dart';
import 'presentation/screens/expenses/expense_groups_screen.dart';
import 'presentation/screens/expenses/create_group_screen.dart';
import 'presentation/screens/expenses/group_detail_screen.dart';
import 'presentation/screens/incomes/incomes_hub_screen.dart';
import 'presentation/screens/incomes/income_form_screen.dart';
import 'presentation/screens/incomes/income_groups_screen.dart';
import 'presentation/screens/incomes/create_income_group_screen.dart';
import 'presentation/screens/incomes/income_group_detail_screen.dart';
import 'presentation/screens/bills/bills_screen.dart';
import 'presentation/screens/plans/plans_screen.dart';
import 'presentation/screens/plans/plan_detail_screen.dart';
import 'presentation/screens/analytics/analytics_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'data/models/expense_model.dart';
import 'data/models/income_model.dart';
import 'data/models/plan_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      // ── Auth routes ───────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) => RegisterScreen(
          returnTo: state.uri.queryParameters['returnTo'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const VerifyEmailScreen(),
      ),

      // ── Analytics — pushed route (not a nav-bar tab) ──────────────────────
      GoRoute(
        path: '/analytics',
        builder: (_, __) => const AnalyticsScreen(),
      ),

      // ── Profile — pushed route (not a nav-bar tab) ────────────────────────
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── Main shell with bottom nav (5 tabs) ───────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.matchedLocation, child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),

          // ── Expenses ───────────────────────────────────────────────────────
          GoRoute(
            path: '/expenses',
            builder: (_, __) => const ExpensesHubScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final group = state.extra is ExpenseGroupModel
                      ? state.extra as ExpenseGroupModel
                      : null;
                  return ExpenseFormScreen(group: group);
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
                path: 'groups/offline',
                builder: (_, __) =>
                    const ExpenseGroupsScreen(isRemote: false),
              ),
              GoRoute(
                path: 'groups/online',
                builder: (_, __) =>
                    const ExpenseGroupsScreen(isRemote: true),
              ),
              GoRoute(
                path: 'groups/new',
                builder: (_, __) => const CreateGroupScreen(),
              ),
              GoRoute(
                path: 'groups/detail/:id',
                builder: (_, state) {
                  final group = state.extra as ExpenseGroupModel;
                  return GroupDetailScreen(group: group);
                },
              ),
            ],
          ),

          // ── Incomes ────────────────────────────────────────────────────────
          GoRoute(
            path: '/incomes',
            builder: (_, __) => const IncomesHubScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) {
                  final group = state.extra is IncomeGroupModel
                      ? state.extra as IncomeGroupModel
                      : null;
                  return IncomeFormScreen(group: group);
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
                path: 'groups/offline',
                builder: (_, __) =>
                    const IncomeGroupsScreen(isRemote: false),
              ),
              GoRoute(
                path: 'groups/online',
                builder: (_, __) =>
                    const IncomeGroupsScreen(isRemote: true),
              ),
              GoRoute(
                path: 'groups/new',
                builder: (_, __) => const CreateIncomeGroupScreen(),
              ),
              GoRoute(
                path: 'groups/detail/:id',
                builder: (_, state) {
                  final group = state.extra as IncomeGroupModel;
                  return IncomeGroupDetailScreen(group: group);
                },
              ),
            ],
          ),

          // ── Reminders ──────────────────────────────────────────────────────
          GoRoute(
            path: '/bills',
            builder: (_, __) => const RemindersScreen(),
          ),

          // ── Plans ──────────────────────────────────────────────────────────
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
        ],
      ),
    ],
  );
});

// ─── Main shell ───────────────────────────────────────────────────────────────

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
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _getIndex();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
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
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_upward_outlined),
            selectedIcon: Icon(Icons.arrow_upward),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_downward_outlined),
            selectedIcon: Icon(Icons.arrow_downward),
            label: 'Income',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Plans',
          ),
        ],
      ),
    );
  }
}
