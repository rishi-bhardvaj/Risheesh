import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/freelance_providers.dart';

class ConvertLeadDialog extends ConsumerStatefulWidget {
  final FreelanceLead lead;

  const ConvertLeadDialog({super.key, required this.lead});

  @override
  ConsumerState<ConvertLeadDialog> createState() => _ConvertLeadDialogState();
}

class _ConvertLeadDialogState extends ConsumerState<ConvertLeadDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _clientNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _projectTitleController;

  String _platform = 'Direct';
  bool _createProject = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _clientNameController = TextEditingController(
      text: l.clientName?.isNotEmpty == true ? l.clientName! : l.title,
    );
    _contactPersonController = TextEditingController(text: l.contactName ?? '');
    _emailController = TextEditingController(
      text: (l.contactInfo != null && l.contactInfo!.contains('@')) ? l.contactInfo! : '',
    );
    _phoneController = TextEditingController(
      text: (l.contactInfo != null && !l.contactInfo!.contains('@')) ? l.contactInfo! : '',
    );
    _locationController = TextEditingController();
    _notesController = TextEditingController(text: l.notes ?? '');
    _projectTitleController = TextEditingController(text: l.title);

    if (l.platform != null && AppConstants.freelancePlatforms.contains(l.platform)) {
      _platform = l.platform!;
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _projectTitleController.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(freelanceRepositoryProvider);

      // 1. Create client and update lead
      final clientId = await repo.convertLeadToClient(
        lead: widget.lead,
        clientName: _clientNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        platform: _platform,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      );

      // 2. Optionally create freelance project
      if (_createProject && _projectTitleController.text.trim().isNotEmpty) {
        await repo.createFreelanceProject(
          name: _projectTitleController.text.trim(),
          description: widget.lead.description,
          clientId: clientId,
          leadId: widget.lead.id,
          progress: 0.0,
          techStack: widget.lead.skills,
          deadline: widget.lead.deadline,
          notes: widget.lead.notes,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead successfully converted to Client!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert lead: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convert Lead to Client',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mark won & transition into an active client relationship',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Client / Company Name
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Client / Company Name *',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Client name is required' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Contact Person & Platform
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactPersonController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _platform,
                            decoration: const InputDecoration(
                              labelText: 'Platform',
                              prefixIcon: Icon(Icons.public),
                              border: OutlineInputBorder(),
                            ),
                            items: AppConstants.freelancePlatforms
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _platform = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email & Phone
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone / Telegram',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location / Timezone
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Timezone',
                        hintText: 'e.g. London, UK (GMT)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Create Project Switch
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Create Active Freelance Project', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Initialize a project in your Work & Freelance dashboard'),
                              value: _createProject,
                              onChanged: (v) => setState(() => _createProject = v),
                            ),
                            if (_createProject) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _projectTitleController,
                                decoration: const InputDecoration(
                                  labelText: 'Project Name *',
                                  prefixIcon: Icon(Icons.folder_open),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (_createProject && (v == null || v.trim().isEmpty)) {
                                    return 'Project name is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Client Onboarding Notes',
                        hintText: 'Contract terms, kick-off dates, milestones...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 25),
                          child: Icon(Icons.note_alt_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: _isLoading ? null : _convert,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm & Convert to Client'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
