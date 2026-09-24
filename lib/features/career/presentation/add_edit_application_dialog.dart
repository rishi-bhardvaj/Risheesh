import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/career_providers.dart';

class AddEditApplicationDialog extends ConsumerStatefulWidget {
  final JobApplication? applicationToEdit;
  final Job? initialJob;

  const AddEditApplicationDialog({
    super.key,
    this.applicationToEdit,
    this.initialJob,
  });

  @override
  ConsumerState<AddEditApplicationDialog> createState() => _AddEditApplicationDialogState();
}

class _AddEditApplicationDialogState extends ConsumerState<AddEditApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  late TextEditingController _companyController;
  late TextEditingController _roleController;
  late TextEditingController _salaryController;
  late TextEditingController _locationController;
  late TextEditingController _urlController;
  late TextEditingController _recruiterNameController;
  late TextEditingController _recruiterContactController;
  late TextEditingController _interviewStageController;
  late TextEditingController _coverLetterController;
  late TextEditingController _nextActionController;
  late TextEditingController _notesController;

  String? _selectedJobId;
  String _status = ApplicationStatus.applied.name;
  DateTime? _appliedAt;
  DateTime? _followUpDate;
  DateTime? _interviewDate;
  String? _selectedResumeId;
  String? _resumeUsedName;

  @override
  void initState() {
    super.initState();
    final a = widget.applicationToEdit;
    final j = widget.initialJob;

    _companyController = TextEditingController(text: a?.company ?? j?.company ?? '');
    _roleController = TextEditingController(text: a?.role ?? j?.title ?? '');
    _salaryController = TextEditingController(text: a?.salary ?? j?.salary ?? '');
    _locationController = TextEditingController(text: a?.location ?? j?.location ?? '');
    _urlController = TextEditingController(text: a?.url ?? j?.url ?? '');
    _recruiterNameController = TextEditingController(text: a?.recruiterName ?? '');
    _recruiterContactController = TextEditingController(text: a?.recruiterContact ?? '');
    _interviewStageController = TextEditingController(text: a?.interviewStage ?? '');
    _coverLetterController = TextEditingController(text: a?.coverLetterReference ?? '');
    _nextActionController = TextEditingController(text: a?.nextAction ?? '');
    _notesController = TextEditingController(text: a?.notes ?? j?.notes ?? '');

    _selectedJobId = a?.jobId ?? j?.id;
    _status = a?.status ?? ApplicationStatus.applied.name;
    _appliedAt = a?.appliedAt ?? DateTime.now();
    _followUpDate = a?.followUpDate;
    _interviewDate = a?.interviewDate;
    _selectedResumeId = a?.resumeId;
    _resumeUsedName = a?.resumeUsed;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    _recruiterNameController.dispose();
    _recruiterContactController.dispose();
    _interviewStageController.dispose();
    _coverLetterController.dispose();
    _nextActionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime? initial,
    required ValueChanged<DateTime?> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final isEditing = widget.applicationToEdit != null;
    final now = DateTime.now();

    // Prevent duplicate applications for the same Job when creating new
    if (!isEditing && _selectedJobId != null) {
      final existing = await db.getApplicationByJobId(_selectedJobId!);
      if (existing != null) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Duplicate Application Warning'),
            content: Text(
              'An application already exists for "${existing.role} at ${existing.company}" (Status: ${existing.status.toUpperCase()}).\n\nDo you want to create another application for this same job?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Create Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
    }

    // Resolve resume name if id is selected
    if (_selectedResumeId != null) {
      final resume = await db.getResumeById(_selectedResumeId!);
      if (resume != null) {
        _resumeUsedName = '${resume.name} (${resume.version})';
      }
    }

    final companion = JobApplicationsCompanion(
      id: drift.Value(isEditing ? widget.applicationToEdit!.id : _uuid.v4()),
      jobId: drift.Value(_selectedJobId),
      company: drift.Value(_companyController.text.trim()),
      role: drift.Value(_roleController.text.trim()),
      salary: drift.Value(_salaryController.text.trim().isEmpty ? null : _salaryController.text.trim()),
      location: drift.Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
      url: drift.Value(_urlController.text.trim().isEmpty ? null : _urlController.text.trim()),
      status: drift.Value(_status),
      appliedAt: drift.Value(_appliedAt),
      followUpDate: drift.Value(_followUpDate),
      interviewDate: drift.Value(_interviewDate),
      interviewStage: drift.Value(_interviewStageController.text.trim().isEmpty ? null : _interviewStageController.text.trim()),
      recruiterName: drift.Value(_recruiterNameController.text.trim().isEmpty ? null : _recruiterNameController.text.trim()),
      recruiterContact: drift.Value(_recruiterContactController.text.trim().isEmpty ? null : _recruiterContactController.text.trim()),
      resumeId: drift.Value(_selectedResumeId),
      resumeUsed: drift.Value(_resumeUsedName),
      coverLetterReference: drift.Value(_coverLetterController.text.trim().isEmpty ? null : _coverLetterController.text.trim()),
      notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
      nextAction: drift.Value(_nextActionController.text.trim().isEmpty ? null : _nextActionController.text.trim()),
      createdAt: drift.Value(isEditing ? widget.applicationToEdit!.createdAt : now),
      updatedAt: drift.Value(now),
    );

    if (isEditing) {
      await db.updateApplication(companion);
    } else {
      await db.insertApplication(companion);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Application updated' : 'Application logged successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.applicationToEdit != null;
    final allJobs = ref.watch(allJobsProvider).valueOrNull ?? [];
    final allResumes = ref.watch(allResumesProvider).valueOrNull ?? [];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_document : Icons.assignment_turned_in_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Application' : 'Log Job Application',
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

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Linked Job Selector (Optional if creating new)
                    if (!isEditing && allJobs.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        value: _selectedJobId,
                        decoration: const InputDecoration(
                          labelText: 'Link Existing Job Opportunity (Optional)',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('-- None (Standalone Entry) --')),
                          ...allJobs.map((j) => DropdownMenuItem(
                                value: j.id,
                                child: Text('${j.title} @ ${j.company}', overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedJobId = val;
                            if (val != null) {
                              final matched = allJobs.firstWhere((j) => j.id == val);
                              _companyController.text = matched.company;
                              _roleController.text = matched.title;
                              if (matched.location != null) _locationController.text = matched.location!;
                              if (matched.salary != null) _salaryController.text = matched.salary!;
                              if (matched.url != null) _urlController.text = matched.url!;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Role Title & Company (Required)
                    TextFormField(
                      controller: _roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role / Job Title *',
                        hintText: 'e.g. Full Stack Engineer',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Role title is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company *',
                        hintText: 'e.g. Microsoft, Uber',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Company is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Application Stage / Status *',
                        prefixIcon: Icon(Icons.timeline),
                        border: OutlineInputBorder(),
                      ),
                      items: ApplicationStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s.name,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Applied Date & Follow-up Date Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(
                              context: context,
                              initial: _appliedAt,
                              onSelected: (d) => setState(() => _appliedAt = d),
                            ),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Applied Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _appliedAt != null
                                    ? '${_appliedAt!.day}/${_appliedAt!.month}/${_appliedAt!.year}'
                                    : 'Select date',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(
                              context: context,
                              initial: _followUpDate,
                              onSelected: (d) => setState(() => _followUpDate = d),
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Follow-up Date',
                                prefixIcon: const Icon(Icons.alarm_on_outlined),
                                suffixIcon: _followUpDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _followUpDate = null),
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _followUpDate != null
                                    ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                                    : 'Set date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _followUpDate != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Interview Schedule & Stage Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(
                              context: context,
                              initial: _interviewDate,
                              onSelected: (d) => setState(() => _interviewDate = d),
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Interview Date',
                                prefixIcon: const Icon(Icons.event_available_outlined),
                                suffixIcon: _interviewDate != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () => setState(() => _interviewDate = null),
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              child: Text(
                                _interviewDate != null
                                    ? '${_interviewDate!.day}/${_interviewDate!.month}/${_interviewDate!.year}'
                                    : 'Schedule date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _interviewDate != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _interviewStageController,
                            decoration: const InputDecoration(
                              labelText: 'Interview Stage',
                              hintText: 'e.g. System Design',
                              prefixIcon: Icon(Icons.psychology_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recruiter Name & Contact
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _recruiterNameController,
                            decoration: const InputDecoration(
                              labelText: 'Recruiter Name',
                              hintText: 'e.g. Sarah Jenkins',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _recruiterContactController,
                            decoration: const InputDecoration(
                              labelText: 'Recruiter Email / Tel',
                              hintText: 'sarah@uber.com',
                              prefixIcon: Icon(Icons.contact_mail_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Linked Resume Vault Version
                    DropdownButtonFormField<String?>(
                      value: _selectedResumeId,
                      decoration: const InputDecoration(
                        labelText: 'Linked Resume Version',
                        prefixIcon: Icon(Icons.picture_as_pdf_outlined),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('-- No Resume Attached --')),
                        ...allResumes.map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${r.name} (${r.version})${r.isPrimary ? ' ⭐ Primary' : ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedResumeId = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location & Salary
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'e.g. Remote, Mumbai',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _salaryController,
                            decoration: const InputDecoration(
                              labelText: 'Offered / Target Salary',
                              hintText: 'e.g. ₹30 LPA',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Next Action
                    TextFormField(
                      controller: _nextActionController,
                      decoration: const InputDecoration(
                        labelText: 'Next Action',
                        hintText: 'e.g. Prepare LeetCode graph problems, send thank-you note',
                        prefixIcon: Icon(Icons.next_plan_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Cover Letter Reference
                    TextFormField(
                      controller: _coverLetterController,
                      decoration: const InputDecoration(
                        labelText: 'Cover Letter Reference / Note',
                        hintText: 'e.g. Tailored backend infra experience highlighted',
                        prefixIcon: Icon(Icons.article_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes & Observations',
                        hintText: 'Interview feedback, round details, hiring team info...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.note_alt_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
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
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Save Changes' : 'Log Application'),
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

