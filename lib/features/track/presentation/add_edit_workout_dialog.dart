import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';

class AddEditWorkoutDialog extends ConsumerStatefulWidget {
  final Workout? workoutToEdit;
  final List<WorkoutExercise>? initialExercises;
  final String? initialTemplateName;
  final List<String>? templateExercises;

  const AddEditWorkoutDialog({
    super.key,
    this.workoutToEdit,
    this.initialExercises,
    this.initialTemplateName,
    this.templateExercises,
  });

  @override
  ConsumerState<AddEditWorkoutDialog> createState() => _AddEditWorkoutDialogState();
}

class _ExerciseItem {
  final TextEditingController nameController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController notesController;

  _ExerciseItem({
    String name = '',
    int sets = 3,
    int reps = 10,
    double weight = 0.0,
    String notes = '',
  })  : nameController = TextEditingController(text: name),
        setsController = TextEditingController(text: sets.toString()),
        repsController = TextEditingController(text: reps.toString()),
        weightController = TextEditingController(text: weight > 0 ? weight.toString() : '0'),
        notesController = TextEditingController(text: notes);

  void dispose() {
    nameController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    notesController.dispose();
  }
}

class _AddEditWorkoutDialogState extends ConsumerState<AddEditWorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _notesController;
  DateTime _date = DateTime.now();
  final List<_ExerciseItem> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final w = widget.workoutToEdit;
    _nameController = TextEditingController(text: w?.name ?? widget.initialTemplateName ?? '');
    _durationController = TextEditingController(text: w?.duration != null ? '${w!.duration}' : '45');
    _notesController = TextEditingController(text: w?.notes ?? '');
    _date = w?.date ?? DateTime.now();

    if (widget.initialExercises != null && widget.initialExercises!.isNotEmpty) {
      for (final ex in widget.initialExercises!) {
        _exercises.add(_ExerciseItem(
          name: ex.exerciseName,
          sets: ex.sets,
          reps: ex.reps,
          weight: ex.weight,
          notes: ex.notes ?? '',
        ));
      }
    } else if (widget.templateExercises != null && widget.templateExercises!.isNotEmpty) {
      for (final exName in widget.templateExercises!) {
        _exercises.add(_ExerciseItem(name: exName));
      }
    } else if (w == null) {
      // Default initial exercise rows
      _exercises.add(_ExerciseItem(name: 'Bench Press', sets: 4, reps: 8, weight: 60));
      _exercises.add(_ExerciseItem(name: 'Incline Dumbbell Press', sets: 3, reps: 10, weight: 20));
      _exercises.add(_ExerciseItem(name: 'Tricep Rope Pushdown', sets: 3, reps: 12, weight: 25));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    for (final ex in _exercises) {
      ex.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exercises.add(_ExerciseItem(name: ''));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final removed = _exercises.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final duration = int.tryParse(_durationController.text.trim());
      final exerciseCompanions = _exercises.map((ex) {
        final sets = int.tryParse(ex.setsController.text.trim()) ?? 3;
        final reps = int.tryParse(ex.repsController.text.trim()) ?? 10;
        final weight = double.tryParse(ex.weightController.text.trim()) ?? 0.0;

        return WorkoutExercisesCompanion(
          exerciseName: drift.Value(ex.nameController.text.trim().isEmpty ? 'Exercise' : ex.nameController.text.trim()),
          sets: drift.Value(sets),
          reps: drift.Value(reps),
          weight: drift.Value(weight),
          notes: drift.Value(ex.notesController.text.trim().isEmpty ? null : ex.notesController.text.trim()),
        );
      }).toList();

      final repo = ref.read(trackRepositoryProvider);
      if (widget.workoutToEdit != null) {
        await repo.updateWorkout(
          id: widget.workoutToEdit!.id,
          name: _nameController.text,
          date: _date,
          duration: duration,
          notes: _notesController.text,
          exercises: exerciseCompanions,
        );
      } else {
        await repo.logWorkout(
          name: _nameController.text,
          date: _date,
          duration: duration,
          notes: _notesController.text,
          exercises: exerciseCompanions,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving workout: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.workoutToEdit != null;

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
                      isEditing ? 'Edit Workout' : 'Log Workout Session',
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
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Workout Name *',
                          hintText: 'e.g. Push - Chest & Triceps, Leg Day, Pull Day',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Workout name is required' : null,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 8),

                      // Quick preset tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Push Day',
                            'Pull Day',
                            'Legs & Core',
                            'Upper Body',
                            'Full Body',
                            'Cardio & Core',
                          ].map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(tag, style: const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() => _nameController.text = tag),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(DateFormatter.formatDate(_date)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(const Duration(days: 7)),
                                );
                                if (picked != null) setState(() => _date = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (mins)',
                                suffixText: 'm',
                                prefixIcon: Icon(Icons.timer_outlined, size: 20),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Exercises Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXERCISES (${_exercises.length})',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Exercise'),
                            onPressed: _addExercise,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Exercises List
                      if (_exercises.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('No exercises added yet. Tap "Add Exercise" above.'),
                          ),
                        )
                      else
                        ..._exercises.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ex = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      child: Text('${idx + 1}', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: ex.nameController,
                                        decoration: const InputDecoration(
                                          hintText: 'Exercise Name (e.g. Squat)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () => _removeExercise(idx),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: ex.setsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Sets',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: ex.repsController,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: ex.weightController,
                                        decoration: const InputDecoration(
                                          labelText: 'Weight (kg)',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Session Notes / Fatigue / PRs (Optional)',
                          hintText: 'Felt strong on bench press, increased squat by 2.5kg...',
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
                          : Text(isEditing ? 'Save Workout' : 'Log Workout'),
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
