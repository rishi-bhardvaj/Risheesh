import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/resume_storage_helper.dart';

class AddEditResumeDialog extends ConsumerStatefulWidget {
  final Resume? resumeToEdit;

  const AddEditResumeDialog({super.key, this.resumeToEdit});

  @override
  ConsumerState<AddEditResumeDialog> createState() => _AddEditResumeDialogState();
}

class _AddEditResumeDialogState extends ConsumerState<AddEditResumeDialog> {
  final _formKey = GlobalKey<FormState>();
  static const _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _targetRoleController;
  late TextEditingController _notesController;

  String? _filePath;
  String? _fileName;
  int? _fileSize;
  bool _isPrimary = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    final r = widget.resumeToEdit;
    _nameController = TextEditingController(text: r?.name ?? '');
    _versionController = TextEditingController(text: r?.version ?? 'v1.0');
    _targetRoleController = TextEditingController(text: r?.targetRole ?? '');
    _notesController = TextEditingController(text: r?.notes ?? '');

    if (r != null) {
      _filePath = r.filePath;
      _fileName = r.fileName;
      _isPrimary = r.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _targetRoleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await ResumeStorageHelper.pickAndSaveResume();
      if (result != null) {
        setState(() {
          _filePath = result.localPath;
          _fileName = result.fileName;
          _fileSize = result.fileSizeBytes;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = result.fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select resume: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_filePath == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a resume file (PDF, DOCX, etc.)')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final isEditing = widget.resumeToEdit != null;
    final now = DateTime.now();
    final id = isEditing ? widget.resumeToEdit!.id : _uuid.v4();

    final companion = ResumesCompanion(
      id: drift.Value(id),
      name: drift.Value(_nameController.text.trim()),
      version: drift.Value(_versionController.text.trim().isEmpty ? 'v1.0' : _versionController.text.trim()),
      targetRole: drift.Value(_targetRoleController.text.trim().isEmpty ? null : _targetRoleController.text.trim()),
      filePath: drift.Value(_filePath!),
      fileName: drift.Value(_fileName!),
      notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
      isPrimary: drift.Value(_isPrimary),
      createdAt: drift.Value(isEditing ? widget.resumeToEdit!.createdAt : now),
      updatedAt: drift.Value(now),
    );

    if (isEditing) {
      await db.updateResume(companion);
    } else {
      await db.insertResume(companion);
    }

    if (_isPrimary) {
      await db.setPrimaryResume(id);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Resume updated' : 'Resume added to vault')),
      );
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.resumeToEdit != null;

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
                    isEditing ? Icons.edit_note : Icons.cloud_upload_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Resume Version' : 'Add Resume to Vault',
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
                    // File Picker Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _fileName != null ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                          width: _fileName != null ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _fileName != null ? Icons.picture_as_pdf : Icons.upload_file,
                                color: _fileName != null ? Colors.redAccent : theme.colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName ?? 'No resume file selected',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _fileSize != null
                                          ? _formatFileSize(_fileSize)
                                          : 'Supports PDF, DOCX, DOC files (saved locally)',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: _isPicking ? null : _pickFile,
                                icon: _isPicking
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.folder_open, size: 18),
                                label: Text(_fileName != null ? 'Change' : 'Browse'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Resume Title / Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Resume Name *',
                        hintText: 'e.g. Backend Java Resume, Full Stack v3',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Resume name is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Version & Target Role Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _versionController,
                            decoration: const InputDecoration(
                              labelText: 'Version',
                              hintText: 'v1.0, v2.1',
                              prefixIcon: Icon(Icons.tag),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _targetRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Target Role',
                              hintText: 'e.g. Java Backend, DevOps',
                              prefixIcon: Icon(Icons.work_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Customizations',
                        hintText: 'e.g. ATS friendly format, highlights distributed systems and AWS...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.note_alt_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // Primary Resume Switch
                    SwitchListTile(
                      title: const Text('Set as Primary Resume'),
                      subtitle: const Text('Used as the default resume for new applications'),
                      secondary: Icon(
                        _isPrimary ? Icons.star : Icons.star_border,
                        color: _isPrimary ? Colors.amber : null,
                      ),
                      value: _isPrimary,
                      onChanged: (v) => setState(() => _isPrimary = v),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Save Changes' : 'Save Resume'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

