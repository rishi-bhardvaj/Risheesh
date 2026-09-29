import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/profile_auth_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/notification_service.dart';

class ProfileSwitcherSheet extends ConsumerWidget {
  const ProfileSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ProfileSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allProfiles = ref.watch(allProfilesStreamProvider).valueOrNull ?? [];
    final currentProfile = ref.watch(activeUserProfileProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Switch Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Select which profile to use on this device, or register a new one.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allProfiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final profile = allProfiles[index];
                final isActive = currentProfile?.id == profile.id;

                final badgeColor = switch (profile.status) {
                  'APPROVED' => Colors.green,
                  'PENDING' => Colors.orange,
                  'REJECTED' => Colors.red,
                  _ => Colors.grey,
                };

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  tileColor: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : null,
                  leading: CircleAvatar(
                    backgroundColor: profile.isAdmin == true
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: profile.isAdmin == true
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isAdmin == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade900.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          profile.status ?? 'PENDING',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    profile.email ?? profile.currentRole ?? 'Candidate Profile',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: isActive
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () async {
                    await ref.read(activeProfileIdProvider.notifier).setActiveProfileId(profile.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Register New User Account'),
            onPressed: () {
              Navigator.pop(context);
              _showNewUserDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  static void _showNewUserDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *', hintText: 'Your Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'name@example.com'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Role', hintText: 'e.g. Flutter Engineer'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final db = ref.read(databaseProvider);
              final id = const Uuid().v4();

              await db.registerNewProfile(
                id: id,
                name: name,
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                currentRole: roleCtrl.text.trim().isEmpty ? null : roleCtrl.text.trim(),
              );

              // Notify Admin of registration
              final notif = ref.read(notificationServiceProvider);
              await notif.notifyAdminNewUser(
                userId: id,
                name: name,
                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
              );

              // Switch to this new profile
              await ref.read(activeProfileIdProvider.notifier).setActiveProfileId(id);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registered $name. Awaiting administrator approval.')),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
