import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';
import 'add_edit_workout_dialog.dart';

class WorkoutDetailsScreen extends ConsumerWidget {
  final Workout? workout;
  final String? workoutId;

  const WorkoutDetailsScreen({
    super.key,
    this.workout,
    this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = workout?.id ?? workoutId;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid workout ID.')));
    }

    final workoutAsync = ref.watch(workoutByIdProvider(id));
    final currentWorkout = workoutAsync.valueOrNull ?? workout;

    if (currentWorkout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Session')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final exercisesAsync = ref.watch(workoutExercisesStreamProvider(currentWorkout.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentWorkout.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Duplicate as Today\'s Workout',
            onPressed: () async {
              final exercises = exercisesAsync.valueOrNull ?? [];
              showDialog(
                context: context,
                builder: (_) => AddEditWorkoutDialog(
                  initialTemplateName: currentWorkout.name,
                  initialExercises: exercises,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Workout',
            onPressed: () {
              final exercises = exercisesAsync.valueOrNull ?? [];
              showDialog(
                context: context,
                builder: (_) => AddEditWorkoutDialog(
                  workoutToEdit: currentWorkout,
                  initialExercises: exercises,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Workout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Workout?'),
                  content: Text('Are you sure you want to delete "${currentWorkout.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(trackRepositoryProvider).deleteWorkout(currentWorkout.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Workout Overview Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentWorkout.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatDate(currentWorkout.date),
                              style: TextStyle(color: theme.hintColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (currentWorkout.duration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '${currentWorkout.duration}m',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (currentWorkout.notes != null && currentWorkout.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      currentWorkout.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exercises Header
          Text(
            'EXERCISES & SETS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No exercises recorded for this session.')),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final ex = exercises[idx];

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.exerciseName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                if (ex.notes != null && ex.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ex.notes!,
                                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ex.sets} sets × ${ex.reps} reps${ex.weight > 0 ? ' @ ${ex.weight.toStringAsFixed(1)} kg' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading exercises: $e'),
          ),
        ],
      ),
    );
  }
}
