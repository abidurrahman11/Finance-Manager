import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../../core/constants/app_theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _resent = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isLoading = auth.isLoading;

    if (user != null && user.isVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, color: AppTheme.success, size: 64),
              const SizedBox(height: 16),
              const Text('Email Verified!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              AppButton(
                label: 'Go to Dashboard',
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(authProvider.notifier).refreshUser(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: AppTheme.primary, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Verify your email',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to ${user?.email ?? 'your email'}. Please check your inbox and click the link to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),
              AppButton(
                label: _resent ? 'Sent Again' : 'Resend Verification Email',
                onPressed: _resent || isLoading
                    ? null
                    : () async {
                        if (user != null) {
                          final ok = await ref
                              .read(authProvider.notifier)
                              .resendVerification(user.email);
                          if (ok) {
                            if (!context.mounted) return;
                            setState(() => _resent = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        }
                      },
                isLoading: isLoading,
                icon: Icons.send,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).refreshUser(),
                child: const Text('I have verified my email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Sign out and use offline',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
