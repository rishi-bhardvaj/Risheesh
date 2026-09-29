import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/profile_auth_provider.dart';
import '../../features/settings/presentation/widgets/profile_switcher_sheet.dart';

class PermissionGuard extends ConsumerWidget {
  final String service;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.service,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(activeUserProfileProvider).valueOrNull;

    // If profile is still loading or doesn't exist yet, allow child (first run onboarding handles it)
    if (user == null) {
      return child;
    }

    // Admin has full access
    if (user.isUserAdmin) {
      return child;
    }

    // Pending account
    if (user.isPending) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded, size: 48, color: Colors.amber.shade600),
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Pending Approval',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome, ${user.name}! Your account has been registered and is currently waiting for administrator approval and service assignments.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch Account'),
                  onPressed: () => ProfileSwitcherSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Rejected account
    if (user.isRejected) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded, size: 48, color: Colors.redAccent),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This account does not have permission to access Risheesh platform services.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch Account'),
                  onPressed: () => ProfileSwitcherSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Approved account: check specific service permission
    if (!user.hasPermission(service)) {
      final serviceName = switch (service) {
        'jobs' => 'Jobs & Applications',
        'freelance' => 'Freelance Radar',
        'dsa' => 'DSA & LeetCode Bank',
        'habits' => 'Daily Habits & Reflections',
        'ai' => 'AI Intelligence',
        'resumes' => 'Resume Vault',
        _ => service,
      };

      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 48, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  '$serviceName Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You currently do not have access to $serviceName. Please contact your administrator to enable this service for your profile.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.switch_account_rounded),
                  label: const Text('Switch Account'),
                  onPressed: () => ProfileSwitcherSheet.show(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
