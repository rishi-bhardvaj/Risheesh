import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track & Health'),
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
            // Header Info
            Text(
              'TRACKING MODULES',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Personal discipline tracking for fitness, workouts, body weight, income, and expense management.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Fitness Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fitness_center, color: Color(0xFF10B981), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Fitness & Workouts',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Push / Pull / Legs, Body Weight, Protein',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                            'Phase 5',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Fitness tracking will be implemented in Phase 5 with workout templates, exercise sets/reps logs, and body weight progression charts.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Finance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF38BDF8), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Finance & Expenses',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Income, Monthly Burn, Savings, CSV Export',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                            'Phase 5',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Finance tracking will be implemented in Phase 5 with simple income/expense logging, category breakdown, and CSV data export without third-party banking access.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

