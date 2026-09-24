import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/work_providers.dart';
import 'add_edit_eod_dialog.dart';

class EODHistoryScreen extends ConsumerStatefulWidget {
  const EODHistoryScreen({super.key});

  @override
  ConsumerState<EODHistoryScreen> createState() => _EODHistoryScreenState();
}

class _EODHistoryScreenState extends ConsumerState<EODHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eodListAsync = ref.watch(eodNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EOD Log History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search EOD logs by keyword...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: eodListAsync.when(
              data: (logs) {
                var filtered = List<EODNote>.from(logs);

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((n) {
                    final c = n.completedWork.toLowerCase();
                    final p = n.inProgressWork.toLowerCase();
                    final b = (n.blockers ?? '').toLowerCase();
                    final t = (n.tomorrowPlan ?? '').toLowerCase();
                    final note = (n.notes ?? '').toLowerCase();
                    return c.contains(_searchQuery) ||
                        p.contains(_searchQuery) ||
                        b.contains(_searchQuery) ||
                        t.contains(_searchQuery) ||
                        note.contains(_searchQuery);
                  }).toList();
                }

                // Newest first
                filtered.sort((a, b) => b.date.compareTo(a.date));

                if (filtered.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.history_edu,
                    title: _searchQuery.isNotEmpty ? 'No Matching EOD Logs' : 'No EOD Logs Recorded',
                    message: _searchQuery.isNotEmpty
                        ? 'Try modifying your search keywords.'
                        : 'Keep a disciplined daily record of your accomplishments, work in progress, and blockers.',
                    actionLabel: _searchQuery.isEmpty ? '+ Log Today’s EOD' : null,
                    onAction: _searchQuery.isEmpty
                        ? () => showDialog(
                              context: context,
                              builder: (_) => const AddEditEODDialog(),
                            )
                        : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    return _buildEODCard(context, ref, note, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading EOD history: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddEditEODDialog(),
        ),
        icon: const Icon(Icons.edit_calendar),
        label: const Text('Log EOD'),
      ),
    );
  }

  Widget _buildEODCard(BuildContext context, WidgetRef ref, EODNote note, ThemeData theme) {
    final hasBlockers = note.blockers != null && note.blockers!.trim().isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEODDetailsDialog(context, ref, note, theme),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event_note, size: 18, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormatter.formatDate(note.date),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (hasBlockers)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(
                            'Has Blockers',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Completed Preview
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.completedWork,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // In Progress Preview
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.timelapse, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.inProgressWork,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEODDetailsDialog(BuildContext context, WidgetRef ref, EODNote note, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EOD Standup Note',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormatter.formatDate(note.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit EOD',
                            onPressed: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (_) => AddEditEODDialog(existingNote: note),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                            tooltip: 'Delete EOD',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete EOD Log?'),
                                  content: Text('Delete EOD log for ${DateFormatter.formatDate(note.date)}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(workRepositoryProvider).deleteEODNote(note.id);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('EOD Log deleted')),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildSectionHeader(theme, 'Completed Today', Icons.check_circle_outline, const Color(0xFF10B981)),
                        const SizedBox(height: 6),
                        _buildContentBox(theme, note.completedWork),
                        const SizedBox(height: 14),

                        _buildSectionHeader(theme, 'In Progress / Worked On', Icons.timelapse, const Color(0xFF38BDF8)),
                        const SizedBox(height: 6),
                        _buildContentBox(theme, note.inProgressWork),
                        const SizedBox(height: 14),

                        if (note.blockers != null && note.blockers!.trim().isNotEmpty) ...[
                          _buildSectionHeader(theme, 'Blockers / Need Help', Icons.warning_amber_rounded, Colors.redAccent),
                          const SizedBox(height: 6),
                          _buildContentBox(theme, note.blockers!),
                          const SizedBox(height: 14),
                        ],

                        if (note.tomorrowPlan != null && note.tomorrowPlan!.trim().isNotEmpty) ...[
                          _buildSectionHeader(theme, 'Plan for Tomorrow', Icons.next_plan_outlined, const Color(0xFFF59E0B)),
                          const SizedBox(height: 6),
                          _buildContentBox(theme, note.tomorrowPlan!),
                          const SizedBox(height: 14),
                        ],

                        if (note.notes != null && note.notes!.trim().isNotEmpty) ...[
                          _buildSectionHeader(theme, 'Additional Notes', Icons.notes, theme.colorScheme.primary),
                          const SizedBox(height: 6),
                          _buildContentBox(theme, note.notes!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildContentBox(ThemeData theme, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
    );
  }
}

