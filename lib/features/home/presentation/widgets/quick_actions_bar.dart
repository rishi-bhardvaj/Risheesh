import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../career/presentation/add_edit_application_dialog.dart';
import '../../../career/presentation/add_edit_job_dialog.dart';
import '../../../career/presentation/add_edit_resume_dialog.dart';
import '../../../work/presentation/add_edit_eod_dialog.dart';
import '../../../work/presentation/add_edit_project_dialog.dart';
import '../../../work/presentation/add_edit_task_dialog.dart';

class QuickActionsBar extends ConsumerWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.add_task,
                label: '+ Task',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditTaskDialog(initialCategory: 'work'),
                ),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.work_outline,
                label: '+ Job',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditJobDialog(),
                ),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.assignment_turned_in_outlined,
                label: '+ Application',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditApplicationDialog(),
                ),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.picture_as_pdf_outlined,
                label: '+ Resume',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditResumeDialog(),
                ),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.folder_open,
                label: '+ Project',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditProjectDialog(),
                ),
                theme: theme,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.edit_calendar,
                label: '+ Log EOD',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const AddEditEODDialog(),
                ),
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
