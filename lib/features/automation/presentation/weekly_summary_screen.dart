import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../ai/data/ollama_provider.dart';
import '../../ai/domain/ai_models.dart';
import '../../ai/providers/ai_config_provider.dart';
import '../domain/automation_models.dart';
import '../domain/weekly_summary_aggregator.dart';

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  WeeklySummaryData? _summary;
  bool _isLoading = true;
  String? _aiSynthesis;
  bool _isSynthesizing = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final aggregator = WeeklySummaryAggregator(db);
    final data = await aggregator.aggregate();
    setState(() {
      _summary = data;
      _isLoading = false;
    });
  }

  Future<void> _synthesizeWithAi() async {
    if (_summary == null) return;
    setState(() => _isSynthesizing = true);

    try {
      final config = ref.read(ollamaConfigProvider);
      final provider = OllamaProvider();

      const systemPrompt = 'You are the AI Executive Copilot for Career OS. Provide a concise, professional executive standup briefing summarizing accomplishments and next priorities.';
      final prompt = '''
Given this factual weekly summary of my progress across all life and career modules, generate a concise, motivational, executive standup debrief (3-4 paragraphs) highlighting achievements, bottlenecks, and the top 2 priorities for next week.

FACTUAL DATA:
${_summary!.toMarkdownReport()}
''';

      final responseBuffer = StringBuffer();
      await for (final chunk in provider.streamChatResponse(
        config: config,
        systemPrompt: systemPrompt,
        messages: [
          AIMessageInput(role: 'user', content: prompt),
        ],
      )) {
        responseBuffer.write(chunk);
        setState(() {
          _aiSynthesis = responseBuffer.toString();
        });
      }
    } catch (e) {
      setState(() {
        _aiSynthesis = 'AI Synthesis unavailable: Could not connect to local Ollama instance ($e).';
      });
    } finally {
      setState(() => _isSynthesizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Progress Digest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('No data found for this week'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    Card(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.assessment, color: theme.colorScheme.primary, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Past 7 Days Overview',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Compiled automatically from your real on-device SQLite database across all 7 modules.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Module Grid Cards
                    _buildSectionHeader('CAREER & JOBS', theme),
                    _buildMetricRow([
                      _MetricItem('Jobs Discovered', '${_summary!.jobsDiscovered}', Icons.work_outline, Colors.blue),
                      _MetricItem('Apps Submitted', '${_summary!.applicationsSubmitted}', Icons.send, Colors.indigo),
                      _MetricItem('Follow-ups Met', '${_summary!.followUpsCompleted}', Icons.check_circle_outline, Colors.green),
                    ], theme),
                    const SizedBox(height: 16),

                    _buildSectionHeader('WORK & STANDUPS', theme),
                    _buildMetricRow([
                      _MetricItem('Tasks Completed', '${_summary!.tasksCompleted}', Icons.task_alt, Colors.teal),
                      _MetricItem('Tasks Pending', '${_summary!.tasksPending}', Icons.pending_actions, Colors.amber),
                      _MetricItem('EODs Logged', '${_summary!.eodNotesLogged}/7', Icons.edit_note, Colors.deepOrange),
                    ], theme),
                    const SizedBox(height: 16),

                    _buildSectionHeader('DSA & LEARNING', theme),
                    _buildMetricRow([
                      _MetricItem('DSA Solved', '${_summary!.dsaProblemsSolved}', Icons.psychology, Colors.purple),
                      _MetricItem('DSA Attempts', '${_summary!.dsaProblemsAttempted}', Icons.repeat, Colors.deepPurple),
                      _MetricItem('Skills Practiced', '${_summary!.skillsPracticed}', Icons.code, Colors.cyan),
                    ], theme),
                    const SizedBox(height: 16),

                    _buildSectionHeader('FITNESS & FINANCE', theme),
                    _buildMetricRow([
                      _MetricItem('Workouts', '${_summary!.workoutsLogged}', Icons.fitness_center, Colors.orange),
                      _MetricItem('Income', '\$${_summary!.totalIncome.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green),
                      _MetricItem('Expenses', '\$${_summary!.totalExpense.toStringAsFixed(0)}', Icons.arrow_downward, Colors.red),
                    ], theme),
                    const SizedBox(height: 16),

                    // AI Synthesis Section
                    _buildSectionHeader('AI EXECUTIVE SYNTHESIS', theme),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.smart_toy_outlined, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text('Ollama AI Standup Synthesis',
                                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                if (_isSynthesizing)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_aiSynthesis != null)
                              Text(_aiSynthesis!, style: theme.textTheme.bodyMedium)
                            else
                              Text(
                                'Generate an executive debrief summarizing accomplishments, velocity, and next week focus areas.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: Text(_aiSynthesis == null ? 'Synthesize with AI' : 'Regenerate Briefing'),
                              onPressed: _isSynthesizing ? null : _synthesizeWithAi,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMetricRow(List<_MetricItem> items, ThemeData theme) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Icon(item.icon, color: item.color, size: 24),
                        const SizedBox(height: 6),
                        Text(item.value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(item.label,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _MetricItem(this.label, this.value, this.icon, this.color);
}
