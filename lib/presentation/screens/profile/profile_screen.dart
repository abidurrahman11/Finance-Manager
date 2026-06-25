import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final hasRemoteSession = auth.hasRemoteSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E3A), Color(0xFF151540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(
                          hasRemoteSession && user?.isVerified == true
                              ? Icons.verified
                              : Icons.phone_android_outlined,
                          size: 14,
                          color: hasRemoteSession && user?.isVerified == true
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasRemoteSession
                              ? (user?.isVerified == true
                                  ? 'Verified account'
                                  : 'Email not verified')
                              : 'Offline local mode',
                          style: TextStyle(
                              fontSize: 12,
                              color: hasRemoteSession && user?.isVerified == true
                                  ? AppTheme.success
                                  : AppTheme.textSecondary),
                        ),
                        if (hasRemoteSession && user?.isVerified == false) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/verify-email'),
                            child: const Text(
                              'Verify Now',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Settings section
          const Text('Account',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),

          _SettingsCard(children: [
            if (hasRemoteSession) ...[
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _showChangePassword(context, ref),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.email_outlined,
                label: 'Forgot / Reset Password',
                onTap: () => context.push('/forgot-password'),
              ),
            ] else ...[
              _SettingsTile(
                icon: Icons.login,
                label: 'Sign In for Online Features',
                onTap: () => context.push('/login?returnTo=/profile'),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.person_add_alt_outlined,
                label: 'Create Online Account',
                onTap: () => context.push('/register?returnTo=/profile'),
              ),
            ],
          ]),

          const SizedBox(height: 16),

          const Text('App',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),

          _SettingsCard(children: [
            _SettingsTile(
              icon: Icons.bar_chart_outlined,
              label: 'Analytics',
              onTap: () => context.go('/analytics'),
            ),
            const Divider(height: 1, indent: 52),
            _SettingsTile(
              icon: Icons.flag_outlined,
              label: 'Budget Plans',
              onTap: () => context.go('/plans'),
            ),
            const Divider(height: 1, indent: 52),
            _SettingsTile(
              icon: Icons.receipt_long_outlined,
              label: 'Recurring Bills',
              onTap: () => context.go('/bills'),
            ),
          ]),

          const SizedBox(height: 24),

          // App info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finance Manager',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      Text('Version 1.0.0',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          if (hasRemoteSession)
            AppButton(
              label: 'Sign Out',
              icon: Icons.logout,
              color: AppTheme.error,
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Sign Out',
                  message:
                      'Sign out of your online account? Local finance data stays on this device.',
                  confirmLabel: 'Sign Out',
                  confirmColor: AppTheme.error,
                );
                if (ok && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscure = true;

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
            const Text('Change Password',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Current Password',
              controller: oldCtrl,
              obscureText: obscure,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.textSecondary),
                onPressed: () => setLocal(() => obscure = !obscure),
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'New Password',
              controller: newCtrl,
              obscureText: obscure,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Confirm New Password',
              controller: confirmCtrl,
              obscureText: obscure,
              prefixIcon: const Icon(Icons.lock_outline,
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Update Password',
              icon: Icons.save,
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: AppTheme.error));
                  return;
                }
                if (newCtrl.text.length < 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Password must be at least 6 chars'),
                      backgroundColor: AppTheme.error));
                  return;
                }
                final ok = await ref
                    .read(authProvider.notifier)
                    .changePassword(oldCtrl.text, newCtrl.text);
                if (ok && ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: AppTheme.success));
                } else if (ctx.mounted) {
                  final err = ref.read(authProvider).error;
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(err ?? 'Failed to change password'),
                      backgroundColor: AppTheme.error));
                }
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const c = AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 16),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: c, fontSize: 15))),
          Icon(Icons.chevron_right,
              color: AppTheme.textSecondary.withValues(alpha: 0.5), size: 20),
        ]),
      ),
    );
  }
}
