import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/work_providers.dart';

class AddEditProjectDialog extends ConsumerStatefulWidget {
  final Project? existingProject;
  final String? initialClientId;
  final String? initialNotes;
  final bool isFreelance;

  const AddEditProjectDialog({
    super.key,
    this.existingProject,
    this.initialClientId,
    this.initialNotes,
    this.isFreelance = false,
  });

  @override
  ConsumerState<AddEditProjectDialog> createState() => _AddEditProjectDialogState();
}

class _AddEditProjectDialogState extends ConsumerState<AddEditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _techStackController;
  late final TextEditingController _githubController;
  late final TextEditingController _liveUrlController;
  late final TextEditingController _notesController;
  ProjectStatus _status = ProjectStatus.inProgress;
  double _progress = 0.2;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProject;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _techStackController = TextEditingController(text: p?.techStack ?? '');
    _githubController = TextEditingController(text: p?.githubUrl ?? '');
    _liveUrlController = TextEditingController(text: p?.liveUrl ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _notesController = TextEditingController(text: p?.notes ?? widget.initialNotes ?? '');
    _status = ProjectStatus.fromString(p?.status);
    _progress = p?.progress ?? 0.2;
    _deadline = p?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _techStackController.dispose();
    _githubController.dispose();
    _liveUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workRepositoryProvider);
      if (widget.existingProject != null) {
        await repo.updateProject(
          id: widget.existingProject!.id,
          name: _nameController.text,
          description: _descController.text,
          status: _status,
          progress: _progress,
          techStack: _techStackController.text,
          githubUrl: _githubController.text,
          liveUrl: _liveUrlController.text,
          deadline: _deadline,
          notes: _notesController.text,
          clientId: widget.existingProject!.clientId ?? widget.initialClientId,
          isFreelance: widget.existingProject!.isFreelance,
        );
      } else {
        await repo.addProject(
          name: _nameController.text,
          description: _descController.text,
          status: _status,
          progress: _progress,
          techStack: _techStackController.text,
          githubUrl: _githubController.text,
          liveUrl: _liveUrlController.text,
          deadline: _deadline,
          notes: _notesController.text,
          clientId: widget.initialClientId,
          isFreelance: widget.isFreelance,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save project: $e')),
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
    final isEditing = widget.existingProject != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
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
                      isEditing ? 'Edit Work Project' : 'New Work Project',
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'e.g. Distributed Task Queue',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Project name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ProjectStatus>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ProjectStatus.values.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _progress,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(_progress * 100).toInt()}%',
                            onChanged: (val) => setState(() => _progress = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event_outlined, size: 16),
                        label: Text(_deadline != null
                            ? 'Target Deadline: ${DateFormatter.formatDate(_deadline)}'
                            : 'Set Target Deadline (Optional)'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1825)),
                          );
                          if (picked != null) setState(() => _deadline = picked);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _techStackController,
                        decoration: const InputDecoration(
                          labelText: 'Tech Stack (Comma-separated)',
                          hintText: 'e.g. Flutter, Go, Redis, PostgreSQL',
                          prefixIcon: Icon(Icons.layers_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _githubController,
                        decoration: const InputDecoration(
                          labelText: 'GitHub Repository URL',
                          hintText: 'https://github.com/...',
                          prefixIcon: Icon(Icons.code, size: 20),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _liveUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Live Demo / Documentation URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.public, size: 20),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Project Overview & Architecture',
                          hintText: 'Goals, architecture, design decisions...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes / Scratchpad',
                          hintText: 'Key milestones, deployment commands, credentials ref...',
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
                          : Text(isEditing ? 'Save Changes' : 'Create Project'),
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
