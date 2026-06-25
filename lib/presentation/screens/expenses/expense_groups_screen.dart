import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/expenses/group_card.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/expense_model.dart';

/// Displays either offline groups or online (collaborative) groups — never both.
///
/// [isRemote] is set by the router:
///   false → /expenses/groups/offline  (uses [expenseGroupsProvider])
///   true  → /expenses/groups/online   (uses [sharedExpenseGroupsProvider])
class ExpenseGroupsScreen extends ConsumerWidget {
  final bool isRemote;

  const ExpenseGroupsScreen({super.key, required this.isRemote});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRemoteSession = ref.watch(authProvider).hasRemoteSession;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRemote ? 'Online Groups' : 'Offline Groups'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/groups/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
        backgroundColor: isRemote ? AppTheme.primary : AppTheme.secondary,
      ),
      body: isRemote
          ? _buildRemote(context, ref, hasRemoteSession)
          : _buildLocal(context, ref),
    );
  }

  // ── Offline groups ──────────────────────────────────────────────────────────

  Widget _buildLocal(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expenseGroupsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBody(message: e.toString()),
      data: (groups) {
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.folder_outlined,
            title: 'No offline groups yet',
            subtitle: 'Create a group to organise your personal expenses.',
            actionLabel: 'Create Group',
            onAction: () => context.push('/expenses/groups/new'),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(expenseGroupsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GroupCard(
                  group: g,
                  // Navigate to detail using the 'detail/:id' path —
                  // avoids any collision with the list routes.
                  onTap: () => context.push(
                    '/expenses/groups/detail/${g.id}',
                    extra: g,
                  ),
                  onDelete: g.isOwner
                      ? () => _confirmDelete(context, ref, g)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Online (collaborative) groups ───────────────────────────────────────────

  Widget _buildRemote(
      BuildContext context, WidgetRef ref, bool hasRemoteSession) {
    if (!hasRemoteSession) {
      return _SignInPrompt(
        onTap: () =>
            context.push('/login?returnTo=/expenses/groups/online'),
      );
    }

    final async = ref.watch(sharedExpenseGroupsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBody(message: e.toString()),
      data: (groups) {
        if (groups.isEmpty) {
          return EmptyState(
            icon: Icons.cloud_outlined,
            title: 'No online groups yet',
            subtitle:
                'Create a collaborative group to share expenses with others.',
            actionLabel: 'Create Group',
            onAction: () => context.push('/expenses/groups/new'),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(sharedExpenseGroupsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GroupCard(
                  group: g,
                  onTap: () => context.push(
                    '/expenses/groups/detail/${g.id}',
                    extra: g,
                  ),
                  onDelete: g.isOwner
                      ? () => _confirmDelete(context, ref, g)
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseGroupModel group,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Group',
      message:
          'Delete "${group.title}"? All expenses in this group will be unlinked.',
    );
    if (!ok) return;

    if (group.isRemote) {
      ref.read(sharedExpenseGroupsProvider.notifier).delete(group.id);
    } else {
      ref.read(expenseGroupsProvider.notifier).delete(group.id);
    }
  }
}

// ─── Sign-in prompt ───────────────────────────────────────────────────────────

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_outlined,
                  color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in required',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to create online groups and collaborate with others.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.login, size: 16),
              label: const Text('Sign in'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error body ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}
