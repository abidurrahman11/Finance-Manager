import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final hasRemoteSession = auth.hasRemoteSession;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: hasRemoteSession
          ? _LoggedInView(auth: auth)
          : const _LoggedOutView(),
    );
  }
}

// ─── Logged-out view ──────────────────────────────────────────────────────────

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero illustration
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person_outline,
                    size: 36, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'You\'re using Finance Manager offline',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in or create a free account to unlock\nmore powerful features.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ]),
          ),

          const SizedBox(height: 28),

          // Benefits
          const _SectionLabel('Why create an account?'),
          const SizedBox(height: 12),

          const _BenefitCard(
            icon: Icons.sync_outlined,
            color: AppTheme.primary,
            title: 'Sync across devices',
            subtitle:
                'Your expenses, income and plans stay in sync everywhere you sign in.',
          ),
          const SizedBox(height: 10),
          const _BenefitCard(
            icon: Icons.group_outlined,
            color: AppTheme.secondary,
            title: 'Collaborative expense groups',
            subtitle:
                'Share expense or income groups with family or teammates and track together.',
          ),
          const SizedBox(height: 10),
          const _BenefitCard(
            icon: Icons.cloud_done_outlined,
            color: AppTheme.success,
            title: 'Secure cloud backup',
            subtitle:
                'Never lose your data — everything is safely stored on the server.',
          ),
          const SizedBox(height: 10),
          const _BenefitCard(
            icon: Icons.bar_chart_outlined,
            color: AppTheme.warning,
            title: 'Cross-device analytics',
            subtitle:
                'See combined analytics from all your devices in one place.',
          ),

          const SizedBox(height: 28),

          // CTA buttons
          ElevatedButton.icon(
            onPressed: () => context.push('/login?returnTo=/profile'),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Sign In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/register?returnTo=/profile'),
            icon: const Icon(Icons.person_add_alt_outlined, size: 18),
            label: const Text('Create Free Account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 28),

          // App version footer
          const _AppFooter(),
        ],
      ),
    );
  }
}

// ─── Logged-in view ───────────────────────────────────────────────────────────

class _LoggedInView extends ConsumerWidget {
  final AuthState auth;

  const _LoggedInView({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = auth.user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E3A), Color(0xFF151530)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              // Avatar with edit overlay
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditProfileSheet(context, ref, user.name),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF151530), width: 2),
                      ),
                      child: const Icon(Icons.edit,
                          size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Email with copy-to-clipboard
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: user.email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      user.email,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Verification badge
              _VerificationBadge(
                isVerified: user.isVerified,
                onVerifyTap: () => context.push('/verify-email'),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // Account info tiles
          const _SectionLabel('Account Details'),
          const SizedBox(height: 10),
          _InfoCard(children: [
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Display Name',
              value: user.name,
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: AppTheme.primary),
                onPressed: () =>
                    _showEditProfileSheet(context, ref, user.name),
                tooltip: 'Edit name',
              ),
            ),
            const _InfoDivider(),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            const _InfoDivider(),
            _InfoRow(
              icon: Icons.fingerprint_outlined,
              label: 'Account ID',
              value: '#${user.id}',
            ),
          ]),

          const SizedBox(height: 20),

          // Security section
          const _SectionLabel('Security'),
          const SizedBox(height: 10),
          _ActionCard(children: [
            _ActionTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => _showChangePasswordSheet(context, ref),
            ),
            const _ActionDivider(),
            _ActionTile(
              icon: Icons.vpn_key_outlined,
              label: 'Forgot / Reset Password',
              onTap: () => context.push('/forgot-password'),
            ),
            if (!user.isVerified) ...[
              const _ActionDivider(),
              _ActionTile(
                icon: Icons.mark_email_unread_outlined,
                label: 'Resend Verification Email',
                color: AppTheme.warning,
                onTap: () => context.push('/verify-email'),
              ),
            ],
          ]),

          const SizedBox(height: 28),

          // Sign out
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),

          // App footer
          const _AppFooter(),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sign Out',
      message:
          'Sign out of your online account? Your local finance data stays on this device.',
      confirmLabel: 'Sign Out',
      confirmColor: AppTheme.error,
    );
    if (ok && context.mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  void _showEditProfileSheet(
      BuildContext context, WidgetRef ref, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProfileSheet(currentName: currentName, ref: ref),
    );
  }

  void _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ChangePasswordSheet(ref: ref),
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  final WidgetRef ref;

  const _EditProfileSheet({required this.currentName, required this.ref});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Edit Display Name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your email address cannot be changed.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Display Name',
            hint: 'Enter your name',
            controller: _nameCtrl,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Save Changes',
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (name == widget.currentName) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    final ok =
        await widget.ref.read(authProvider.notifier).updateProfile(name: name);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      final err = widget.ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to update profile'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  final WidgetRef ref;

  const _ChangePasswordSheet({required this.ref});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Show passwords' : 'Hide passwords',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Current Password',
            controller: _oldCtrl,
            obscureText: _obscure,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'New Password',
            controller: _newCtrl,
            obscureText: _obscure,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Confirm New Password',
            controller: _confirmCtrl,
            obscureText: _obscure,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Update Password',
            icon: Icons.save_outlined,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final oldPass = _oldCtrl.text;
    final newPass = _newCtrl.text;
    final confirmPass = _confirmCtrl.text;

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all fields'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('New passwords do not match'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password must be at least 6 characters'),
        backgroundColor: AppTheme.warning,
      ));
      return;
    }

    setState(() => _saving = true);
    final ok = await widget.ref
        .read(authProvider.notifier)
        .changePassword(oldPass, newPass);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: AppTheme.success,
      ));
    } else {
      final err = widget.ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Failed to change password'),
        backgroundColor: AppTheme.error,
      ));
    }
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final VoidCallback onVerifyTap;

  const _VerificationBadge(
      {required this.isVerified, required this.onVerifyTap});

  @override
  Widget build(BuildContext context) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 14, color: AppTheme.success),
            SizedBox(width: 5),
            Text(
              'Verified account',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onVerifyTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_outlined,
                size: 14, color: AppTheme.warning),
            SizedBox(width: 5),
            Text(
              'Email not verified — Tap to verify',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 48, endIndent: 0,
        color: AppTheme.divider);
  }
}

class _ActionCard extends StatelessWidget {
  final List<Widget> children;

  const _ActionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
            size: 20,
          ),
        ]),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 50, color: AppTheme.divider);
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _BenefitCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finance Manager',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ]),
    );
  }
}
