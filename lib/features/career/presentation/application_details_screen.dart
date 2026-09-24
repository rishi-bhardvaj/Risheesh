import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/resume_storage_helper.dart';
import '../../../core/utils/url_helper.dart';
import '../providers/career_providers.dart';
import 'add_edit_application_dialog.dart';

class ApplicationDetailsScreen extends ConsumerWidget {
  final JobApplication? application;
  final String? applicationId;

  const ApplicationDetailsScreen({
    super.key,
    this.application,
    this.applicationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (application != null) {
      return _buildContent(context, ref, application!);
    }

    if (applicationId != null) {
      final appAsync = ref.watch(applicationByIdProvider(applicationId!));
      return appAsync.when(
        data: (app) {
          if (app == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Application Details')),
              body: const Center(child: Text('Application not found')),
            );
          }
          return _buildContent(context, ref, app);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Application Details')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Application Details')),
          body: Center(child: Text('Error: $e')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: const Center(child: Text('No application specified')),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, JobApplication app) {
    final theme = Theme.of(context);
    final status = ApplicationStatus.fromString(app.status);
    final isFollowUpDue = app.followUpDate != null && DateFormatter.isOverdue(app.followUpDate);
    final resumeAsync = app.resumeId != null ? ref.watch(resumeByIdProvider(app.resumeId!)) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Application',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditApplicationDialog(applicationToEdit: app),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Application',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Application?'),
                  content: Text('Are you sure you want to delete your application for ${app.role} at ${app.company}?'),
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
                await ref.read(careerRepositoryProvider).deleteApplication(app.id);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.business_outlined, color: theme.colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.role,
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                app.company,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Status Dropdown & Timeline
                    Row(
                      children: [
                        Text('Current Stage:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        DropdownButton<ApplicationStatus>(
                          value: status,
                          underline: const SizedBox(),
                          items: ApplicationStatus.values.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s.label));
                          }).toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              await ref.read(careerRepositoryProvider).updateApplicationStatus(app.id, newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.calendar_today,
                    title: 'Applied Date',
                    value: DateFormatter.formatDate(app.appliedAt),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateInfo(
                    icon: Icons.alarm,
                    title: 'Follow-up',
                    value: app.followUpDate != null ? DateFormatter.formatDate(app.followUpDate) : 'Not set',
                    theme: theme,
                    isHighlighted: isFollowUpDue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Next Action Card
            if (app.nextAction != null && app.nextAction!.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.next_plan_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Next Action Item', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(app.nextAction!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Interview Details Card (if scheduled)
            if (app.interviewDate != null || app.interviewStage != null) ...[
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
                          Icon(Icons.event_note, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Interview Scheduled', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (app.interviewDate != null)
                        Text('Date: ${DateFormatter.formatDate(app.interviewDate)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (app.interviewStage != null)
                        Text('Stage: ${app.interviewStage!}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recruiter Info Card
            if (app.recruiterName != null || app.recruiterContact != null) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recruiter Info', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (app.recruiterName != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(app.recruiterName!),
                          subtitle: app.recruiterContact != null ? Text(app.recruiterContact!) : null,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Linked Resume Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resume Used', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (resumeAsync != null)
                      resumeAsync.when(
                        data: (res) {
                          if (res == null) return Text(app.resumeUsed ?? 'Resume version linked, but local file removed');
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                            title: Text('${res.name} (${res.version})'),
                            subtitle: Text(res.fileName),
                            trailing: FilledButton.tonalIcon(
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('Open'),
                              onPressed: () async {
                                final openResult = await ResumeStorageHelper.openResume(res.filePath);
                                if (openResult.type != ResultType.done && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(openResult.message)));
                                }
                              },
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => Text(app.resumeUsed ?? 'No resume attached'),
                      )
                    else
                      Text(
                        app.resumeUsed ?? 'No resume attached to this application',
                        style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Card
            if (app.notes != null && app.notes!.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notes & Observations', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(app.notes!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons (Job Link & URL)
            if (app.url != null && app.url!.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => UrlHelper.launchURL(context, app.url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open External Job Link'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isHighlighted ? const Color(0xFFEF4444) : theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? const Color(0xFFEF4444) : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? const Color(0xFFEF4444) : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
