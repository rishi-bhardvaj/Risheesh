import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../providers/track_providers.dart';

const _moods = ['😞', '😕', '😐', '🙂', '😄'];

/// End-of-day reflection: mood, wins, blockers, lessons, and tomorrow's
/// focus. One entry per day; saving again updates it.
class ReflectionTab extends ConsumerStatefulWidget {
  const ReflectionTab({super.key});

  @override
  ConsumerState<ReflectionTab> createState() => _ReflectionTabState();
}

class _ReflectionTabState extends ConsumerState<ReflectionTab> {
  final _wins = TextEditingController();
  final _blockers = TextEditingController();
  final _learned = TextEditingController();
  final _tomorrow = TextEditingController();
  int _mood = 3;
  bool _saving = false;
  String? _loadedId;

  @override
  void dispose() {
    for (final c in [_wins, _blockers, _learned, _tomorrow]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the form from today's saved entry once, without clobbering edits.
  void _hydrate(DailyReflection? today) {
    if (today == null || _loadedId == today.id) return;
    _loadedId = today.id;
    _mood = today.mood;
    _wins.text = today.wins ?? '';
    _blockers.text = today.blockers ?? '';
    _learned.text = today.learned ?? '';
    _tomorrow.text = today.tomorrow ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(habitRepositoryProvider).saveReflection(
            day: DateTime.now(),
            mood: _mood,
            wins: _wins.text,
            blockers: _blockers.text,
            learned: _learned.text,
            tomorrow: _tomorrow.text,
          );
      messenger.showSnackBar(const SnackBar(content: Text('Reflection saved'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(reflectionsProvider).valueOrNull ?? const <DailyReflection>[];
    final today = dayKey(DateTime.now());
    final todayEntry = entries.where((e) => dayKey(e.day) == today).firstOrNull;
    _hydrate(todayEntry);
    final history = entries.where((e) => dayKey(e.day) != today).toList();

    Widget field(TextEditingController c, String label, String hint, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20), alignLabelWithHint: true),
          ),
        );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(DateFormat('EEEE, d MMMM').format(today),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('How did today go?', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Semantics(
                          label: 'Mood $i of 5',
                          selected: _mood == i,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => setState(() => _mood = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _mood == i ? theme.colorScheme.primary.withValues(alpha: 0.2) : null,
                                border: Border.all(color: _mood == i ? theme.colorScheme.primary : Colors.transparent, width: 2),
                              ),
                              child: Text(_moods[i - 1], style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  field(_wins, 'Wins', 'What went well?', Icons.emoji_events_outlined),
                  field(_blockers, 'Blockers', 'What slowed you down?', Icons.block_rounded),
                  field(_learned, 'Learned', 'One thing you learned', Icons.lightbulb_outline_rounded),
                  field(_tomorrow, 'Tomorrow', 'Top priority for tomorrow', Icons.flag_outlined),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: Text(todayEntry == null ? 'Save reflection' : 'Update reflection'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (history.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text('Past reflections', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverList.builder(
            itemCount: history.length,
            itemBuilder: (context, i) => _ReflectionCard(entry: history[i]),
          ),
        ),
      ],
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final DailyReflection entry;

  const _ReflectionCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <(String, String?)>[
      ('Wins', entry.wins),
      ('Blockers', entry.blockers),
      ('Learned', entry.learned),
      ('Tomorrow', entry.tomorrow),
    ].where((p) => p.$2 != null && p.$2!.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        shape: const Border(),
        leading: Text(_moods[(entry.mood - 1).clamp(0, 4)], style: const TextStyle(fontSize: 24)),
        title: Text(DateFormat('EEE, d MMM').format(entry.day), style: theme.textTheme.titleSmall),
        subtitle: parts.isEmpty
            ? null
            : Text(parts.first.$2!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in parts) ...[
            Text(p.$1, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(p.$2!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
