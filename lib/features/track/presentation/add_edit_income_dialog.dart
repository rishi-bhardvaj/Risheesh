import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/track_providers.dart';

class AddEditIncomeDialog extends ConsumerStatefulWidget {
  final Income? incomeToEdit;

  const AddEditIncomeDialog({super.key, this.incomeToEdit});

  @override
  ConsumerState<AddEditIncomeDialog> createState() => _AddEditIncomeDialogState();
}

class _AddEditIncomeDialogState extends ConsumerState<AddEditIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late final TextEditingController _notesController;

  String _category = 'Salary';
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final i = widget.incomeToEdit;
    _amountController = TextEditingController(text: i != null ? i.amount.toStringAsFixed(2) : '');
    _sourceController = TextEditingController(text: i?.source ?? '');
    _notesController = TextEditingController(text: i?.notes ?? '');
    _category = i?.category ?? 'Salary';
    _date = i?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount >= 0')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trackRepositoryProvider);
      if (widget.incomeToEdit != null) {
        await repo.updateIncome(
          id: widget.incomeToEdit!.id,
          amount: amount,
          source: _sourceController.text,
          date: _date,
          category: _category,
          notes: _notesController.text,
        );
      } else {
        await repo.addIncome(
          amount: amount,
          source: _sourceController.text,
          date: _date,
          category: _category,
          notes: _notesController.text,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving income: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.incomeToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                      isEditing ? 'Edit Income' : 'Add Income',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    hintText: 'e.g. 5000.00',
                    prefixIcon: Icon(Icons.attach_money, size: 20),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Amount is required';
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed < 0) return 'Enter a valid amount >= 0';
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Income Source *',
                    hintText: 'e.g. Acme Corp Salary, Upwork Client, Dividend',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Source is required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: incomeCategories.contains(_category) ? _category : 'Other',
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: incomeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormatter.formatDate(_date)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Tax deductible, bonus breakdown...',
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
                          : Text(isEditing ? 'Save Changes' : 'Record Income'),
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
