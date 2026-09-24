import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../work/presentation/add_edit_project_dialog.dart';
import '../providers/freelance_providers.dart';
import 'add_edit_client_dialog.dart';
import 'add_edit_lead_dialog.dart';
import 'add_edit_payment_dialog.dart';
import 'lead_details_screen.dart';

class ClientDetailsScreen extends ConsumerWidget {
  final Client? client;
  final String? clientId;

  const ClientDetailsScreen({
    super.key,
    this.client,
    this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final id = client?.id ?? clientId;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('Invalid client identifier.')));
    }

    final clientAsync = ref.watch(clientByIdProvider(id));
    final currentClient = clientAsync.valueOrNull ?? client;

    if (currentClient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client CRM')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final leadsAsync = ref.watch(clientLeadsProvider(id));
    final projectsAsync = ref.watch(clientProjectsProvider(id));
    final paymentsAsync = ref.watch(clientPaymentsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Client',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddEditClientDialog(clientToEdit: currentClient),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Client',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Client?'),
                  content: Text('Are you sure you want to delete "${currentClient.name}" and all associated records?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(freelanceRepositoryProvider).deleteClient(currentClient.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Client Info Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          currentClient.name.isNotEmpty ? currentClient.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentClient.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (currentClient.contactName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                currentClient.contactName!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(currentClient.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Contact Details
                  if (currentClient.email != null && currentClient.email!.isNotEmpty)
                    _buildContactRow(Icons.email_outlined, currentClient.email!, theme),
                  if (currentClient.phone != null && currentClient.phone!.isNotEmpty)
                    _buildContactRow(Icons.phone_outlined, currentClient.phone!, theme),
                  if (currentClient.location != null && currentClient.location!.isNotEmpty)
                    _buildContactRow(Icons.location_on_outlined, currentClient.location!, theme),
                  if (currentClient.platform != null && currentClient.platform!.isNotEmpty)
                    _buildContactRow(Icons.public, 'Platform: ${currentClient.platform!}', theme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Revenue & Payments Summary Card
          paymentsAsync.when(
            data: (payments) {
              double received = 0.0;
              double expected = 0.0;
              for (final p in payments) {
                if (p.status.toUpperCase() == 'RECEIVED') {
                  received += p.amount;
                } else if (p.status.toUpperCase() == 'EXPECTED' || p.status.toUpperCase() == 'INVOICED') {
                  expected += p.amount;
                }
              }

              return Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Revenue Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditPaymentDialog(initialClientId: currentClient.id),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Payment'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRevenueItem('Total Received', '\$${received.toStringAsFixed(0)}', Colors.green, theme),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRevenueItem('Invoiced / Expected', '\$${expected.toStringAsFixed(0)}', Colors.orange.shade800, theme),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Related Projects Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RELATED PROJECTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Create Project for Client',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditProjectDialog(
                      initialNotes: 'Client: ${currentClient.name}',
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          projectsAsync.when(
            data: (projects) {
              if (projects.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('No active projects linked to this client.'),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AddEditProjectDialog(
                                initialNotes: 'Client: ${currentClient.name}',
                              ),
                            );
                          },
                          child: const Text('Create Project'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final proj = projects[idx];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(proj.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: ${proj.status} • Progress: ${(proj.progress * 100).toInt()}%'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/work/project/${proj.id}'),
                    ),
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading projects: $e'),
          ),
          const SizedBox(height: 16),

          // Related Leads / Opportunities Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OPPORTUNITIES & LEADS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                tooltip: 'Add Lead for Client',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AddEditLeadDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          leadsAsync.when(
            data: (leads) {
              if (leads.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No freelance opportunities logged for this client.'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final lead = leads[idx];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      title: Text(lead.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Stage: ${lead.status} • ${lead.platform ?? "Direct"}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LeadDetailsScreen(lead: lead)),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading leads: $e'),
          ),
          const SizedBox(height: 16),

          // Notes Card
          if (currentClient.notes != null && currentClient.notes!.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client History & Notes', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 6),
                    Text(currentClient.notes!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        break;
      case 'PROSPECT':
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue.shade800;
        break;
      default:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.hintColor),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
