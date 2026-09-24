import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../providers/work_providers.dart';

class AddEditThingToAskDialog extends ConsumerStatefulWidget {
  final ThingsToAsk? existingItem;

  const AddEditThingToAskDialog({super.key, this.existingItem});

  @override
  ConsumerState<AddEditThingToAskDialog> createState() => _AddEditThingToAskDialogState();
}

class _AddEditThingToAskDialogState extends ConsumerState<AddEditThingToAskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  String _priority = 'medium'; // 'high', 'medium', 'low'
  String _status = 'open'; // 'open', 'resolved'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priority = item?.priority ?? 'medium';
    _status = item?.status ?? 'open';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workRepositoryProvider);
      if (widget.existingItem != null) {
        await repo.updateThingToAsk(
          id: widget.existingItem!.id,
          title: _titleController.text,
          description: _descController.text,
          priority: _priority,
          status: _status,
        );
      } else {
        await repo.addThingToAsk(
          title: _titleController.text,
          description: _descController.text,
          priority: _priority,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save question: $e')),
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
    final isEditing = widget.existingItem != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
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
                      isEditing ? 'Edit Question / Blocker' : 'Add Thing to Ask',
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
                          labelText: 'Question / Topic *',
                          hintText: 'e.g. Clarify event idempotency SLA with Lead',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Question is required' : null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: const InputDecoration(labelText: 'Priority'),
                              items: const [
                                DropdownMenuItem(value: 'high', child: Text('High Priority')),
                                DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                                DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _priority = val);
                              },
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(labelText: 'Status'),
                                items: const [
                                  DropdownMenuItem(value: 'open', child: Text('Open / Pending')),
                                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _status = val);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Context & Background (Optional)',
                          hintText: 'Why this is needed, links, related PRs...',
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
                          : Text(isEditing ? 'Save Changes' : 'Add Question'),
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

