import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../ai/data/ollama_provider.dart';
import '../../../ai/domain/ai_models.dart';
import '../../../ai/providers/ai_config_provider.dart';
import '../../providers/career_providers.dart';

class JobAiAnalysisDialog extends ConsumerStatefulWidget {
  final Job job;

  const JobAiAnalysisDialog({super.key, required this.job});

  @override
  ConsumerState<JobAiAnalysisDialog> createState() => _JobAiAnalysisDialogState();
}

class _JobAiAnalysisDialogState extends ConsumerState<JobAiAnalysisDialog> {
  String _analysisText = '';
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _analysisText = '';
    });

    try {
      final activeResumes = ref.read(activeResumesProvider);
      final parsedProfiles = ref.read(parsedResumeProfilesProvider);
      final profile = ref.read(careerProfileProvider).valueOrNull;

      final resumeSummary = activeResumes.isNotEmpty
          ? activeResumes.map((r) {
              final p = parsedProfiles[r.id];
              return 'Resume: ${r.name} (${r.targetRole ?? "General"})\nSkills: ${p?.allUniqueSkills.join(", ") ?? r.notes ?? ""}';
            }).join('\n\n')
          : 'Candidate Profile Skills: ${profile?.skills ?? "Not specified"} | Role: ${profile?.currentRole ?? "Software Engineer"}';

      final prompt = '''
You are a career coach and technical recruiter. Perform a deep, structured analysis of this job opportunity against the candidate's resume/profile.

<candidate_context>
$resumeSummary
</candidate_context>

<job_details>
Title: ${widget.job.title}
Company: ${widget.job.company}
Location: ${widget.job.location ?? "Unknown"}
Employment Type: ${widget.job.employmentType ?? "Full-time"}
Requirements/Skills: ${widget.job.skills ?? "See description"}
Description:
${widget.job.description ?? "No description available"}
</job_details>

Please provide a concise, actionable analysis with these sections:
1. 🎯 Role Fit & Strengths (Where the candidate matches well)
2. ⚠️ Key Gaps & Missing Keywords (Specific technologies or requirements not evident in the profile)
3. 💡 High-Impact Resume Tailoring Tips (2-3 bullet point suggestions to highlight for this specific role)
4. 🎤 Probable Technical / Behavioral Interview Questions (3 focused questions candidate should prepare for)
''';

      final ollamaConfig = ref.read(ollamaConfigProvider);
      final ollamaProvider = OllamaProvider();

      await for (final token in ollamaProvider.streamChatResponse(
        config: ollamaConfig,
        systemPrompt: 'You are an expert career coach and technical recruiter helping a candidate analyze a job description against their profile.',
        messages: [
          AIMessageInput(role: 'user', content: prompt),
        ],
      )) {
        if (mounted) {
          setState(() {
            _analysisText += token;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to reach local Ollama daemon ($e). Please verify Ollama is running at 127.0.0.1:11434.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
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
                    child: Icon(Icons.psychology, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Job Description Analysis',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.job.title} • ${widget.job.company}',
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
              Expanded(
                child: _isLoading && _analysisText.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Analyzing job against active resume...',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : _error != null && _analysisText.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_off_outlined, size: 40, color: theme.colorScheme.error),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.tonalIcon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry Analysis'),
                                    onPressed: _startAnalysis,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              _analysisText,
                              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                            ),
                          ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_analysisText.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Analysis'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _analysisText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Analysis copied to clipboard!')),
                        );
                      },
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
