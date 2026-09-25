import 'package:flutter/material.dart';
import '../../domain/resume_profile_models.dart';

class ResumeQualityAuditDialog extends StatelessWidget {
  final ResumeProfile profile;

  const ResumeQualityAuditDialog({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audit = profile.qualityAudit;

    Color scoreColor;
    if (audit.score >= 80) {
      scoreColor = Colors.green.shade600;
    } else if (audit.score >= 60) {
      scoreColor = Colors.amber.shade700;
    } else {
      scoreColor = Colors.red.shade600;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 620),
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
                    child: Icon(Icons.analytics_outlined, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume Quality & ATS Audit',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          profile.resumeName,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: audit.score / 100,
                          backgroundColor: scoreColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          strokeWidth: 6,
                        ),
                        Text(
                          '${audit.score}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audit.score >= 80 ? 'Excellent Resume Structure' : (audit.score >= 60 ? 'Good Baseline, Needs Polish' : 'Needs Structural Improvement'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Deterministic ATS parsing audit based on industry resume standards.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    if (audit.passedChecks.isNotEmpty) ...[
                      Text(
                        'PASSED CHECKS (${audit.passedChecks.length})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...audit.passedChecks.map(
                        (check) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(check, style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (audit.improvementSuggestions.isNotEmpty) ...[
                      Text(
                        'RECOMMENDED IMPROVEMENTS (${audit.improvementSuggestions.length})',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...audit.improvementSuggestions.map(
                        (sugg) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(sugg, style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
