import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/freelance_providers.dart';

class AddEditLeadDialog extends ConsumerStatefulWidget {
  final FreelanceLead? leadToEdit;

  const AddEditLeadDialog({super.key, this.leadToEdit});

  @override
  ConsumerState<AddEditLeadDialog> createState() => _AddEditLeadDialogState();
}

class _AddEditLeadDialogState extends ConsumerState<AddEditLeadDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _clientNameController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactInfoController;
  late TextEditingController _descriptionController;
  late TextEditingController _skillsController;
  late TextEditingController _budgetController;
  late TextEditingController _urlController;
  late TextEditingController _followUpNoteController;
  late TextEditingController _nextActionController;
  late TextEditingController _proposalController;
  late TextEditingController _notesController;

  String _platform = 'Upwork';
  String _currency = 'USD';
  String _status = 'NEW_LEAD';
  DateTime? _deadline;
  DateTime? _followUpDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.leadToEdit;
    _titleController = TextEditingController(text: l?.title ?? '');
    _clientNameController = TextEditingController(text: l?.clientName ?? '');
    _contactNameController = TextEditingController(text: l?.contactName ?? '');
    _contactInfoController = TextEditingController(text: l?.contactInfo ?? '');
    _descriptionController = TextEditingController(text: l?.description ?? '');
    _skillsController = TextEditingController(text: l?.skills ?? '');
    _budgetController = TextEditingController(text: l?.budget != null ? '${l!.budget}' : '');
    _urlController = TextEditingController(text: l?.url ?? '');
    _followUpNoteController = TextEditingController(text: l?.followUpNote ?? '');
    _nextActionController = TextEditingController(text: l?.nextAction ?? '');
    _proposalController = TextEditingController(text: l?.proposal ?? '');
    _notesController = TextEditingController(text: l?.notes ?? '');

    if (l != null) {
      if (l.platform != null && AppConstants.freelancePlatforms.contains(l.platform)) {
        _platform = l.platform!;
      }
      if (AppConstants.currencies.contains(l.currency)) {
        _currency = l.currency;
      }
      _status = l.status;
      _deadline = l.deadline;
      _followUpDate = l.followUpDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientNameController.dispose();
    _contactNameController.dispose();
    _contactInfoController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _budgetController.dispose();
    _urlController.dispose();
    _followUpNoteController.dispose();
    _nextActionController.dispose();
    _proposalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(freelanceRepositoryProvider);
      final budgetVal = double.tryParse(_budgetController.text.trim());
      final isEditing = widget.leadToEdit != null;

      if (isEditing) {
        await repo.updateLead(
          id: widget.leadToEdit!.id,
          title: _titleController.text.trim(),
          clientName: _clientNameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          contactInfo: _contactInfoController.text.trim(),
          platform: _platform,
          description: _descriptionController.text.trim(),
          skills: _skillsController.text.trim(),
          budget: budgetVal,
          currency: _currency,
          url: _urlController.text.trim(),
          status: _status,
          proposal: _proposalController.text.trim(),
          deadline: _deadline,
          followUpDate: _followUpDate,
          followUpNote: _followUpNoteController.text.trim(),
          nextAction: _nextActionController.text.trim(),
          notes: _notesController.text.trim(),
          leadDate: widget.leadToEdit!.leadDate,
          clientId: widget.leadToEdit!.clientId,
          projectId: widget.leadToEdit!.projectId,
          createdAt: widget.leadToEdit!.createdAt,
        );
      } else {
        await repo.addLead(
          title: _titleController.text.trim(),
          clientName: _clientNameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          contactInfo: _contactInfoController.text.trim(),
          platform: _platform,
          description: _descriptionController.text.trim(),
          skills: _skillsController.text.trim(),
          budget: budgetVal,
          currency: _currency,
          url: _urlController.text.trim(),
          status: _status,
          proposal: _proposalController.text.trim(),
          deadline: _deadline,
          followUpDate: _followUpDate,
          followUpNote: _followUpNoteController.text.trim(),
          nextAction: _nextActionController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Lead updated' : 'Freelance lead added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.leadToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 760),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Freelance Opportunity' : 'Add Freelance Lead',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Project / Lead Title (Required)
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Project / Opportunity Title *',
                        hintText: 'e.g. Build Mobile App MVP in Flutter',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Project title is required' : null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Client & Contact Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _clientNameController,
                            decoration: const InputDecoration(
                              labelText: 'Client / Company Name',
                              hintText: 'e.g. Apex Studio, John',
                              prefixIcon: Icon(Icons.business_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _contactNameController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person',
                              hintText: 'e.g. Sarah Connor',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Platform & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _platform,
                            decoration: const InputDecoration(
                              labelText: 'Platform / Source',
                              prefixIcon: Icon(Icons.public),
                              border: OutlineInputBorder(),
                            ),
                            items: AppConstants.freelancePlatforms
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _platform = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Pipeline Status',
                              prefixIcon: Icon(Icons.stacked_bar_chart),
                              border: OutlineInputBorder(),
                            ),
                            items: LeadStatus.values
                                .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Budget & Currency Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _budgetController,
                            decoration: const InputDecoration(
                              labelText: 'Budget (Optional)',
                              hintText: 'e.g. 1500, 50000',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final val = double.tryParse(v.trim());
                                if (val == null || val < 0) {
                                  return 'Enter a valid amount >= 0';
                                }
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            items: AppConstants.currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact Info & Project URL Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactInfoController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Email / Handle',
                              hintText: 'e.g. client@email.com, @handle',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Project Posting URL',
                              hintText: 'https://...',
                              prefixIcon: Icon(Icons.link),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.url,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                final uri = Uri.tryParse(v.trim());
                                if (uri == null || !uri.hasScheme) {
                                  return 'Please enter a valid URL';
                                }
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dates Row (Follow-up & Deadline)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickFollowUpDate,
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Follow-up Date',
                                prefixIcon: const Icon(Icons.alarm),
                                border: const OutlineInputBorder(),
                                suffixIcon: _followUpDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _followUpDate = null),
                                      )
                                    : null,
                              ),
                              child: Text(
                                _followUpDate != null
                                    ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                                    : 'Select follow-up',
                                style: TextStyle(
                                  color: _followUpDate != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDeadline,
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Project Deadline',
                                prefixIcon: const Icon(Icons.event_available),
                                border: const OutlineInputBorder(),
                                suffixIcon: _deadline != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _deadline = null),
                                      )
                                    : null,
                              ),
                              child: Text(
                                _deadline != null
                                    ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                    : 'Select deadline',
                                style: TextStyle(
                                  color: _deadline != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Required Skills
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Required Skills (comma-separated)',
                        hintText: 'e.g. Flutter, Firebase, REST API, Stripe',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Project Description / Requirements',
                        hintText: 'Detailed requirements, deliverables, scope...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 45),
                          child: Icon(Icons.description_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 16),

                    // Follow-up Note / Next Action
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _followUpNoteController,
                            decoration: const InputDecoration(
                              labelText: 'Follow-up Note',
                              hintText: 'e.g. Check if client replied on Upwork',
                              prefixIcon: Icon(Icons.note_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nextActionController,
                            decoration: const InputDecoration(
                              labelText: 'Next Action',
                              hintText: 'e.g. Send demo video',
                              prefixIcon: Icon(Icons.arrow_forward),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Proposal Text / Pitch
                    TextFormField(
                      controller: _proposalController,
                      decoration: const InputDecoration(
                        labelText: 'Draft Proposal / Submitted Pitch',
                        hintText: 'Paste or draft your cover letter/proposal text here...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.draw_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 16),

                    // Internal Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Private Notes',
                        hintText: 'Strategy, pricing flexibility, communication thoughts...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.lock_outline),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Opportunity' : 'Save Opportunity'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

