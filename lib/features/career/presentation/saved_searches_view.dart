import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/career_providers.dart';
import 'add_edit_saved_search_dialog.dart';

class SavedSearchesView extends ConsumerWidget {
  final VoidCallback onRunSearch;

  const SavedSearchesView({super.key, required this.onRunSearch});

  Future<void> _deleteSearch(BuildContext context, WidgetRef ref, SavedSearch s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Saved Search?'),
        content: Text('Are you sure you want to delete preset "${s.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(databaseProvider).deleteSavedSearch(s.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved search removed')),
        );
      }
    }
  }

  void _applyAndRun(WidgetRef ref, SavedSearch s) {
    // 1. Set query
    final queryParts = <String>[];
    if (s.keywords != null) queryParts.add(s.keywords!);
    if (s.jobTitle != null) queryParts.add(s.jobTitle!);
    if (s.company != null) queryParts.add(s.company!);
    ref.read(jobSearchQueryProvider.notifier).state = queryParts.join(' ');

    // 2. Set filter
    ref.read(jobFilterProvider.notifier).state = JobFilterState(
      employmentType: s.employmentType,
      remotePreference: s.remotePreference,
      location: s.location,
    );

    // 3. Switch to Jobs tab
    onRunSearch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchesAsync = ref.watch(allSavedSearchesProvider);

    return searchesAsync.when(
      data: (searches) {
        if (searches.isEmpty) {
          return EmptyStateView(
            icon: Icons.saved_search,
            title: 'No Saved Searches',
            message: 'Save search criteria presets to quickly filter local opportunities and prepare for future providers.',
            actionLabel: 'Create Search Preset',
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditSavedSearchDialog(),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: searches.length,
          itemBuilder: (context, index) {
            final s = searches[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.saved_search, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditSavedSearchDialog(searchToEdit: s),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _deleteSearch(context, ref, s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Criteria chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (s.jobTitle != null)
                          Chip(
                            avatar: const Icon(Icons.badge_outlined, size: 14),
                            label: Text(s.jobTitle!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.company != null)
                          Chip(
                            avatar: const Icon(Icons.business_outlined, size: 14),
                            label: Text(s.company!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.keywords != null)
                          Chip(
                            avatar: const Icon(Icons.tag, size: 14),
                            label: Text(s.keywords!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.location != null)
                          Chip(
                            avatar: const Icon(Icons.location_on_outlined, size: 14),
                            label: Text(s.location!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.remotePreference != null)
                          Chip(
                            avatar: const Icon(Icons.home_work_outlined, size: 14),
                            label: Text(s.remotePreference!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.employmentType != null)
                          Chip(
                            avatar: const Icon(Icons.work_outline, size: 14),
                            label: Text(s.employmentType!),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (s.salary != null)
                          Chip(
                            avatar: const Icon(Icons.payments_outlined, size: 14),
                            label: Text('Min: ${s.salary!}'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ℹ️ Applies filter to local jobs database',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color?.withOpacity(0.5),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _applyAndRun(ref, s),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Run Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading saved searches: $e')),
    );
  }
}
