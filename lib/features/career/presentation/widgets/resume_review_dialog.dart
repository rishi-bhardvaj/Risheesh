import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/resume_profile_models.dart';
import '../../services/career_profile_sync_service.dart';

class ResumeReviewDialog extends ConsumerStatefulWidget {
  final ResumeProfile extractedProfile;
  final UserProfile existingProfile;

  const ResumeReviewDialog({
    super.key,
    required this.extractedProfile,
    required this.existingProfile,
  });

  @override
  ConsumerState<ResumeReviewDialog> createState() => _ResumeReviewDialogState();
}

class _ResumeReviewDialogState extends ConsumerState<ResumeReviewDialog> {
  final _syncService = CareerProfileSyncService();
  late List<ProfileDiffItem> _diffs;
  late Set<String> _selectedFieldNames;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _diffs = _syncService.computeDifferences(
      existingProfile: widget.existingProfile,
      extractedProfile: widget.extractedProfile,
    );
    _selectedFieldNames = _diffs
        .where((d) => d.selectedByDefault)
        .map((d) => d.fieldName)
        .toSet();
  }

  Future<void> _applySelectedDiffs() async {
    setState(() => _isSaving = true);
    try {
      final approvedDiffs = _diffs
          .where((d) => _selectedFieldNames.contains(d.fieldName))
          .toList();

      final updatedCompanion = _syncService.buildUpdatedCompanion(
        existingProfile: widget.existingProfile,
        approvedDiffs: approvedDiffs,
      );

      final db = ref.read(databaseProvider);
      await db.upsertProfile(updatedCompanion);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${approvedDiffs.length} profile fields from resume!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.sync_alt, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume Extraction Review',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.extractedProfile.resumeName,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Review extracted resume data before merging into your Career Profile. Uncheck any field you do not wish to overwrite.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Divider(height: 24),
              Expanded(
                child: _diffs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade600),
                          const SizedBox(height: 12),
                          const Text(
                            'Career Profile is already in sync with this resume!',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _diffs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final diff = _diffs[index];
                        final isChecked = _selectedFieldNames.contains(diff.fieldName);

                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedFieldNames.add(diff.fieldName);
                              } else {
                                _selectedFieldNames.remove(diff.fieldName);
                              }
                            });
                          },
                          title: Text(
                            diff.label,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current: ',
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  Expanded(
                                    child: Text(
                                      diff.currentValue?.isNotEmpty == true ? diff.currentValue! : '(Empty)',
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Extracted: ',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  ),
                                  Expanded(
                                    child: Text(
                                      diff.extractedValue,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Skip / Keep Existing'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isSaving ? 'Updating...' : 'Sync Selected Fields (${_selectedFieldNames.length})'),
                    onPressed: _diffs.isEmpty || _selectedFieldNames.isEmpty || _isSaving
                        ? null
                        : _applySelectedDiffs,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
