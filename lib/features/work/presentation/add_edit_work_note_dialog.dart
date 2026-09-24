import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/work_providers.dart';

class AddEditWorkNoteDialog extends ConsumerStatefulWidget {
  final WorkNote? existingNote;
  final String? initialType;
  final String? initialProjectId;

  const AddEditWorkNoteDialog({
    super.key,
    this.existingNote,
    this.initialType,
    this.initialProjectId,
  });

  @override
  ConsumerState<AddEditWorkNoteDialog> createState() => _AddEditWorkNoteDialogState();
}

class _AddEditWorkNoteDialogState extends ConsumerState<AddEditWorkNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _participantsController;
  late final TextEditingController _actionItemsController;
  String _noteType = 'general';
  String? _selectedProjectId;
  DateTime? _meetingDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final n = widget.existingNote;
    _titleController = TextEditingController(text: n?.title ?? '');
    _contentController = TextEditingController(text: n?.content ?? '');
    _participantsController = TextEditingController(text: n?.participants ?? '');
    _actionItemsController = TextEditingController(text: n?.actionItems ?? '');
    _noteType = n?.noteType ?? widget.initialType ?? 'general';
    _selectedProjectId = n?.projectId ?? widget.initialProjectId;
    _meetingDate = n?.meetingDate ?? (n == null && _noteType == 'meeting' ? DateTime.now() : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _participantsController.dispose();
    _actionItemsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workRepositoryProvider);
      if (widget.existingNote != null) {
        await repo.updateWorkNote(
          id: widget.existingNote!.id,
          title: _titleController.text,
          content: _contentController.text,
          noteType: _noteType,
          projectId: _selectedProjectId,
          meetingDate: _noteType == 'meeting' ? (_meetingDate ?? DateTime.now()) : null,
          participants: _participantsController.text,
          actionItems: _actionItemsController.text,
        );
      } else {
        await repo.addWorkNote(
          title: _titleController.text,
          content: _contentController.text,
          noteType: _noteType,
          projectId: _selectedProjectId,
          meetingDate: _noteType == 'meeting' ? (_meetingDate ?? DateTime.now()) : null,
          participants: _participantsController.text,
          actionItems: _actionItemsController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save work note: $e')),
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
    final isEditing = widget.existingNote != null;
    final projects = ref.watch(projectsStreamProvider).valueOrNull ?? [];

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
                      isEditing ? 'Edit Work Note' : 'New Work Note',
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
                      // Note Type & Project Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _noteType,
                              decoration: const InputDecoration(labelText: 'Note Type'),
                              items: const [
                                DropdownMenuItem(value: 'general', child: Text('General Note')),
                                DropdownMenuItem(value: 'meeting', child: Text('Meeting Note')),
                                DropdownMenuItem(value: 'technical', child: Text('Technical Spec')),
                                DropdownMenuItem(value: 'instruction', child: Text('Instructions / Runbook')),
                                DropdownMenuItem(value: 'investigation', child: Text('Investigation / Bug')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _noteType = val;
                                    if (_noteType == 'meeting' && _meetingDate == null) {
                                      _meetingDate = DateTime.now();
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedProjectId,
                              decoration: const InputDecoration(labelText: 'Project (Optional)'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('No Project'),
                                ),
                                ...projects.map((p) => DropdownMenuItem<String?>(
                                      value: p.id,
                                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (val) => setState(() => _selectedProjectId = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: _noteType == 'meeting' ? 'Meeting Title *' : 'Note Title *',
                          hintText: _noteType == 'meeting'
                              ? 'e.g. Sprint 14 Architecture Alignment'
                              : 'e.g. Postgres Index Optimization Strategy',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      if (_noteType == 'meeting') ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_meetingDate != null
                              ? 'Meeting Date: ${DateFormatter.formatDate(_meetingDate)}'
                              : 'Select Meeting Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _meetingDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _meetingDate = picked);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _participantsController,
                          decoration: const InputDecoration(
                            labelText: 'Participants / Attendees',
                            hintText: 'e.g. Alice (EM), Bob (Lead), Charlie',
                            prefixIcon: Icon(Icons.people_outline, size: 20),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          labelText: _noteType == 'meeting' ? 'Meeting Notes & Discussion *' : 'Content / Body *',
                          hintText: 'Detailed notes, takeaways, design points...',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _actionItemsController,
                        decoration: const InputDecoration(
                          labelText: 'Action Items (One per line)',
                          hintText: '• Review draft PR #204\n• Update database migration schema',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
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
                          : Text(isEditing ? 'Save Changes' : 'Create Note'),
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

