import 'package:flutter/material.dart';
import '../../domain/automation_models.dart';

class AutomationRunResultDialog extends StatelessWidget {
  final RuleEvaluationResult result;
  final String title;

  const AutomationRunResultDialog({
    super.key,
    required this.result,
    this.title = 'Automation Execution Result',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            result.isSuccess ? Icons.check_circle : Icons.error_outline,
            color: result.isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.isSuccess
                      ? Colors.green.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.isSuccess
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Evaluated', result.itemsEvaluated.toString(), theme),
                    _buildStatCol('New / Flagged', result.itemsCreated.toString(), theme),
                    _buildStatCol('Actions', result.proposedActions.length.toString(), theme),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (result.messages.isNotEmpty) ...[
                Text('Execution Logs:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...result.messages.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $m', style: theme.textTheme.bodySmall),
                    )),
              ],
              if (result.proposedActions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Proposed Actions:', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...result.proposedActions.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(a.description, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
      ],
    );
  }
}
