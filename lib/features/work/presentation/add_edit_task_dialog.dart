import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/work_providers.dart';

class AddEditTaskDialog extends ConsumerStatefulWidget {
  final Task? existingTask;
  final String? initialProjectId;
  final String? initialCategory;
  final String? initialTitle;
  final String? initialNotes;

  const AddEditTaskDialog({
    super.key,
    this.existingTask,
    this.initialProjectId,
    this.initialCategory,
    this.initialTitle,
    this.initialNotes,
  });

  @override
  ConsumerState<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends ConsumerState<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _notesController;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  String _category = 'work'; // 'work', 'personal'
  String? _selectedProjectId;
  DateTime? _dueDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleController = TextEditingController(text: t?.title ?? widget.initialTitle ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _notesController = TextEditingController(text: t?.notes ?? widget.initialNotes ?? '');
    _priority = TaskPriority.fromString(t?.priority);
    _status = TaskStatus.fromString(t?.status);
    _category = t?.category ?? widget.initialCategory ?? 'work';
    _selectedProjectId = t?.projectId ?? widget.initialProjectId;
    _dueDate = t?.dueDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workRepositoryProvider);
      if (widget.existingTask != null) {
        await repo.updateTask(
          id: widget.existingTask!.id,
          title: _titleController.text,
          description: _descController.text,
          priority: _priority,
          status: _status,
          category: _category,
          projectId: _selectedProjectId,
          dueDate: _dueDate,
          notes: _notesController.text,
        );
      } else {
        await repo.addTask(
          title: _titleController.text,
          description: _descController.text,
          priority: _priority,
          status: _status,
          category: _category,
          projectId: _selectedProjectId,
          dueDate: _dueDate,
          notes: _notesController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
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
    final isEditing = widget.existingTask != null;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final projects = projectsAsync.valueOrNull ?? [];

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
                      isEditing ? 'Edit Work Task' : 'New Work Task',
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
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title *',
                          hintText: 'e.g. Implement cache invalidation logic',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      // Category & Priority Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration: const InputDecoration(labelText: 'Category'),
                              items: const [
                                DropdownMenuItem(value: 'work', child: Text('Work')),
                                DropdownMenuItem(value: 'personal', child: Text('Personal')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              value: _priority,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: TaskPriority.values.map((p) {
                                return DropdownMenuItem(value: p, child: Text(p.label));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _priority = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status & Project Row
                      Row(
                        children: [
                          if (isEditing) ...[
                            Expanded(
                              child: DropdownButtonFormField<TaskStatus>(
                                value: _status,
                                decoration: const InputDecoration(labelText: 'Status'),
                                items: TaskStatus.values.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s.label));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _status = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedProjectId,
                              decoration: const InputDecoration(
                                labelText: 'Project (Optional)',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No Project (Standalone)'),
                                ),
                                ...projects.map((p) => DropdownMenuItem<String?>(
                                      value: p.id,
                                      child: Text(
                                        p.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (val) => setState(() => _selectedProjectId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Due Date Picker Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_dueDate != null
                            ? 'Due Date: ${DateFormatter.formatDate(_dueDate)}'
                            : 'No Due Date Set'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) setState(() => _dueDate = picked);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Scope, requirements, ticket references...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Checklist (Optional)',
                          hintText: 'Personal notes, snippets, or checklist...',
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
                          : Text(isEditing ? 'Save Changes' : 'Create Task'),
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
