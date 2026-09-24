import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../providers/freelance_providers.dart';

class AddEditPaymentDialog extends ConsumerStatefulWidget {
  final FreelancePayment? paymentToEdit;
  final String? initialClientId;
  final String? initialProjectId;

  const AddEditPaymentDialog({
    super.key,
    this.paymentToEdit,
    this.initialClientId,
    this.initialProjectId,
  });

  @override
  ConsumerState<AddEditPaymentDialog> createState() => _AddEditPaymentDialogState();
}

class _AddEditPaymentDialogState extends ConsumerState<AddEditPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedProjectId;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String _currency = 'USD';
  String _status = 'EXPECTED';
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.paymentToEdit;
    _selectedClientId = p?.clientId ?? widget.initialClientId;
    _selectedProjectId = p?.projectId ?? widget.initialProjectId;
    _amountController = TextEditingController(text: p != null ? '${p.amount}' : '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');

    if (p != null) {
      if (AppConstants.currencies.contains(p.currency)) {
        _currency = p.currency;
      }
      _status = p.status;
      _paymentDate = p.paymentDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a client first.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than or equal to 0.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(freelanceRepositoryProvider);
      final isEditing = widget.paymentToEdit != null;

      if (isEditing) {
        await repo.updatePayment(
          id: widget.paymentToEdit!.id,
          clientId: _selectedClientId!,
          projectId: _selectedProjectId,
          amount: amount,
          currency: _currency,
          paymentDate: _paymentDate,
          status: _status,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: widget.paymentToEdit!.createdAt,
        );
      } else {
        await repo.addPayment(
          clientId: _selectedClientId!,
          projectId: _selectedProjectId,
          amount: amount,
          currency: _currency,
          paymentDate: _paymentDate,
          status: _status,
          description: _descriptionController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Payment updated' : 'Payment recorded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save payment: $e')),
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
    final isEditing = widget.paymentToEdit != null;
    final clientsAsync = ref.watch(allClientsStreamProvider);
    final projectsAsync = ref.watch(freelanceProjectsStreamProvider);

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
                    isEditing ? Icons.edit_note : Icons.payments_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Payment Record' : 'Record Freelance Payment',
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
                    // Client Selector (Required)
                    clientsAsync.when(
                      data: (clients) {
                        if (clients.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text('No clients found. Please create a client first.'),
                                ),
                              ],
                            ),
                          );
                        }

                        // Validate if selected client exists
                        if (_selectedClientId != null && !clients.any((c) => c.id == _selectedClientId)) {
                          _selectedClientId = null;
                        }
                        _selectedClientId ??= clients.first.id;

                        return DropdownButtonFormField<String>(
                          value: _selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Client *',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: clients
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedClientId = v);
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading clients: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Amount & Currency Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount *',
                              hintText: 'e.g. 500, 25000',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Amount is required';
                              final val = double.tryParse(v.trim());
                              if (val == null || val < 0) return 'Must be >= 0';
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            items: AppConstants.currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status & Date Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status',
                              prefixIcon: Icon(Icons.check_circle_outline),
                              border: OutlineInputBorder(),
                            ),
                            items: PaymentStatus.values
                                .map((s) => DropdownMenuItem(value: s.value, child: Text(s.label, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Payment Date',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Project Selector (Optional)
                    projectsAsync.when(
                      data: (projects) {
                        return DropdownButtonFormField<String?>(
                          value: _selectedProjectId,
                          decoration: const InputDecoration(
                            labelText: 'Linked Project (Optional)',
                            prefixIcon: Icon(Icons.folder_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None (General Client Payment)'),
                            ),
                            ...projects.map((p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(p.name, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedProjectId = v),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // Description / Milestone
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description / Milestone',
                        hintText: 'e.g. Milestone 1 - UI Screens & API integration',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Notes / Invoice Number
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Notes / Reference',
                        hintText: 'e.g. Invoice #2024-01, Wire transfer ref, Upwork Escrow',
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
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Payment' : 'Save Payment'),
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

