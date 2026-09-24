import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class AddEditSavedSearchDialog extends ConsumerStatefulWidget {
  final SavedSearch? searchToEdit;

  const AddEditSavedSearchDialog({super.key, this.searchToEdit});

  @override
  ConsumerState<AddEditSavedSearchDialog> createState() => _AddEditSavedSearchDialogState();
}

class _AddEditSavedSearchDialogState extends ConsumerState<AddEditSavedSearchDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _keywordsController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _locationController;
  late TextEditingController _employmentTypeController;
  late TextEditingController _experienceController;
  late TextEditingController _salaryController;

  String _remotePreference = 'any';

  final _remoteOptions = [
    {'value': 'any', 'label': 'Any Mode'},
    {'value': 'remote', 'label': 'Remote Only'},
    {'value': 'hybrid', 'label': 'Hybrid'},
    {'value': 'on-site', 'label': 'On-site'},
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.searchToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _keywordsController = TextEditingController(text: s?.keywords ?? '');
    _jobTitleController = TextEditingController(text: s?.jobTitle ?? '');
    _companyController = TextEditingController(text: s?.company ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _employmentTypeController = TextEditingController(text: s?.employmentType ?? '');
    _experienceController = TextEditingController(text: s?.experience ?? '');
    _salaryController = TextEditingController(text: s?.salary ?? '');

    if (s?.remotePreference != null) {
      _remotePreference = s!.remotePreference!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _employmentTypeController.dispose();
    _experienceController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final isEditing = widget.searchToEdit != null;
    final now = DateTime.now();

    final companion = SavedSearchesCompanion(
      id: drift.Value(isEditing ? widget.searchToEdit!.id : _uuid.v4()),
      name: drift.Value(_nameController.text.trim()),
      keywords: drift.Value(_keywordsController.text.trim().isEmpty ? null : _keywordsController.text.trim()),
      jobTitle: drift.Value(_jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim()),
      company: drift.Value(_companyController.text.trim().isEmpty ? null : _companyController.text.trim()),
      location: drift.Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
      remotePreference: drift.Value(_remotePreference == 'any' ? null : _remotePreference),
      employmentType: drift.Value(_employmentTypeController.text.trim().isEmpty ? null : _employmentTypeController.text.trim()),
      experience: drift.Value(_experienceController.text.trim().isEmpty ? null : _experienceController.text.trim()),
      salary: drift.Value(_salaryController.text.trim().isEmpty ? null : _salaryController.text.trim()),
      createdAt: drift.Value(isEditing ? widget.searchToEdit!.createdAt : now),
      updatedAt: drift.Value(now),
    );

    if (isEditing) {
      await db.updateSavedSearch(companion);
    } else {
      await db.insertSavedSearch(companion);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Saved search updated' : 'Saved search created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.searchToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.saved_search,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Saved Search' : 'Create Saved Search Preset',
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
                    // Search Preset Name (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Search Preset Name *',
                        hintText: 'e.g. Backend Dev Bangalore, Remote Flutter',
                        prefixIcon: Icon(Icons.label_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Search name is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Keywords & Job Title
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _jobTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Target Title',
                              hintText: 'e.g. Backend Engineer',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Target Company',
                              hintText: 'e.g. Google, Atlassian',
                              prefixIcon: Icon(Icons.business_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Keywords / Skills
                    TextFormField(
                      controller: _keywordsController,
                      decoration: const InputDecoration(
                        labelText: 'Keywords / Skills',
                        hintText: 'e.g. Java, Spring, Microservices, AWS',
                        prefixIcon: Icon(Icons.code_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Location & Remote Preference
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              hintText: 'e.g. Bengaluru, India',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _remotePreference,
                            decoration: const InputDecoration(
                              labelText: 'Work Mode',
                              prefixIcon: Icon(Icons.home_work_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _remoteOptions
                                .map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _remotePreference = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Employment Type, Experience & Salary
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _employmentTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Employment Type',
                              hintText: 'Full-time, Contract',
                              prefixIcon: Icon(Icons.work_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                              labelText: 'Min Experience',
                              hintText: 'e.g. 3+ years',
                              prefixIcon: Icon(Icons.timer_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Salary Expectation',
                        hintText: 'e.g. ₹25 LPA',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
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
                mainAxisAlignment: daylightPadding(),
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Save Changes' : 'Create Search Preset'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  MainAxisAlignment daylightPadding() => MainAxisAlignment.end;
}
