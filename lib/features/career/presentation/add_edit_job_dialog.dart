import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class AddEditJobDialog extends ConsumerStatefulWidget {
  final Job? jobToEdit;

  const AddEditJobDialog({super.key, Job? jobToEdit, Job? existingJob})
      : jobToEdit = jobToEdit ?? existingJob;

  @override
  ConsumerState<AddEditJobDialog> createState() => _AddEditJobDialogState();
}

class _AddEditJobDialogState extends ConsumerState<AddEditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  late TextEditingController _titleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _salaryController;
  late TextEditingController _experienceController;
  late TextEditingController _skillsController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String _employmentType = 'Full-time';
  String _source = 'Manual';
  bool _isSaved = false;
  DateTime? _postedDate;
  bool _isLoading = false;

  final _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Remote',
    'Hybrid',
    'On-site',
    'Internship',
  ];

  final _sources = [
    'Manual',
    'LinkedIn',
    'Indeed',
    'Wellfound',
    'Naukri',
    'Internshala',
    'Company Website',
    'Referral',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final j = widget.jobToEdit;
    _titleController = TextEditingController(text: j?.title ?? '');
    _companyController = TextEditingController(text: j?.company ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _salaryController = TextEditingController(text: j?.salary ?? '');
    _experienceController = TextEditingController(text: j?.experienceRequirement ?? '');
    _skillsController = TextEditingController(text: j?.skills ?? '');
    _urlController = TextEditingController(text: j?.url ?? '');
    _descriptionController = TextEditingController(text: j?.description ?? '');
    _notesController = TextEditingController(text: j?.notes ?? '');

    if (j != null) {
      if (j.employmentType != null && _employmentTypes.contains(j.employmentType)) {
        _employmentType = j.employmentType!;
      }
      if (j.source != null && _sources.contains(j.source)) {
        _source = j.source!;
      }
      _isSaved = j.isSaved;
      _postedDate = j.postedDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPostedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _postedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _postedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final isEditing = widget.jobToEdit != null;
      final now = DateTime.now();

      final companion = JobsCompanion(
        id: drift.Value(isEditing ? widget.jobToEdit!.id : _uuid.v4()),
        title: drift.Value(_titleController.text.trim()),
        company: drift.Value(_companyController.text.trim()),
        location: drift.Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
        salary: drift.Value(_salaryController.text.trim().isEmpty ? null : _salaryController.text.trim()),
        employmentType: drift.Value(_employmentType),
        experienceRequirement: drift.Value(_experienceController.text.trim().isEmpty ? null : _experienceController.text.trim()),
        url: drift.Value(_urlController.text.trim().isEmpty ? null : _urlController.text.trim()),
        source: drift.Value(_source),
        description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
        skills: drift.Value(_skillsController.text.trim().isEmpty ? null : _skillsController.text.trim()),
        postedDate: drift.Value(_postedDate),
        isSaved: drift.Value(_isSaved),
        notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
        updatedAt: drift.Value(now),
        createdAt: drift.Value(isEditing ? widget.jobToEdit!.createdAt : now),
        discoveredAt: drift.Value(isEditing ? widget.jobToEdit!.discoveredAt : now),
      );

      if (isEditing) {
        await db.updateJob(companion);
      } else {
        await db.insertJob(companion);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Job updated' : 'Job added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save job: $e')),
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
    final isEditing = widget.jobToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_business_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Job Opportunity' : 'Add Job Opportunity',
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

            // Dialog Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Job Title (Required)
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title *',
                        hintText: 'e.g. Senior Backend Engineer',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Job title is required' : null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Company Name (Required)
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company *',
                        hintText: 'e.g. Google, Stripe, Razorpay',
                        prefixIcon: Icon(Icons.business_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Company is required' : null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Location & Salary Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'e.g. Bengaluru, Remote',
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
                              labelText: 'Salary / Range',
                              hintText: 'e.g. ₹25-35 LPA, \$140k',
                              prefixIcon: Icon(Icons.payments_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Employment Type & Source Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _employmentType,
                            decoration: const InputDecoration(
                              labelText: 'Employment Type',
                              prefixIcon: Icon(Icons.work_outline),
                              border: OutlineInputBorder(),
                            ),
                            items: _employmentTypes
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _employmentType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _source,
                            decoration: const InputDecoration(
                              labelText: 'Source',
                              prefixIcon: Icon(Icons.link_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _sources
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _source = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Experience Requirement & Posted Date Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                              labelText: 'Experience Req.',
                              hintText: 'e.g. 3-5 years',
                              prefixIcon: Icon(Icons.timer_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickPostedDate,
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Posted Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _postedDate != null
                                    ? '${_postedDate!.day}/${_postedDate!.month}/${_postedDate!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  color: _postedDate != null ? theme.textTheme.bodyMedium?.color : theme.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skills Required
                    TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        labelText: 'Key Skills (comma-separated)',
                        hintText: 'e.g. Java, Spring Boot, PostgreSQL, Docker',
                        prefixIcon: Icon(Icons.code_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Job URL (Validated if provided)
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Job Posting URL',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.open_in_new_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final uri = Uri.tryParse(v.trim());
                          if (uri == null || !uri.hasScheme) {
                            return 'Please enter a valid URL (e.g. https://...)';
                          }
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Job Description / Highlights',
                        hintText: 'Key responsibilities, team details, tech stack...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.description_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Personal Notes',
                        hintText: 'Referral contact, application strategy, salary target...',
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
                    const SizedBox(height: 16),

                    // Save / Bookmark Switch
                    SwitchListTile(
                      title: const Text('Save to Bookmarks'),
                      subtitle: const Text('Mark this job in your saved opportunities tab'),
                      secondary: Icon(
                        _isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: _isSaved ? theme.colorScheme.primary : null,
                      ),
                      value: _isSaved,
                      onChanged: (val) => setState(() => _isSaved = val),
                    ),
                  ],
                ),
              ),
            ),

            // Dialog Footer Actions
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
                    label: Text(isEditing ? 'Save Changes' : 'Add Job'),
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
