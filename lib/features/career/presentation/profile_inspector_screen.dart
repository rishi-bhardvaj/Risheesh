import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/profile_auth_provider.dart';
import '../../../shared/widgets/ui_kit.dart';

class ProfileInspectorScreen extends ConsumerWidget {
  const ProfileInspectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(activeUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Inspector')),
      body: profile == null
          ? const Center(child: Text('No profile loaded'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(profile.currentRole ?? 'Candidate', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text('Status: ${profile.status ?? "PENDING"} · Admin: ${profile.isAdmin == true ? "Yes" : "No"}'),
                      Text('Permissions: ${profile.permissions ?? "None"}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'Skills & Preferences'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Skills: ${profile.skills ?? "Not set"}'),
                      const SizedBox(height: 8),
                      Text('Preferred Roles: ${profile.preferredRoles ?? "Not set"}'),
                      const SizedBox(height: 8),
                      Text('Remote: ${profile.remotePreference}'),
                      const SizedBox(height: 8),
                      Text('Expected Salary: ${profile.expectedSalary ?? "Not set"}'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
