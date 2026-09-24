import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/work_providers.dart';

class AddEditEODDialog extends ConsumerStatefulWidget {
  final EODNote? existingNote;
  final DateTime? initialDate;

  const AddEditEODDialog({
    super.key,
    this.existingNote,
    this.initialDate,
  });

  @override
  ConsumerState<AddEditEODDialog> createState() => _AddEditEODDialogState();
}

class _AddEditEODDialogState extends ConsumerState<AddEditEODDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _completedController;
  late final TextEditingController _inProgressController;
  late final TextEditingController _blockersController;
  late final TextEditingController _tomorrowController;
  late final TextEditingController _notesController;
  late DateTime _date;
  String? _existingId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _date = note?.date ?? widget.initialDate ?? DateTime.now();
    _existingId = note?.id;

    _completedController = TextEditingController(text: note?.completedWork ?? '');
    _inProgressController = TextEditingController(text: note?.inProgressWork ?? '');
    _blockersController = TextEditingController(text: note?.blockers ?? '');
    _tomorrowController = TextEditingController(text: note?.tomorrowPlan ?? '');
    _notesController = TextEditingController(text: note?.notes ?? '');

    // If no explicit existing note was passed, check if one exists for the selected date
    if (note == null) {
      _checkExistingForDate(_date);
    }
  }

  Future<void> _checkExistingForDate(DateTime date) async {
    final db = ref.read(databaseProvider);
    final existing = await db.getEODNoteForDate(date);
    if (existing != null && mounted) {
      setState(() {
        _existingId = existing.id;
        _completedController.text = existing.completedWork;
        _inProgressController.text = existing.inProgressWork;
        _blockersController.text = existing.blockers ?? '';
        _tomorrowController.text = existing.tomorrowPlan ?? '';
        _notesController.text = existing.notes ?? '';
      });
    }
  }

  @override
  void dispose() {
    _completedController.dispose();
    _inProgressController.dispose();
    _blockersController.dispose();
    _tomorrowController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(workRepositoryProvider).saveEODNote(
            existingId: _existingId,
            date: _date,
            completedWork: _completedController.text,
            inProgressWork: _inProgressController.text,
            blockers: _blockersController.text,
            tomorrowPlan: _tomorrowController.text,
            notes: _notesController.text,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingId != null ? 'EOD Log updated successfully' : 'EOD Log saved successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save EOD update: $e')),
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
    final isEditing = _existingId != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
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
                      isEditing ? 'Edit EOD Log' : 'Log EOD Update',
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
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('Log Date: ${DateFormatter.formatDate(_date)}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                          );
                          if (picked != null) {
                            setState(() => _date = picked);
                            _checkExistingForDate(picked);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _completedController,
                        decoration: const InputDecoration(
                          labelText: '1. What I Completed Today *',
                          hintText: '• Merged PR #104\n• Finished API endpoints for auth\n• Documented schema',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter completed work' : null,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _inProgressController,
                        decoration: const InputDecoration(
                          labelText: '2. What I Worked On / In Progress *',
                          hintText: '• Profiling slow query performance\n• Writing integration tests',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter in-progress work' : null,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _blockersController,
                        decoration: const InputDecoration(
                          labelText: '3. Blockers / Need Help With (Optional)',
                          hintText: 'Waiting on DevOps access key or client approval...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tomorrowController,
                        decoration: const InputDecoration(
                          labelText: '4. Plan for Tomorrow (Optional)',
                          hintText: '• Review pull request #105\n• Push v1.2 release to staging',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: '5. Additional Standup Notes (Optional)',
                          hintText: 'Shoutouts, meetings attended, reminders...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
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
                          : Text(isEditing ? 'Update EOD' : 'Save EOD Log'),
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

