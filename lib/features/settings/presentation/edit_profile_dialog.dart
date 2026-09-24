import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile? currentProfile;

  const EditProfileDialog({super.key, this.currentProfile});

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _expController;
  late final TextEditingController _noticeController;
  late final TextEditingController _educationController;
  late final TextEditingController _salaryController;
  late final TextEditingController _preferredEmploymentController;
  late final TextEditingController _rolesController;
  late final TextEditingController _locationsController;
  late final TextEditingController _skillsController;
  late final TextEditingController _languagesController;
  late final TextEditingController _frameworksController;
  late final TextEditingController _resumePrefController;

  String _remotePref = 'any';
  bool _isLoading = false;

  final _remoteOptions = [
    {'value': 'any', 'label': 'Any / Flexible'},
    {'value': 'remote', 'label': 'Remote Only'},
    {'value': 'hybrid', 'label': 'Hybrid'},
    {'value': 'on-site', 'label': 'On-site'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _roleController = TextEditingController(text: p?.currentRole ?? '');
    _expController = TextEditingController(text: p?.experienceYears != null ? p!.experienceYears.toString() : '0');
    _noticeController = TextEditingController(text: p?.noticePeriod ?? '');
    _educationController = TextEditingController(text: p?.education ?? '');
    _salaryController = TextEditingController(text: p?.expectedSalary ?? '');
    _preferredEmploymentController = TextEditingController(text: p?.preferredEmploymentType ?? '');
    _rolesController = TextEditingController(text: p?.preferredRoles ?? '');
    _locationsController = TextEditingController(text: p?.preferredLocations ?? '');
    _skillsController = TextEditingController(text: p?.skills ?? '');
    _languagesController = TextEditingController(text: p?.programmingLanguages ?? '');
    _frameworksController = TextEditingController(text: p?.frameworks ?? '');
    _resumePrefController = TextEditingController(text: p?.resumePreferences ?? '');

    if (p?.remotePreference != null && p!.remotePreference.isNotEmpty) {
      _remotePref = p.remotePreference;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _expController.dispose();
    _noticeController.dispose();
    _educationController.dispose();
    _salaryController.dispose();
    _preferredEmploymentController.dispose();
    _rolesController.dispose();
    _locationsController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
    _frameworksController.dispose();
    _resumePrefController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final isEditing = widget.currentProfile != null;
      final now = DateTime.now();

      final companion = UserProfilesCompanion(
        id: drift.Value(isEditing ? widget.currentProfile!.id : _uuid.v4()),
        name: drift.Value(_nameController.text.trim()),
        currentRole: drift.Value(_roleController.text.trim().isEmpty ? null : _roleController.text.trim()),
        experienceYears: drift.Value(double.tryParse(_expController.text.trim()) ?? 0.0),
        noticePeriod: drift.Value(_noticeController.text.trim().isEmpty ? null : _noticeController.text.trim()),
        education: drift.Value(_educationController.text.trim().isEmpty ? null : _educationController.text.trim()),
        expectedSalary: drift.Value(_salaryController.text.trim().isEmpty ? null : _salaryController.text.trim()),
        preferredEmploymentType: drift.Value(_preferredEmploymentController.text.trim().isEmpty ? null : _preferredEmploymentController.text.trim()),
        remotePreference: drift.Value(_remotePref),
        preferredRoles: drift.Value(_rolesController.text.trim().isEmpty ? null : _rolesController.text.trim()),
        preferredLocations: drift.Value(_locationsController.text.trim().isEmpty ? null : _locationsController.text.trim()),
        skills: drift.Value(_skillsController.text.trim().isEmpty ? null : _skillsController.text.trim()),
        programmingLanguages: drift.Value(_languagesController.text.trim().isEmpty ? null : _languagesController.text.trim()),
        frameworks: drift.Value(_frameworksController.text.trim().isEmpty ? null : _frameworksController.text.trim()),
        resumePreferences: drift.Value(_resumePrefController.text.trim().isEmpty ? null : _resumePrefController.text.trim()),
        createdAt: drift.Value(isEditing ? widget.currentProfile!.createdAt : now),
        updatedAt: drift.Value(now),
      );

      await db.upsertProfile(companion);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Career Profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Career Profile',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Text(
                        'Basic Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'Your name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _roleController,
                              decoration: const InputDecoration(labelText: 'Current Role', hintText: 'Backend Architect'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _expController,
                              decoration: const InputDecoration(labelText: 'Experience (Years)', hintText: '4.0'),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _noticeController,
                              decoration: const InputDecoration(labelText: 'Notice Period', hintText: '30 days'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _educationController,
                              decoration: const InputDecoration(labelText: 'Education', hintText: 'B.Tech in CS'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Skills & Technical Stack',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _languagesController,
                        decoration: const InputDecoration(labelText: 'Programming Languages', hintText: 'Java, Dart, TypeScript, SQL'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _frameworksController,
                        decoration: const InputDecoration(labelText: 'Frameworks & Tools', hintText: 'Spring Boot, Flutter, PostgreSQL, Docker'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _skillsController,
                        decoration: const InputDecoration(labelText: 'Primary Skills & Competencies', hintText: 'Distributed Systems, System Design, REST APIs'),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Career & Job Preferences',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rolesController,
                        decoration: const InputDecoration(labelText: 'Preferred / Target Roles', hintText: 'Staff Backend Engineer, Tech Lead'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _locationsController,
                              decoration: const InputDecoration(labelText: 'Preferred Locations', hintText: 'Bengaluru, Hyderabad'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _remotePref,
                              decoration: const InputDecoration(labelText: 'Work Mode'),
                              items: _remoteOptions.map((o) => DropdownMenuItem(value: o['value'], child: Text(o['label']!))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _remotePref = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController,
                              decoration: const InputDecoration(labelText: 'Expected Salary', hintText: '₹35-45 LPA'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _preferredEmploymentController,
                              decoration: const InputDecoration(labelText: 'Employment Type', hintText: 'Full-time'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _resumePrefController,
                        decoration: const InputDecoration(
                          labelText: 'Resume & Application Preferences',
                          hintText: 'Highlight distributed architectures and low-latency systems...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save Profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
