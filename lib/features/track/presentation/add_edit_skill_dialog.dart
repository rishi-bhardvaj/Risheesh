import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/track_providers.dart';

class AddEditSkillDialog extends ConsumerStatefulWidget {
  final LearningSkill? skillToEdit;

  const AddEditSkillDialog({super.key, this.skillToEdit});

  @override
  ConsumerState<AddEditSkillDialog> createState() => _AddEditSkillDialogState();
}

class _AddEditSkillDialogState extends ConsumerState<AddEditSkillDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  String _category = 'Technical';
  SkillLevel _currentLevel = SkillLevel.beginner;
  SkillLevel _targetLevel = SkillLevel.advanced;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.skillToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _category = s?.category ?? 'Technical';
    _currentLevel = SkillLevel.fromString(s?.currentLevel);
    _targetLevel = SkillLevel.fromString(s?.targetLevel);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(trackRepositoryProvider);
      if (widget.skillToEdit != null) {
        await repo.updateSkill(
          id: widget.skillToEdit!.id,
          name: _nameController.text,
          category: _category,
          currentLevel: _currentLevel,
          targetLevel: _targetLevel,
          notes: _notesController.text,
        );
      } else {
        await repo.addSkill(
          name: _nameController.text,
          category: _category,
          currentLevel: _currentLevel,
          targetLevel: _targetLevel,
          notes: _notesController.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving skill: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.skillToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
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
                      isEditing ? 'Edit Learning Skill' : 'New Learning Skill',
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
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Skill Name *',
                          hintText: 'e.g. System Design, Redis, Kafka, Flutter, Go',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Skill name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: skillCategories.contains(_category) ? _category : 'Other',
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: skillCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<SkillLevel>(
                              value: _currentLevel,
                              decoration: const InputDecoration(labelText: 'Current Level'),
                              items: SkillLevel.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _currentLevel = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<SkillLevel>(
                              value: _targetLevel,
                              decoration: const InputDecoration(labelText: 'Target Level'),
                              items: SkillLevel.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _targetLevel = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Learning Goals / Notes (Optional)',
                          hintText: 'Target milestones, books, project integration ideas...',
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
                          : Text(isEditing ? 'Save Changes' : 'Create Skill'),
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
