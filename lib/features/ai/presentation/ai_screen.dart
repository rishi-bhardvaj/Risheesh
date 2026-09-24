import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AIScreen extends ConsumerWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal AI Assistant',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Local Ollama & Private Context Engine',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Phase 6',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'AI integration is architected for Phase 6 with support for local Ollama instances (e.g. http://127.0.0.1:11434) and private on-device structured context injection.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'PLANNED CAPABILITIES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            _buildCapabilityTile(
              icon: Icons.notes,
              title: 'Automated EOD Synthesis',
              description: 'Synthesizes today’s completed tasks and git commits into clean professional standup updates.',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildCapabilityTile(
              icon: Icons.psychology_outlined,
              title: 'Job Match & Gap Analysis',
              description: 'Compares job descriptions against your Career Profile to highlight skill matches and missing keywords.',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildCapabilityTile(
              icon: Icons.mail_outline,
              title: 'Recruiter Outreach Drafts',
              description: 'Generates customized LinkedIn notes, follow-up emails, and tailored cover letters with review before sending.',
              theme: theme,
            ),
            const SizedBox(height: 8),
            _buildCapabilityTile(
              icon: Icons.check_circle_outline,
              title: 'Structured Actions with Confirmation',
              description: 'Allows conversational quick capture with explicit confirmation before any database mutations.',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityTile({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3,
                    ),
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

