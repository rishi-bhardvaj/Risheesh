import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/presentation/edit_profile_dialog.dart';
import '../providers/career_providers.dart';

class CareerProfileView extends ConsumerWidget {
  const CareerProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(careerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Profile'),
        actions: [
          profileAsync.when(
            data: (profile) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => EditProfileDialog(currentProfile: profile),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No career profile found'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const EditProfileDialog(),
                      );
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile Header Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.currentRole ?? 'Software Engineer',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                Text(
                                  '${profile.experienceYears} Years Exp',
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (profile.noticePeriod != null)
                                  Text(
                                    '• Notice: ${profile.noticePeriod!}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (profile.education != null)
                                  Text(
                                    '• ${profile.education!}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Technical Stack & Skills Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.terminal, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Technical Stack & Skills',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (profile.programmingLanguages != null && profile.programmingLanguages!.isNotEmpty) ...[
                        Text('Programming Languages', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 6),
                        _buildTagWrap(profile.programmingLanguages!, theme, Colors.blue),
                        const SizedBox(height: 12),
                      ],

                      if (profile.frameworks != null && profile.frameworks!.isNotEmpty) ...[
                        Text('Frameworks & Tools', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 6),
                        _buildTagWrap(profile.frameworks!, theme, Colors.teal),
                        const SizedBox(height: 12),
                      ],

                      if (profile.skills != null && profile.skills!.isNotEmpty) ...[
                        Text('Primary Skills & Competencies', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 6),
                        _buildTagWrap(profile.skills!, theme, Colors.deepPurple),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preferences Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Preferences & Target Criteria',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildInfoTile('Target Roles', profile.preferredRoles ?? 'Not specified', Icons.badge_outlined),
                      _buildInfoTile('Preferred Locations', profile.preferredLocations ?? 'Any location', Icons.location_on_outlined),
                      _buildInfoTile('Work Mode', profile.remotePreference.toUpperCase(), Icons.home_work_outlined),
                      _buildInfoTile('Expected Salary', profile.expectedSalary ?? 'Not specified', Icons.payments_outlined),
                      if (profile.preferredEmploymentType != null)
                        _buildInfoTile('Employment Type', profile.preferredEmploymentType!, Icons.work_outline),
                      if (profile.noticePeriod != null)
                        _buildInfoTile('Notice Period', profile.noticePeriod!, Icons.access_time),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Resume & Cover Letter Preferences
              if (profile.resumePreferences != null && profile.resumePreferences!.isNotEmpty) ...[
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description_outlined, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Resume & Application Notes',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.resumePreferences!,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => EditProfileDialog(currentProfile: profile),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Career Profile'),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildTagWrap(String text, ThemeData theme, MaterialColor color) {
    final tags = text.split(RegExp(r'[,/|]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map((t) => Chip(
                label: Text(t, style: TextStyle(fontSize: 12, color: color[700])),
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ))
          .toList(),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
