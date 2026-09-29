import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/profile_auth_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _filter = 'ALL'; // ALL, PENDING, APPROVED

  static const _availableServices = [
    {'id': 'jobs', 'label': 'Jobs & Applications', 'icon': Icons.work_rounded},
    {'id': 'freelance', 'label': 'Freelance Radar', 'icon': Icons.storefront_rounded},
    {'id': 'dsa', 'label': 'DSA Problem Bank', 'icon': Icons.code_rounded},
    {'id': 'habits', 'label': 'Daily Habits & Reflection', 'icon': Icons.check_circle_outline_rounded},
    {'id': 'ai', 'label': 'AI Intelligence & Keys', 'icon': Icons.auto_awesome_rounded},
    {'id': 'resumes', 'label': 'Resume Vault & ATS', 'icon': Icons.description_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allProfilesAsync = ref.watch(allProfilesStreamProvider);
    final currentProfile = ref.watch(activeUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Accounts & RBAC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Register New User',
            onPressed: () => _showAddUserSheet(context),
          ),
        ],
      ),
      body: allProfilesAsync.when(
        data: (profiles) {
          final pendingCount = profiles.where((p) => p.status == 'PENDING').length;

          final filtered = profiles.where((p) {
            if (_filter == 'PENDING') return p.status == 'PENDING';
            if (_filter == 'APPROVED') return p.status == 'APPROVED';
            return true;
          }).toList();

          return CustomScrollView(
            slivers: [
              if (pendingCount > 0)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.pending_actions_rounded, color: Colors.amber.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$pendingCount Registration${pendingCount > 1 ? "s" : ""} Pending Approval',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Grant individual service permissions to give them access to the platform.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${profiles.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PENDING', 'Pending ($pendingCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('APPROVED', 'Approved (${profiles.length - pendingCount})'),
                    ],
                  ),
                ),
              ),

              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No users matching $_filter', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = filtered[index];
                        final isSelf = currentProfile?.id == user.id;
                        return _buildUserCard(context, user, isSelf);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profiles: $err')),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildUserCard(BuildContext context, UserProfile user, bool isSelf) {
    final theme = Theme.of(context);
    final db = ref.read(databaseProvider);
    final statusColor = switch (user.status) {
      'APPROVED' => Colors.green,
      'PENDING' => Colors.orange,
      'REJECTED' => Colors.red,
      _ => Colors.grey,
    };

    final userPerms = (user.permissions ?? '').split(',').map((s) => s.trim().toLowerCase()).toSet();
    final hasAll = user.isAdmin == true || user.permissions == 'ALL';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: user.status == 'PENDING'
              ? Colors.orange.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: user.status == 'PENDING',
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin == true ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: user.isAdmin == true ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          user.name + (isSelf ? ' (You)' : ''),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (user.isAdmin == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade900.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.shade400, width: 0.8),
                      ),
                      child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor, width: 0.8),
                    ),
                    child: Text(
                      user.status ?? 'PENDING',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${user.email ?? "No email"} · ${user.currentRole ?? "Candidate"}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                'Joined: ${DateFormat.yMMMd().format(user.createdAt)}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Service Permissions',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (user.isAdmin != true)
                      TextButton.icon(
                        icon: const Icon(Icons.select_all_rounded, size: 16),
                        label: const Text('Grant All'),
                        onPressed: () async {
                          await db.setProfilePermissions(user.id, 'ALL');
                          if (user.status == 'PENDING') {
                            await db.setProfileStatus(user.id, 'APPROVED');
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Granted full access to ${user.name}')),
                            );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (user.isAdmin == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Administrator accounts have unrestricted access to all services.',
                      style: TextStyle(color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableServices.map((svc) {
                      final svcId = svc['id'] as String;
                      final isGranted = hasAll || userPerms.contains(svcId);

                      return FilterChip(
                        avatar: Icon(
                          svc['icon'] as IconData,
                          size: 16,
                          color: isGranted ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                        ),
                        label: Text(svc['label'] as String),
                        selected: isGranted,
                        onSelected: (val) async {
                          final currentSet = hasAll
                              ? _availableServices.map((s) => s['id'] as String).toSet()
                              : Set<String>.from(userPerms);

                          if (val) {
                            currentSet.add(svcId);
                          } else {
                            currentSet.remove(svcId);
                          }

                          final newPerms = currentSet.join(',');
                          await db.setProfilePermissions(user.id, newPerms);
                        },
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Approval and Account Action Buttons with responsive Wrap
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (user.status == 'PENDING') ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                        onPressed: () async {
                          final perms = user.permissions == null || user.permissions!.isEmpty
                              ? 'jobs,freelance,dsa,habits,ai,resumes'
                              : user.permissions!;
                          await db.setProfilePermissions(user.id, perms);
                          await db.setProfileStatus(user.id, 'APPROVED');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user.name} approved with active permissions.')),
                            );
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.block_rounded, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          await db.setProfileStatus(user.id, 'REJECTED');
                          await db.setProfilePermissions(user.id, '');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${user.name} access rejected.')),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      if (!isSelf)
                        OutlinedButton(
                          onPressed: () async {
                            final newAdmin = !(user.isAdmin ?? false);
                            await (db.update(db.userProfiles)..where((p) => p.id.equals(user.id))).write(
                              UserProfilesCompanion(
                                isAdmin: Value(newAdmin),
                                permissions: Value(newAdmin ? 'ALL' : user.permissions),
                              ),
                            );
                          },
                          child: Text(user.isAdmin == true ? 'Revoke Admin' : 'Make Admin'),
                        ),
                      if (!isSelf)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete User Account',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Delete ${user.name}?'),
                                content: const Text('This will permanently delete this profile and access history.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await db.deleteProfile(user.id);
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Software Engineer');
    bool autoApprove = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Register New Account', style: Theme.of(ctx).textTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Current / Desired Role', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Pre-approve access immediately'),
                subtitle: const Text('If unchecked, user starts as PENDING until you approve'),
                value: autoApprove,
                onChanged: (v) => setSheetState(() => autoApprove = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
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

                  if (autoApprove) {
                    await db.setProfileStatus(id, 'APPROVED');
                    await db.setProfilePermissions(id, 'jobs,freelance,dsa,habits,ai,resumes');
                  } else {
                    final notifService = ref.read(notificationServiceProvider);
                    await notifService.notifyAdminNewUser(
                      userId: id,
                      name: name,
                      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    );
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create User Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
