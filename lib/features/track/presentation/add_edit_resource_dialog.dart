import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/track_providers.dart';

class AddEditResourceDialog extends ConsumerStatefulWidget {
  final Resource? resourceToEdit;
  final String? initialSkillId;

  const AddEditResourceDialog({super.key, this.resourceToEdit, this.initialSkillId});

  @override
  ConsumerState<AddEditResourceDialog> createState() => _AddEditResourceDialogState();
}

class _AddEditResourceDialogState extends ConsumerState<AddEditResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _categoryController;
  late final TextEditingController _tagsController;
  late final TextEditingController _notesController;

  ResourceType _type = ResourceType.documentation;
  ResourceStatus _status = ResourceStatus.toRead;
  String? _selectedSkillId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final r = widget.resourceToEdit;
    _titleController = TextEditingController(text: r?.title ?? '');
    _urlController = TextEditingController(text: r?.url ?? '');
    _categoryController = TextEditingController(text: r?.category ?? '');
    _tagsController = TextEditingController(text: r?.tags ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');

    _type = ResourceType.fromString(r?.type);
    _status = ResourceStatus.fromString(r?.status);
    _selectedSkillId = r?.skillId ?? widget.initialSkillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(trackRepositoryProvider);
      if (widget.resourceToEdit != null) {
        await repo.updateResource(
          id: widget.resourceToEdit!.id,
          title: _titleController.text,
          url: _urlController.text,
          type: _type,
          category: _categoryController.text,
          tags: _tagsController.text,
          status: _status,
          notes: _notesController.text,
          skillId: _selectedSkillId,
        );
      } else {
        await repo.addResource(
          title: _titleController.text,
          url: _urlController.text,
          type: _type,
          category: _categoryController.text,
          tags: _tagsController.text,
          status: _status,
          notes: _notesController.text,
          skillId: _selectedSkillId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving resource: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.resourceToEdit != null;
    final skills = ref.watch(skillsStreamProvider).valueOrNull ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      isEditing ? 'Edit Learning Resource' : 'Add Learning Resource',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Resource Title *',
                          hintText: 'e.g. Designing Data-Intensive Applications, CS61B Lectures',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Resource URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link, size: 20),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ResourceType>(
                              value: _type,
                              decoration: const InputDecoration(labelText: 'Type'),
                              items: ResourceType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _type = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<ResourceStatus>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: ResourceStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: _selectedSkillId,
                        decoration: const InputDecoration(labelText: 'Link to Skill (Optional)'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('No Skill (General Resource)')),
                          ...skills.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: (val) => setState(() => _selectedSkillId = val),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (Comma-separated)',
                          hintText: 'architecture, sql, system-design, free',
                          prefixIcon: Icon(Icons.tag, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Key Takeaways (Optional)',
                          hintText: 'Summary, chapters completed, references...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Save Resource'),
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
