import 'package:flutter/material.dart';
import '../../features/career/presentation/add_edit_application_dialog.dart';
import '../../features/career/presentation/add_edit_job_dialog.dart';
import '../../features/career/presentation/add_edit_resume_dialog.dart';
import '../../features/freelance/presentation/add_edit_client_dialog.dart';
import '../../features/freelance/presentation/add_edit_lead_dialog.dart';
import '../../features/freelance/presentation/add_edit_payment_dialog.dart';
import '../../features/work/presentation/add_edit_eod_dialog.dart';
import '../../features/work/presentation/add_edit_project_dialog.dart';
import '../../features/work/presentation/add_edit_task_dialog.dart';
import '../../features/work/presentation/add_edit_thing_to_ask_dialog.dart';
import '../../features/work/presentation/add_edit_work_note_dialog.dart';

void showQuickAddModal(BuildContext context) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionItem(
                icon: Icons.add_task,
                title: 'Create Task',
                subtitle: 'Add work item, technical goal, or reminder',
                color: theme.colorScheme.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditTaskDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.tune,
                title: 'Add Freelance Lead',
                subtitle: 'Track incoming client opportunity, budget, and pitch',
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditLeadDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add Freelance Client',
                subtitle: 'Store client profile, contacts, and contract terms',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditClientDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.add_card,
                title: 'Record Freelance Payment',
                subtitle: 'Log milestone payment, invoice, or received amount',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditPaymentDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.work_outline,
                title: 'Add Job Opportunity',
                subtitle: 'Save a target role with company, salary, and link',
                color: const Color(0xFF38BDF8),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditJobDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Log Job Application',
                subtitle: 'Track status, follow-up date, and resume used',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditApplicationDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Add Resume to Vault',
                subtitle: 'Store a tailored resume version locally',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditResumeDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.folder_open,
                title: 'Create Project',
                subtitle: 'Track work/side project, tech stack, and progress',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditProjectDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.edit_calendar,
                title: 'Log EOD Standup Note',
                subtitle: 'Record completed items and blockers for today',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditEODDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.question_answer_outlined,
                title: 'Add Thing to Ask',
                subtitle: 'Questions or blockers for standup and 1:1s',
                color: Colors.pinkAccent,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditThingToAskDialog());
                },
              ),
              const SizedBox(height: 10),
              _buildQuickActionItem(
                icon: Icons.note_add_outlined,
                title: 'New Meeting / Work Note',
                subtitle: 'Meeting notes, decisions, and action items',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(context: context, builder: (_) => const AddEditWorkNoteDialog());
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildQuickActionItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    ),
  );
}
