import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data Governance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner
          Card(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Data Never Leaves Your Device',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Career OS operates under an uncompromising offline-first, zero-telemetry guarantee.',
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Privacy Pillars
          Text(
            'PRIVACY PILLARS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _buildPolicyCard(
            context,
            icon: Icons.storage_outlined,
            title: '1. On-Device SQLite Storage',
            description:
                'Every job application, resume, task, project note, freelance invoice, DSA problem, workout log, and financial record is saved in a local SQLite database in your application\'s sandboxed internal storage directory. No remote server has a replica of your data.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.block_outlined,
            title: '2. Zero Telemetry & Tracking',
            description:
                'Career OS includes no telemetry frameworks, tracking cookies, advertising identifiers, or third-party analytics trackers. Your usage patterns, work habits, and financial logs remain 100% private to you.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.memory_outlined,
            title: '3. Local AI Execution (Ollama)',
            description:
                'Our AI subsystem is designed to query a local Ollama instance (such as http://127.0.0.1:11434) running on your own machine. Data context synthesized for AI responses stays entirely on your local machine network.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.download_for_offline_outlined,
            title: '4. Public Discovery Feeds Only',
            description:
                'Automated discovery features only parse public, unauthenticated RSS/Atom feeds configured explicitly by you. No user credentials, session cookies, or private tokens are sent to external discovery servers.',
          ),
          const SizedBox(height: 12),
          _buildPolicyCard(
            context,
            icon: Icons.delete_forever_outlined,
            title: '5. Absolute Data Ownership',
            description:
                'You retain total ownership and control over your data. You can delete or modify any entry directly from the application at any time without asking permission.',
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
