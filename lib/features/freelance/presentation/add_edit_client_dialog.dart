import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/freelance_providers.dart';

class AddEditClientDialog extends ConsumerStatefulWidget {
  final Client? clientToEdit;
  final String? initialName;
  final String? initialContactName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialPlatform;
  final String? initialNotes;

  const AddEditClientDialog({
    super.key,
    this.clientToEdit,
    this.initialName,
    this.initialContactName,
    this.initialEmail,
    this.initialPhone,
    this.initialPlatform,
    this.initialNotes,
  });

  @override
  ConsumerState<AddEditClientDialog> createState() => _AddEditClientDialogState();
}

class _AddEditClientDialogState extends ConsumerState<AddEditClientDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _contactNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  String _platform = 'Direct';
  String _status = 'ACTIVE';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.clientToEdit;
    _nameController = TextEditingController(text: c?.name ?? widget.initialName ?? '');
    _contactNameController = TextEditingController(text: c?.contactName ?? widget.initialContactName ?? '');
    _emailController = TextEditingController(text: c?.email ?? widget.initialEmail ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? widget.initialPhone ?? '');
    _locationController = TextEditingController(text: c?.location ?? '');
    _notesController = TextEditingController(text: c?.notes ?? widget.initialNotes ?? '');

    if (c != null) {
      if (c.platform != null && AppConstants.freelancePlatforms.contains(c.platform)) {
        _platform = c.platform!;
      }
      _status = c.status;
    } else if (widget.initialPlatform != null && AppConstants.freelancePlatforms.contains(widget.initialPlatform)) {
      _platform = widget.initialPlatform!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(freelanceRepositoryProvider);
      final isEditing = widget.clientToEdit != null;

      if (isEditing) {
        await repo.updateClient(
          id: widget.clientToEdit!.id,
          name: _nameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          platform: _platform,
          location: _locationController.text.trim(),
          status: _status,
          notes: _notesController.text.trim(),
          createdAt: widget.clientToEdit!.createdAt,
        );
      } else {
        await repo.addClient(
          name: _nameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          platform: _platform,
          location: _locationController.text.trim(),
          status: _status,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Client updated' : 'Client created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save client: $e')),
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
    final isEditing = widget.clientToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.person_add_alt_1_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Client Profile' : 'Add Freelance Client',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                    // Client / Company Name (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Client / Company Name *',
                        hintText: 'e.g. Acme Innovations, Mark Zuckerberg',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Client name is required' : null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Contact Person & Status
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactNameController,
                            decoration: const InputDecoration(
                              labelText: 'Primary Contact Person',
                              hintText: 'e.g. Emily Watson',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.star_outline),
                              border: OutlineInputBorder(),
                            ),
                            items: ClientStatus.values
                                .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
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
                              hintText: 'client@example.com',
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
                              hintText: '+1 555-0199',
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

                    // Platform & Location
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _platform,
                            decoration: const InputDecoration(
                              labelText: 'Platform Source',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location / Timezone',
                              hintText: 'e.g. San Francisco (PST)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Client Notes & History',
                        hintText: 'Communication preferences, contracts, billing terms...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(Icons.note_alt_outlined),
                        ),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
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
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Client' : 'Save Client'),
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

