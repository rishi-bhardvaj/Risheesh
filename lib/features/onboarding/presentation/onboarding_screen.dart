import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/resume_storage_helper.dart';
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
  String _remotePreference = 'any';
  bool _isLoading = false;
  String? _resumeFileName;
  String? _resumeFilePath;
  bool _hasResumedUpload = false;

  @override
  void dispose() {
    _nameController.dispose();
    _currentRoleController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _preferredRolesController.dispose();
    _preferredLocationsController.dispose();
    _expectedSalaryController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await ResumeStorageHelper.pickAndSaveResume();
      if (result == null) return;
      setState(() {
        _resumeFileName = result.fileName;
        _resumeFilePath = result.localPath;
        _hasResumedUpload = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick resume: $e')),
        );
      }
    }
  }

  Future<void> _submit({bool isSkip = false}) async {
    if (!isSkip && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final name = isSkip || _nameController.text.trim().isEmpty ? 'Engineer' : _nameController.text.trim();
      final exp = double.tryParse(_experienceController.text.trim()) ?? 0.0;
      await ref.read(onboardingServiceProvider).completeOnboarding(
            name: name,
            currentRole: isSkip ? null : _currentRoleController.text,
            experienceYears: isSkip ? 0.0 : exp,
            skills: isSkip ? null : _skillsController.text,
            preferredRoles: isSkip ? null : _preferredRolesController.text,
            preferredLocations: isSkip ? null : _preferredLocationsController.text,
            remotePreference: isSkip ? 'any' : _remotePreference,
            expectedSalary: isSkip ? null : _expectedSalaryController.text,
            resumeFilePath: _hasResumedUpload ? _resumeFilePath : null,
            resumeFileName: _resumeFileName,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.terminal,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Career OS',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Personal Command Center',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Let’s set up your profile',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in your baseline information. You can skip optional fields and edit everything anytime in Settings.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Resume Upload Section
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickResume,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.upload_file,
                                size: 28,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upload Resume',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Select PDF or DOCX file to auto-populate your profile',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_hasResumedUpload && _resumeFileName != null)
                                Flexible(
                                  child: Text(
                                    _resumeFileName!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                Text(
                                  'No file selected',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'PERSONAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        hintText: 'e.g. Risheesh Upadhyay',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CAREER PROFILE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _currentRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Current Role',
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
                              labelText: 'Years Exp',
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
                      decoration: const InputDecoration(
                        labelText: 'Primary Skills',
                        hintText: 'e.g. Java, Spring Boot, Flutter, SQL, Docker',
                        prefixIcon: Icon(Icons.code_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _preferredRolesController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Target Roles',
                        hintText: 'e.g. Senior Backend Dev, Full Stack Dev',
                        prefixIcon: Icon(Icons.military_tech_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _preferredLocationsController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Locations',
                        hintText: 'e.g. Bengaluru, Hyderabad, Remote',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _remotePreference,
                      decoration: const InputDecoration(
                        labelText: 'Work Mode Preference',
                        prefixIcon: Icon(Icons.laptop_chromebook, size: 20),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'any', child: Text('Flexible / Any')),
                        DropdownMenuItem(value: 'remote', child: Text('Remote Only')),
                        DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                        DropdownMenuItem(value: 'onsite', child: Text('On-site')),
                      ],
                      onChanged: (val) => val != null ? setState(() => _remotePreference = val) : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _expectedSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Compensation / Target',
                        hintText: 'e.g. ₹25-30 LPA or 120k',
                        prefixIcon: Icon(Icons.currency_rupee, size: 20),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isLoading ? null : () => _submit(isSkip: false),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Complete Setup & Launch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : () => _submit(isSkip: true),
                      child: Text('Skip for now (Set defaults)', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ),
                    const SizedBox(height: 16),
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