import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';

class AddEditDSADialog extends ConsumerStatefulWidget {
  final DSAProblem? problemToEdit;

  const AddEditDSADialog({super.key, this.problemToEdit});

  @override
  ConsumerState<AddEditDSADialog> createState() => _AddEditDSADialogState();
}

class _AddEditDSADialogState extends ConsumerState<AddEditDSADialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _solutionController;
  late final TextEditingController _notesController;

  String _platform = 'LeetCode';
  String _topic = 'Arrays';
  DSADifficulty _difficulty = DSADifficulty.medium;
  DSAStatus _status = DSAStatus.todo;
  DateTime? _revisionDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.problemToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _urlController = TextEditingController(text: p?.url ?? '');
    _solutionController = TextEditingController(text: p?.solution ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    _platform = p?.platform ?? 'LeetCode';
    _topic = p?.topic ?? 'Arrays';
    _difficulty = DSADifficulty.fromString(p?.difficulty);
    _status = DSAStatus.fromString(p?.status);
    _revisionDate = p?.revisionDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _solutionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(trackRepositoryProvider);
      if (widget.problemToEdit != null) {
        await repo.updateDSAProblem(
          id: widget.problemToEdit!.id,
          title: _titleController.text,
          platform: _platform,
          url: _urlController.text,
          topic: _topic,
          difficulty: _difficulty,
          status: _status,
          solution: _solutionController.text,
          notes: _notesController.text,
          revisionDate: _revisionDate,
          solvedAt: widget.problemToEdit!.solvedAt,
        );
      } else {
        await repo.addDSAProblem(
          title: _titleController.text,
          platform: _platform,
          url: _urlController.text,
          topic: _topic,
          difficulty: _difficulty,
          status: _status,
          solution: _solutionController.text,
          notes: _notesController.text,
          revisionDate: _revisionDate,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving problem: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.problemToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
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
                      isEditing ? 'Edit DSA Problem' : 'Log DSA Problem',
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
                          labelText: 'Problem Title *',
                          hintText: 'e.g. Two Sum, LRU Cache, Course Schedule',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),

                      // Platform & Topic Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: dsaPlatforms.contains(_platform) ? _platform : 'Other',
                              decoration: const InputDecoration(labelText: 'Platform'),
                              items: dsaPlatforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _platform = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: dsaTopics.contains(_topic) ? _topic : 'Other',
                              decoration: const InputDecoration(labelText: 'Topic'),
                              items: dsaTopics.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _topic = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Difficulty & Status Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DSADifficulty>(
                              value: _difficulty,
                              decoration: const InputDecoration(labelText: 'Difficulty'),
                              items: DSADifficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _difficulty = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<DSAStatus>(
                              value: _status,
                              decoration: const InputDecoration(labelText: 'Status'),
                              items: DSAStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _status = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Problem URL',
                          hintText: 'https://leetcode.com/problems/...',
                          prefixIcon: Icon(Icons.link, size: 20),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),

                      // Revision Date Selector
                      OutlinedButton.icon(
                        icon: const Icon(Icons.alarm, size: 16),
                        label: Text(_revisionDate != null
                            ? 'Next Revision: ${DateFormatter.formatDate(_revisionDate)}'
                            : 'Set Revision Date (Optional)'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _revisionDate ?? DateTime.now().add(const Duration(days: 3)),
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() => _revisionDate = picked);
                        },
                      ),
                      if (_revisionDate != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _revisionDate = null),
                            child: const Text('Clear Revision Date', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _solutionController,
                        decoration: const InputDecoration(
                          labelText: 'Solution & Approach',
                          hintText: 'Algorithm, Time/Space complexity (e.g. O(N) time using HashMap), Key edge cases...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Personal Notes / Gotchas',
                          hintText: 'Mistakes made in first attempt, pattern references...',
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
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(isEditing ? 'Save Changes' : 'Add Problem'),
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
