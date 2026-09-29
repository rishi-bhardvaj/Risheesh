import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/resume_storage_helper.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../career/domain/resume_profile_models.dart';
import '../../career/presentation/widgets/paste_resume_dialog.dart';
import '../../career/services/resume_ingest_service.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentRoleController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _preferredRolesController = TextEditingController();
  final _preferredLocationsController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  final _resumeId = const Uuid().v4();
  String _remotePreference = 'any';
  bool _isLoading = false;
  bool _parsing = false;
  String? _parseError;
  String? _resumeFileName;
  String? _resumeFilePath;
  ResumeProfile? _parsed;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _currentRoleController,
      _experienceController,
      _skillsController,
      _preferredRolesController,
      _preferredLocationsController,
      _expectedSalaryController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final file = await ResumeStorageHelper.pickAndSaveResume();
      if (file == null) return;
      setState(() {
        _resumeFileName = file.fileName;
        _resumeFilePath = file.localPath;
        _parsing = true;
        _parseError = null;
      });
      final result = await ResumeIngestService.fromFile(file.localPath, resumeId: _resumeId, resumeName: file.fileName);
      _applyParsed(result.profile);
    } catch (e) {
      if (mounted) setState(() => _parseError = e.toString());
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  Future<void> _pasteResume() async {
    final text = await showPasteResumeDialog(context);
    if (text == null || !mounted) return;
    setState(() {
      _parsing = true;
      _parseError = null;
    });
    try {
      final result = ResumeIngestService.fromText(text, resumeId: _resumeId, resumeName: 'Pasted resume');
      final file = await ResumeStorageHelper.saveTextResume(
        result.text,
        baseName: result.profile.fullName?.value.replaceAll(' ', '_') ?? 'Pasted_Resume',
      );
      _resumeFileName = file.fileName;
      _resumeFilePath = file.localPath;
      _applyParsed(result.profile);
    } catch (e) {
      if (mounted) setState(() => _parseError = e.toString());
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  /// Prefills empty form fields; anything the user typed is kept.
  void _applyParsed(ResumeProfile p) {
    void fill(TextEditingController c, String? v) {
      if (v != null && v.trim().isNotEmpty && c.text.trim().isEmpty) c.text = v.trim();
    }

    fill(_nameController, p.fullName?.value);
    fill(_currentRoleController, p.targetRole?.value);
    fill(_preferredRolesController, p.targetRole?.value);
    fill(_experienceController, p.experienceYears?.value.toString());
    fill(_skillsController, p.allUniqueSkills.take(20).join(', '));
    setState(() => _parsed = p);
  }

  Future<void> _submit({bool isSkip = false}) async {
    if (!isSkip && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final name = isSkip && _nameController.text.trim().isEmpty ? 'Engineer' : _nameController.text.trim();
      await ref.read(onboardingServiceProvider).completeOnboarding(
            name: name.isEmpty ? 'Engineer' : name,
            currentRole: isSkip ? null : _currentRoleController.text,
            experienceYears: isSkip ? 0.0 : double.tryParse(_experienceController.text.trim()) ?? 0.0,
            skills: isSkip ? null : _skillsController.text,
            preferredRoles: isSkip ? null : _preferredRolesController.text,
            preferredLocations: isSkip ? null : _preferredLocationsController.text,
            remotePreference: isSkip ? 'any' : _remotePreference,
            expectedSalary: isSkip ? null : _expectedSalaryController.text,
            resumeFilePath: _resumeFilePath,
            resumeFileName: _resumeFileName,
            resumeId: _resumeId,
            parsedResume: _parsed,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const AppLogo(size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppConstants.appName,
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              Text('Personal command center',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ResumeHeroCard(
                      parsing: _parsing,
                      error: _parseError,
                      fileName: _resumeFileName,
                      parsed: _parsed,
                      onUpload: _pickResume,
                      onPaste: _pasteResume,
                    ),
                    const SizedBox(height: 24),
                    sectionLabel('PERSONAL'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your name *',
                        hintText: 'e.g. Risheesh Upadhyay',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),
                    sectionLabel('CAREER PROFILE'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _currentRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Current role',
                              hintText: 'e.g. Backend Engineer',
                              prefixIcon: Icon(Icons.work_outline, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                              labelText: 'Years exp',
                              hintText: 'e.g. 2.5',
                              prefixIcon: Icon(Icons.timer_outlined, size: 20),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _skillsController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Primary skills',
                        hintText: 'e.g. Java, Spring Boot, Flutter, SQL, Docker',
                        prefixIcon: Icon(Icons.code_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _preferredRolesController,
                      decoration: const InputDecoration(
                        labelText: 'Target roles',
                        hintText: 'e.g. Senior Backend Dev, Full Stack Dev',
                        prefixIcon: Icon(Icons.military_tech_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _preferredLocationsController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred locations',
                        hintText: 'e.g. Bengaluru, Hyderabad, Remote',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _remotePreference,
                      decoration: const InputDecoration(
                        labelText: 'Work mode',
                        prefixIcon: Icon(Icons.laptop_chromebook, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'any', child: Text('Flexible / any')),
                        DropdownMenuItem(value: 'remote', child: Text('Remote only')),
                        DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                        DropdownMenuItem(value: 'onsite', child: Text('On-site')),
                      ],
                      onChanged: (val) => val != null ? setState(() => _remotePreference = val) : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _expectedSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Expected compensation',
                        hintText: 'e.g. ₹25-30 LPA or 120k',
                        prefixIcon: Icon(Icons.payments_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading || _parsing ? null : () => _submit(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Complete setup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading ? null : () => _submit(isSkip: true),
                      child: Text('Skip for now', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeHeroCard extends StatelessWidget {
  final bool parsing;
  final String? error;
  final String? fileName;
  final ResumeProfile? parsed;
  final VoidCallback onUpload;
  final VoidCallback onPaste;

  const _ResumeHeroCard({
    required this.parsing,
    required this.error,
    required this.fileName,
    required this.parsed,
    required this.onUpload,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = parsed;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary.withValues(alpha: 0.18), theme.colorScheme.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start with your resume', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Upload a PDF, DOCX or TXT, or paste the text. It’s read on your phone and fills in the form below. Nothing is uploaded.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: parsing ? null : onUpload,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(fileName == null ? 'Upload resume' : 'Replace file'),
              ),
              OutlinedButton.icon(
                onPressed: parsing ? null : onPaste,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Paste text'),
              ),
            ],
          ),
          if (parsing) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text('Reading ${fileName ?? 'resume'}…', style: theme.textTheme.bodySmall),
          ] else if (error != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error))),
              ],
            ),
          ] else if (p != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName == null ? 'Resume parsed' : 'Parsed $fileName',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (p.fullName != null) _pill(context, Icons.person_outline, p.fullName!.value),
                if (p.email != null) _pill(context, Icons.mail_outline, p.email!.value),
                if (p.experienceYears != null) _pill(context, Icons.timeline, '${p.experienceYears!.value} yrs'),
                _pill(context, Icons.build_outlined, '${p.allUniqueSkills.length} skills'),
                if (p.experience.isNotEmpty) _pill(context, Icons.work_history_outlined, '${p.experience.length} roles'),
                if (p.educationEntries.isNotEmpty) _pill(context, Icons.school_outlined, 'Education'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium)),
        ],
      ),
    );
  }
}
