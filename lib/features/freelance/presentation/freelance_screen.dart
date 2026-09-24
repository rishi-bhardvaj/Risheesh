import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../work/presentation/add_edit_project_dialog.dart';
import '../providers/freelance_providers.dart';
import 'add_edit_client_dialog.dart';
import 'add_edit_lead_dialog.dart';
import 'add_edit_payment_dialog.dart';
import 'client_details_screen.dart';
import 'convert_lead_dialog.dart';
import 'lead_details_screen.dart';

class FreelanceScreen extends ConsumerStatefulWidget {
  const FreelanceScreen({super.key});

  @override
  ConsumerState<FreelanceScreen> createState() => _FreelanceScreenState();
}

class _FreelanceScreenState extends ConsumerState<FreelanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _leadSearchCtrl = TextEditingController();
  final TextEditingController _clientSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _leadSearchCtrl.dispose();
    _clientSearchCtrl.dispose();
    super.dispose();
  }

  void _showLeadFilterSheet(BuildContext context) {
    final currentFilter = ref.read(leadFilterProvider);
    var filterState = currentFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Opportunities',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(leadFilterProvider.notifier).state = const LeadFilterState();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Platform Filter
                  const Text('Platform / Source', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['all', ...AppConstants.freelancePlatforms].map((plat) {
                      final isSelected = (plat == 'all' && filterState.platform == 'all') ||
                          filterState.platform.toLowerCase() == plat.toLowerCase();
                      return ChoiceChip(
                        label: Text(plat == 'all' ? 'All Sources' : plat),
                        selected: isSelected,
                        onSelected: (sel) {
                          setSheetState(() {
                            filterState = filterState.copyWith(platform: sel ? plat : 'all');
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Has Budget Toggle
                  CheckboxListTile(
                    title: const Text('With Specified Budget Only'),
                    value: filterState.hasBudget,
                    onChanged: (val) {
                      setSheetState(() {
                        filterState = filterState.copyWith(hasBudget: val ?? false);
                      });
                    },
                  ),

                  // Follow-up Due Only
                  CheckboxListTile(
                    title: const Text('Follow-up Due or Overdue Only'),
                    value: filterState.followUpDueOnly,
                    onChanged: (val) {
                      setSheetState(() {
                        filterState = filterState.copyWith(followUpDueOnly: val ?? false);
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(leadFilterProvider.notifier).state = filterState;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(freelanceSnapshotProvider);
    final followUpsDue = ref.watch(leadsFollowUpDueTodayProvider);
    final followUpsOverdue = ref.watch(leadsFollowUpOverdueProvider);
    final totalFollowUps = followUpsDue.length + followUpsOverdue.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freelance CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 18),
                  const SizedBox(width: 6),
                  const Text('Opportunities'),
                  if (snapshot.activeLeads > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${snapshot.activeLeads}', Colors.blue),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Clients'),
                  if (snapshot.totalClients > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${snapshot.totalClients}', Colors.indigo),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Projects'),
                  if (snapshot.activeProjects > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('${snapshot.activeProjects}', Colors.teal),
                  ],
                ],
              ),
            ),
            const Tab(
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Revenue'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.alarm_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  const Text('Follow-ups'),
                  if (totalFollowUps > 0) ...[
                    const SizedBox(width: 6),
                    _buildBadge('$totalFollowUps', followUpsOverdue.isNotEmpty ? Colors.redAccent : Colors.orange),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsTab(context),
          _buildClientsTab(context),
          _buildProjectsTab(context),
          _buildRevenueTab(context),
          _buildFollowUpsTab(context),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget? _buildFab(BuildContext context) {
    switch (_tabController.index) {
      case 0:
      case 4:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditLeadDialog(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Lead'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditClientDialog(),
            );
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Client'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditProjectDialog(),
            );
          },
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('New Project'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddEditPaymentDialog(),
            );
          },
          icon: const Icon(Icons.add_card),
          label: const Text('Record Payment'),
        );
      default:
        return null;
    }
  }

  // --- TAB 1: OPPORTUNITIES / LEADS ---
  Widget _buildLeadsTab(BuildContext context) {
    final theme = Theme.of(context);
    final leads = ref.watch(filteredLeadsProvider);
    final filter = ref.watch(leadFilterProvider);
    final currentSort = ref.watch(leadSortOptionProvider);

    return Column(
      children: [
        // Search & Filter & Sort Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _leadSearchCtrl,
                  leading: const Icon(Icons.search),
                  hintText: 'Search title, client, skills, platform...',
                  trailing: _leadSearchCtrl.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _leadSearchCtrl.clear();
                              ref.read(leadSearchQueryProvider.notifier).state = '';
                            },
                          ),
                        ]
                      : null,
                  onChanged: (val) {
                    ref.read(leadSearchQueryProvider.notifier).state = val;
                  },
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: Badge(
                  isLabelVisible: filter.hasActiveFilters,
                  child: const Icon(Icons.filter_list),
                ),
                tooltip: 'Filter Leads',
                onPressed: () => _showLeadFilterSheet(context),
              ),
              PopupMenuButton<LeadSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Leads',
                initialValue: currentSort,
                onSelected: (s) => ref.read(leadSortOptionProvider.notifier).state = s,
                itemBuilder: (ctx) => LeadSortOption.values
                    .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                    .toList(),
              ),
            ],
          ),
        ),

        // Pipeline Status Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Stages'),
                selected: filter.status == 'all',
                onSelected: (sel) {
                  if (sel) ref.read(leadFilterProvider.notifier).state = filter.copyWith(status: 'all');
                },
              ),
              const SizedBox(width: 6),
              ...LeadStatus.values.map((s) {
                final isSelected = filter.status.toUpperCase() == s.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: isSelected,
                    onSelected: (sel) {
                      ref.read(leadFilterProvider.notifier).state = filter.copyWith(status: sel ? s.value : 'all');
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        // Leads List
        Expanded(
          child: leads.isEmpty
              ? EmptyStateView(
                  icon: Icons.work_history_outlined,
                  title: 'No Freelance Leads',
                  message: 'Track client opportunities, proposals, negotiation terms, and won projects.',
                  actionLabel: 'Add First Lead',
                  onAction: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddEditLeadDialog(),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: leads.length,
                  itemBuilder: (ctx, index) {
                    final lead = leads[index];
                    final leadStatus = LeadStatus.fromString(lead.status);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: leadStatus == LeadStatus.won
                              ? Colors.green.withOpacity(0.5)
                              : theme.colorScheme.outlineVariant,
                          width: leadStatus == LeadStatus.won ? 1.5 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LeadDetailsScreen(lead: lead)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (lead.clientName != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            lead.clientName!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  _buildLeadStageBadge(leadStatus),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Info Chips (Platform, Budget, Follow-up)
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (lead.platform != null)
                                    _buildSmallTag(lead.platform!, Icons.public, theme),
                                  if (lead.budget != null)
                                    _buildSmallTag('${lead.currency} ${lead.budget!.toStringAsFixed(0)}', Icons.payments_outlined, theme),
                                  if (lead.followUpDate != null)
                                    _buildSmallTag(
                                      'Follow-up: ${DateFormatter.formatDate(lead.followUpDate!)}',
                                      Icons.alarm,
                                      theme,
                                      isAlert: _isOverdue(lead.followUpDate!),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 6),

                              // Actions Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormatter.formatRelative(lead.createdAt),
                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                                  ),
                                  if (leadStatus == LeadStatus.won || lead.clientId == null)
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => ConvertLeadDialog(lead: lead),
                                        );
                                      },
                                      icon: const Icon(Icons.verified, size: 16, color: Colors.green),
                                      label: const Text('Convert to Client', style: TextStyle(color: Colors.green)),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => LeadDetailsScreen(lead: lead)),
                                        );
                                      },
                                      icon: const Icon(Icons.arrow_forward, size: 16),
                                      label: const Text('Details'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: CLIENTS CRM ---
  Widget _buildClientsTab(BuildContext context) {
    final theme = Theme.of(context);
    final clients = ref.watch(filteredClientsProvider);
    final statusFilter = ref.watch(clientStatusFilterProvider);
    final currentSort = ref.watch(clientSortOptionProvider);

    return Column(
      children: [
        // Search & Sort Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  controller: _clientSearchCtrl,
                  leading: const Icon(Icons.search),
                  hintText: 'Search client name, contact, email...',
                  trailing: _clientSearchCtrl.text.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _clientSearchCtrl.clear();
                              ref.read(clientSearchQueryProvider.notifier).state = '';
                            },
                          ),
                        ]
                      : null,
                  onChanged: (val) {
                    ref.read(clientSearchQueryProvider.notifier).state = val;
                  },
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<ClientSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Clients',
                initialValue: currentSort,
                onSelected: (s) => ref.read(clientSortOptionProvider.notifier).state = s,
                itemBuilder: (ctx) => ClientSortOption.values
                    .map((opt) => PopupMenuItem(value: opt, child: Text(opt.label)))
                    .toList(),
              ),
            ],
          ),
        ),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Clients'),
                selected: statusFilter == 'all',
                onSelected: (sel) {
                  if (sel) ref.read(clientStatusFilterProvider.notifier).state = 'all';
                },
              ),
              const SizedBox(width: 6),
              ...ClientStatus.values.map((s) {
                final isSelected = statusFilter.toUpperCase() == s.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: isSelected,
                    onSelected: (sel) {
                      ref.read(clientStatusFilterProvider.notifier).state = sel ? s.value : 'all';
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        // Clients List
        Expanded(
          child: clients.isEmpty
              ? EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'No Clients Yet',
                  message: 'Clients converted from won leads or added manually will appear here.',
                  actionLabel: 'Add Client Profile',
                  onAction: () {
                    showDialog(
                      context: context,
                      builder: (_) => const AddEditClientDialog(),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  itemCount: clients.length,
                  itemBuilder: (ctx, index) {
                    final client = clients[index];

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ClientDetailsScreen(client: client)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client.name,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (client.contactName != null) ...[
                                          Text(
                                            client.contactName!,
                                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  _buildClientStatusBadge(client.status),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Contact summary
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (client.email != null)
                                    _buildSmallTag(client.email!, Icons.email_outlined, theme),
                                  if (client.platform != null)
                                    _buildSmallTag(client.platform!, Icons.public, theme),
                                  if (client.location != null)
                                    _buildSmallTag(client.location!, Icons.location_on_outlined, theme),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 3: FREELANCE PROJECTS ---
  Widget _buildProjectsTab(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(freelanceProjectsStreamProvider);

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return EmptyStateView(
            icon: Icons.folder_open_outlined,
            title: 'No Freelance Projects',
            message: 'Active projects linked to your freelance clients and won contracts will show here.',
            actionLabel: 'Create Project',
            onAction: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditProjectDialog(),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: projects.length,
          itemBuilder: (ctx, index) {
            final proj = projects[index];

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/work/project/${proj.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              proj.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              proj.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (proj.description != null && proj.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          proj.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: proj.progress,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(proj.progress * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Footer tags
                      Wrap(
                        spacing: 8,
                        children: [
                          if (proj.deadline != null)
                            _buildSmallTag('Deadline: ${DateFormatter.formatDate(proj.deadline!)}', Icons.event_available, theme),
                          if (proj.techStack != null)
                            _buildSmallTag(proj.techStack!, Icons.code, theme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading projects: $e')),
    );
  }

  // --- TAB 4: REVENUE & PAYMENTS ---
  Widget _buildRevenueTab(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = ref.watch(freelanceSnapshotProvider);
    final payments = ref.watch(filteredPaymentsProvider);
    final statusFilter = ref.watch(paymentStatusFilterProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Revenue Summary Header Cards
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.green.withOpacity(0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          const SizedBox(width: 6),
                          Text('Received', style: TextStyle(fontSize: 12, color: Colors.green.shade900, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${snapshot.totalReceivedRevenue.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.orange.withOpacity(0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pending_actions, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 6),
                          Text('Expected', style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${snapshot.totalExpectedRevenue.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Bar & Payment List Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT RECORDS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddEditPaymentDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Payment'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Payment Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Statuses'),
                selected: statusFilter == 'all',
                onSelected: (sel) {
                  if (sel) ref.read(paymentStatusFilterProvider.notifier).state = 'all';
                },
              ),
              const SizedBox(width: 6),
              ...PaymentStatus.values.map((s) {
                final isSelected = statusFilter.toUpperCase() == s.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: isSelected,
                    onSelected: (sel) {
                      ref.read(paymentStatusFilterProvider.notifier).state = sel ? s.value : 'all';
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No payment entries recorded yet. Track expected invoices and received milestones.'),
              ),
            ),
          )
        else
          ...payments.map((p) {
            final isReceived = p.status.toUpperCase() == 'RECEIVED';

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isReceived ? Colors.green.withOpacity(0.4) : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isReceived ? Colors.green : Colors.orange).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isReceived ? Icons.check_circle : Icons.receipt_long_outlined,
                        color: isReceived ? Colors.green : Colors.orange.shade800,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.description?.isNotEmpty == true ? p.description! : 'Payment Record',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date: ${DateFormatter.formatDate(p.paymentDate)} • Status: ${p.status}',
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                          if (p.notes != null && p.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(p.notes!, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${p.currency} ${p.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isReceived ? Colors.green.shade800 : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (!isReceived)
                          TextButton(
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            onPressed: () {
                              ref.read(freelanceRepositoryProvider).markPaymentReceived(p.id);
                            },
                            child: const Text('Mark Received', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 5: FOLLOW-UPS ---
  Widget _buildFollowUpsTab(BuildContext context) {
    final theme = Theme.of(context);
    final dueToday = ref.watch(leadsFollowUpDueTodayProvider);
    final overdue = ref.watch(leadsFollowUpOverdueProvider);
    final upcoming = ref.watch(leadsUpcomingFollowUpProvider);

    if (dueToday.isEmpty && overdue.isEmpty && upcoming.isEmpty) {
      return EmptyStateView(
        icon: Icons.check_circle_outline,
        title: 'All Follow-ups Clear',
        message: 'No pending client follow-ups scheduled.',
        actionLabel: 'View All Opportunities',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        if (overdue.isNotEmpty) ...[
          _buildFollowUpHeader('OVERDUE FOLLOW-UPS', Colors.red, overdue.length),
          ...overdue.map((l) => _buildFollowUpCard(l, isOverdue: true, theme: theme)),
          const SizedBox(height: 16),
        ],
        if (dueToday.isNotEmpty) ...[
          _buildFollowUpHeader('DUE TODAY', Colors.orange.shade800, dueToday.length),
          ...dueToday.map((l) => _buildFollowUpCard(l, isToday: true, theme: theme)),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          _buildFollowUpHeader('UPCOMING FOLLOW-UPS', theme.colorScheme.primary, upcoming.length),
          ...upcoming.map((l) => _buildFollowUpCard(l, theme: theme)),
        ],
      ],
    );
  }

  Widget _buildFollowUpHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(FreelanceLead lead, {bool isOverdue = false, bool isToday = false, required ThemeData theme}) {
    final borderCol = isOverdue
        ? Colors.red.withOpacity(0.5)
        : (isToday ? Colors.orange.withOpacity(0.5) : theme.colorScheme.outlineVariant);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderCol, width: isOverdue || isToday ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  lead.followUpDate != null ? DateFormatter.formatDate(lead.followUpDate!) : '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isOverdue ? Colors.red : (isToday ? Colors.orange.shade800 : theme.hintColor),
                  ),
                ),
              ],
            ),
            if (lead.clientName != null) ...[
              const SizedBox(height: 2),
              Text(
                'Client: ${lead.clientName!}',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
              ),
            ],
            if (lead.followUpNote != null && lead.followUpNote!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${lead.followUpNote!}', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LeadDetailsScreen(lead: lead)),
                    );
                  },
                  child: const Text('Open Lead'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadStageBadge(LeadStatus status) {
    Color bg;
    Color fg;

    switch (status) {
      case LeadStatus.newLead:
        bg = Colors.blue.withOpacity(0.15);
        fg = Colors.blue.shade800;
        break;
      case LeadStatus.researching:
        bg = Colors.purple.withOpacity(0.15);
        fg = Colors.purple.shade800;
        break;
      case LeadStatus.contacted:
      case LeadStatus.replied:
        bg = Colors.teal.withOpacity(0.15);
        fg = Colors.teal.shade800;
        break;
      case LeadStatus.discussion:
        bg = Colors.indigo.withOpacity(0.15);
        fg = Colors.indigo.shade800;
        break;
      case LeadStatus.proposalSent:
      case LeadStatus.negotiation:
        bg = Colors.orange.withOpacity(0.15);
        fg = Colors.orange.shade900;
        break;
      case LeadStatus.won:
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        break;
      case LeadStatus.lost:
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildClientStatusBadge(String status) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.blue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.green.shade800 : Colors.blue.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSmallTag(String text, IconData icon, ThemeData theme, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.withOpacity(0.12) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isAlert ? Colors.red : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isAlert ? Colors.red.shade800 : theme.colorScheme.onSurfaceVariant,
              fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOverdue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }
}
