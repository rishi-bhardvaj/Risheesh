import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/track_providers.dart';

const _habitIcons = <String, IconData>{
  'check': Icons.check_circle_outline_rounded,
  'code': Icons.code_rounded,
  'book': Icons.menu_book_rounded,
  'fitness': Icons.fitness_center_rounded,
  'water': Icons.water_drop_outlined,
  'sleep': Icons.bedtime_outlined,
  'walk': Icons.directions_walk_rounded,
  'meditate': Icons.self_improvement_rounded,
};

const _habitColors = <int>[0xFF6366F1, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444, 0xFF38BDF8, 0xFFA855F7];

/// Daily habits with a 7-day check strip and current streak.
class HabitsTab extends ConsumerWidget {
  const HabitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider);
    final doneDays = ref.watch(habitDoneDaysProvider);
    final today = dayKey(DateTime.now());
    final week = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habit-add',
        onPressed: () => _showAddHabit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New habit'),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load habits: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return _EmptyHabits(onAdd: () => _showAddHabit(context, ref));
          }
          final doneToday = habits.where((h) => doneDays[h.id]?.contains(today) ?? false).length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: habits.isEmpty ? 0 : doneToday / habits.length,
                            strokeWidth: 6,
                            color: AppTheme.success,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$doneToday of ${habits.length} done today',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(DateFormat('EEEE, d MMMM').format(today),
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, i) => _HabitCard(
                    habit: habits[i],
                    week: week,
                    done: doneDays[habits[i].id] ?? const {},
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _showAddHabit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String, int)>(context: context, builder: (_) => const _AddHabitDialog());
    if (result != null) {
      await ref.read(habitRepositoryProvider).addHabit(result.$1, icon: result.$2, colorValue: result.$3);
    }
  }
}

class _AddHabitDialog extends StatefulWidget {
  const _AddHabitDialog();

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _controller = TextEditingController();
  var _icon = 'check';
  var _color = _habitColors.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name, _icon, _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Solve 2 LeetCode problems'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                for (final e in _habitIcons.entries)
                  IconButton(
                    tooltip: e.key,
                    style: IconButton.styleFrom(
                      backgroundColor: _icon == e.key ? Color(_color).withValues(alpha: 0.18) : null,
                    ),
                    icon: Icon(e.value, color: _icon == e.key ? Color(_color) : null),
                    onPressed: () => setState(() => _icon = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _habitColors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: c == _color ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final List<DateTime> week;
  final Set<DateTime> done;

  const _HabitCard({required this.habit, required this.week, required this.done});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(habit.colorValue);
    final today = week.last;
    final doneToday = done.contains(today);
    final streak = habitStreak(done);
    final repo = ref.read(habitRepositoryProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(_habitIcons[habit.icon] ?? Icons.check_circle_outline_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        streak == 0 ? 'No streak yet' : '🔥 $streak-day streak',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: doneToday ? 'Mark not done' : 'Mark done today',
                  style: IconButton.styleFrom(
                    backgroundColor: doneToday ? color : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: doneToday ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  ),
                  icon: Icon(doneToday ? Icons.check_rounded : Icons.radio_button_unchecked_rounded),
                  onPressed: () => repo.setDone(habit.id, today, !doneToday),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More',
                  onSelected: (v) async {
                    if (v != 'delete') return;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete habit?'),
                        content: Text('“${habit.name}” and its history will be removed.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok == true) await repo.deleteHabit(habit.id);
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => repo.setDone(habit.id, day, !done.contains(day)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            Text(DateFormat('E').format(day).substring(0, 1),
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done.contains(day) ? color : Colors.transparent,
                                border: Border.all(
                                  color: done.contains(day) ? color : theme.colorScheme.outline,
                                  width: day == today ? 2 : 1,
                                ),
                              ),
                              child: done.contains(day) ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyHabits({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Build daily habits', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Track small daily wins like LeetCode practice, reading or workouts, and keep your streaks alive.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add your first habit')),
          ],
        ),
      ),
    );
  }
}
