import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/url_helper.dart';
import '../../work/presentation/add_edit_task_dialog.dart';
import '../providers/freelance_providers.dart';
import 'add_edit_lead_dialog.dart';
import 'convert_lead_dialog.dart';

class LeadDetailsScreen extends ConsumerWidget {
  final FreelanceLead? lead;
  final String? leadId;

  const LeadDetailsScreen({
    super.key,
    this.lead,
    this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = lead?.id ?? leadId;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid lead identifier.')));
    }

    final leadAsync = ref.watch(leadByIdProvider(id));
    final currentLead = leadAsync.valueOrNull ?? lead;

    if (currentLead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = LeadStatus.fromString(currentLead.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Opportunity',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditLeadDialog(leadToEdit: currentLead),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Opportunity?'),
                    content: Text('Are you sure you want to delete "${currentLead.title}"?'),
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
                  await ref.read(freelanceRepositoryProvider).deleteLead(currentLead.id);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (val == 'convert') {
                showDialog(
                  context: context,
                  builder: (_) => ConvertLeadDialog(lead: currentLead),
                );
              } else if (val == 'add_task') {
                showDialog(
                  context: context,
                  builder: (_) => AddEditTaskDialog(
                    initialTitle: 'Follow up: ${currentLead.title}',
                    initialCategory: 'work',
                    initialNotes: 'Platform: ${currentLead.platform ?? "Direct"}\nClient: ${currentLead.clientName ?? ""}',
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'convert',
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Convert to Client'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_task',
                child: Row(
                  children: [
                    Icon(Icons.add_task, size: 18),
                    SizedBox(width: 8),
                    Text('Create Task for Lead'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Opportunity', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          currentLead.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (currentLead.clientName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          currentLead.clientName!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontSize: 15,
                          ),
                        ),
                        if (currentLead.contactName != null) ...[
                          const SizedBox(width: 6),
                          Text('• ${currentLead.contactName!}', style: TextStyle(color: theme.hintColor)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Meta Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (currentLead.platform != null)
                        _buildInfoChip(currentLead.platform!, Icons.public, theme),
                      if (currentLead.budget != null)
                        _buildInfoChip(
                          '${currentLead.currency} ${currentLead.budget!.toStringAsFixed(0)}',
                          Icons.payments_outlined,
                          theme,
                          isHighlight: true,
                        ),
                      if (currentLead.deadline != null)
                        _buildInfoChip(
                          'Deadline: ${DateFormatter.formatDate(currentLead.deadline!)}',
                          Icons.event_available,
                          theme,
                        ),
                      _buildInfoChip(
                        'Logged ${DateFormatter.formatRelative(currentLead.createdAt)}',
                        Icons.calendar_today_outlined,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Pipeline Status Changer Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pipeline Stage', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: LeadStatus.values.map((s) {
                      final isSelected = s == status;
                      return ChoiceChip(
                        label: Text(s.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(freelanceRepositoryProvider).updateLeadStatus(currentLead.id, s.value);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Follow-up Section
          if (currentLead.followUpDate != null || currentLead.followUpNote != null || currentLead.nextAction != null) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isOverdue(currentLead.followUpDate) ? Colors.red.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.alarm,
                          color: _isOverdue(currentLead.followUpDate) ? Colors.red : Colors.orange.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isOverdue(currentLead.followUpDate) ? 'Overdue Follow-up' : 'Scheduled Follow-up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isOverdue(currentLead.followUpDate) ? Colors.red : Colors.orange.shade900,
                          ),
                        ),
                        const Spacer(),
                        if (currentLead.followUpDate != null)
                          Text(
                            DateFormatter.formatDate(currentLead.followUpDate!),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    if (currentLead.followUpNote != null && currentLead.followUpNote!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(currentLead.followUpNote!, style: theme.textTheme.bodyMedium),
                    ],
                    if (currentLead.nextAction != null && currentLead.nextAction!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.arrow_right_alt, size: 16, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Next: ${currentLead.nextAction!}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Skills Section
          if (currentLead.skills != null && currentLead.skills!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skills & Stack', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: currentLead.skills!
                          .split(RegExp(r'[,|]'))
                          .map((s) => s.trim())
                          .where((s) => s.isNotEmpty)
                          .map((skill) => Chip(
                                label: Text(skill, style: const TextStyle(fontSize: 12)),
                                backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Description Section
          if (currentLead.description != null && currentLead.description!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Opportunity Description', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 8),
                    Text(
                      currentLead.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Proposal / Pitch Section
          if (currentLead.proposal != null && currentLead.proposal!.isNotEmpty) ...[
            Card(
              elevation: 0,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Proposal / Submitted Pitch', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Copy Proposal',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentLead.proposal!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Proposal copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentLead.proposal!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Project URL Link
          if (currentLead.url != null && currentLead.url!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open Project URL'),
                subtitle: Text(currentLead.url!, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => UrlHelper.launchURL(currentLead.url!, context),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Private Notes
          if (currentLead.notes != null && currentLead.notes!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Private Notes', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 6),
                    Text(currentLead.notes!, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 16),

          // Big Conversion Call to Action
          if (status == LeadStatus.won || currentLead.clientId == null)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ConvertLeadDialog(lead: currentLead),
                );
              },
              icon: const Icon(Icons.verified),
              label: Text(currentLead.clientId != null ? 'Convert / Update Client Info' : 'Convert Lead to Client'),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LeadStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case LeadStatus.newLead:
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue.shade800;
        break;
      case LeadStatus.researching:
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple.shade800;
        break;
      case LeadStatus.contacted:
      case LeadStatus.replied:
        bg = Colors.teal.withOpacity(0.15);
        fg = Colors.teal.shade800;
        break;
      case LeadStatus.discussion:
        bg = Colors.indigo.withOpacity(0.15);
        fg = Colors.indigo.shade800;
        break;
      case LeadStatus.proposalSent:
      case LeadStatus.negotiation:
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange.shade900;
        break;
      case LeadStatus.won:
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        break;
      case LeadStatus.lost:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, ThemeData theme, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? theme.colorScheme.primaryContainer.withOpacity(0.6) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}

