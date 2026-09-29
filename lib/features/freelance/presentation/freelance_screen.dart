import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_keys.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/feed_widgets.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../business/business_discovery_service.dart';
import '../business/website_inspector.dart';
import '../providers/freelance_providers.dart';
import 'add_edit_client_dialog.dart';

Color presenceColor(WebPresence p) => switch (p) {
      WebPresence.noWebsite => AppTheme.error,
      WebPresence.shopify => AppTheme.violet,
      WebPresence.needsWebsite => AppTheme.warning,
      WebPresence.hasWebsite => AppTheme.textMid,
    };

IconData presenceIcon(WebPresence p) => switch (p) {
      WebPresence.noWebsite => Icons.public_off_rounded,
      WebPresence.shopify => Icons.shopping_bag_outlined,
      WebPresence.needsWebsite => Icons.build_circle_outlined,
      WebPresence.hasWebsite => Icons.public_rounded,
    };

const leadStatuses = [
  ('NEW', 'New'),
  ('CONTACTED', 'Contacted'),
  ('PROPOSAL', 'Proposal sent'),
  ('WON', 'Won'),
  ('LOST', 'Lost'),
];

String leadStatusLabel(String s) => leadStatuses.firstWhere((e) => e.$1 == s, orElse: () => (s, s)).$2;

class FreelanceScreen extends StatelessWidget {
  const FreelanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenTitle(title: 'Freelance', subtitle: '₹1 Cr+ businesses that need a website'),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [Tab(text: 'Leads'), Tab(text: 'Pipeline'), Tab(text: 'Clients')],
              ),
              Expanded(child: TabBarView(children: [_LeadsTab(), _PipelineTab(), _ClientsTab()])),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Leads

class _LeadsTab extends ConsumerStatefulWidget {
  const _LeadsTab();

  @override
  ConsumerState<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends ConsumerState<_LeadsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(filteredBusinessLeadsProvider);
    final counts = ref.watch(businessPresenceCountsProvider);
    final presence = ref.watch(businessPresenceFilterProvider);
    final loaded = ref.watch(businessLeadsProvider).hasValue;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _FinderCard()),
        if (counts[null]! > 0) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SearchField(
                controller: _search,
                hint: 'Search name, industry, city',
                onChanged: (v) => ref.read(businessSearchProvider.notifier).state = v,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FilterPills<WebPresence?>(
              options: const [
                (null, 'All'),
                (WebPresence.noWebsite, 'No website'),
                (WebPresence.shopify, 'Shopify'),
                (WebPresence.needsWebsite, 'Needs a site'),
              ],
              counts: counts,
              selected: presence,
              onSelected: (v) => ref.read(businessPresenceFilterProvider.notifier).state = v,
            ),
          ),
        ],
        if (!loaded)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: SkeletonCard()))
        else if (leads.isEmpty)
          SliverToBoxAdapter(
            child: counts[null]! == 0
                ? const EmptyHint(
                    icon: Icons.storefront_outlined,
                    title: 'No leads yet',
                    message: 'Pick a region above and tap Find. Claude searches directories like IndiaMART and Google Maps, then every website is checked on your phone.',
                  )
                : const EmptyHint(icon: Icons.filter_alt_off_rounded, title: 'Nothing in this category', message: 'Try another filter or search.'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => BusinessLeadCard(lead: leads[i]),
            ),
          ),
      ],
    );
  }
}

class _FinderCard extends ConsumerStatefulWidget {
  const _FinderCard();

  @override
  ConsumerState<_FinderCard> createState() => _FinderCardState();
}

class _FinderCardState extends ConsumerState<_FinderCard> {
  final _industry = TextEditingController();
  final _city = TextEditingController();
  LeadRegion _region = LeadRegion.india;

  @override
  void dispose() {
    _industry.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    final result = await ref.read(businessDiscoveryProvider.notifier).discover(BusinessSearchRequest(
          region: _region,
          industry: _industry.text,
          city: _city.text,
        ));
    if (result != null && mounted) messenger.showSnackBar(SnackBar(content: Text(result.summary)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(businessDiscoveryProvider);
    final hasClaude = ref.watch(aiKeysProvider).has(AiProvider.claude);

    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Find businesses', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              SegmentedButton<LeadRegion>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: AppTheme.accent.withValues(alpha: 0.15),
                  selectedForegroundColor: AppTheme.accent,
                ),
                segments: const [
                  ButtonSegment(value: LeadRegion.india, label: Text('India')),
                  ButtonSegment(value: LeadRegion.global, label: Text('Global')),
                ],
                selected: {_region},
                onSelectionChanged: (s) => setState(() => _region = s.first),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Turnover ≥ ₹1 Cr · no website, Shopify, or a weak site', style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _industry,
                  decoration: InputDecoration(hintText: 'Industry (optional)', isDense: true, fillColor: theme.colorScheme.surfaceContainerHigh),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _city,
                  decoration: InputDecoration(hintText: 'City (optional)', isDense: true, fillColor: theme.colorScheme.surfaceContainerHigh),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Searching the web and checking each website… usually 1–3 minutes.', style: theme.textTheme.bodySmall),
          ] else if (!hasClaude)
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/ai'),
              icon: const Icon(Icons.key_rounded, size: 18),
              label: const Text('Add Claude key to search'),
            )
          else
            FilledButton.icon(
              onPressed: _find,
              icon: const Icon(Icons.travel_explore_rounded, size: 20),
              label: const Text('Find 10 businesses'),
            ),
          if (state.error != null && !state.isLoading) ...[
            const SizedBox(height: 10),
            Text(state.error!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error)),
          ],
        ],
      ),
    );
  }
}

class BusinessLeadCard extends StatelessWidget {
  final BusinessLead lead;

  const BusinessLeadCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presence = WebPresence.from(lead.webPresence);
    final place = [lead.industry, lead.city ?? lead.country].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return AppCard(
      onTap: () => context.push('/freelance/business/${lead.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialAvatar(name: lead.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(place, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatInr(lead.turnoverInr), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.success)),
                  Text('turnover', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(child: Tag(presence.label, color: presenceColor(presence), icon: presenceIcon(presence))),
              const SizedBox(width: 6),
              Tag('Need ${lead.needScore}', color: scoreColor(lead.needScore)),
              const Spacer(),
              Text(
                lead.status == 'NEW' ? DateFormatter.timeAgo(lead.discoveredAt) : leadStatusLabel(lead.status),
                style: theme.textTheme.labelMedium?.copyWith(color: lead.status == 'NEW' ? null : AppTheme.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Pipeline

class _PipelineTab extends ConsumerWidget {
  const _PipelineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(pipelineLeadsProvider);
    final status = ref.watch(pipelineStatusFilterProvider);
    final all = (ref.watch(businessLeadsProvider).valueOrNull ?? const <BusinessLead>[]).where((b) => isPipelineStatus(b.status));
    final counts = <String, int>{'ALL': all.length, for (final s in leadStatuses.skip(1)) s.$1: all.where((b) => b.status == s.$1).length};

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: FilterPills<String>(
            options: [('ALL', 'All'), ...leadStatuses.skip(1)],
            counts: counts,
            selected: status,
            onSelected: (v) => ref.read(pipelineStatusFilterProvider.notifier).state = v,
          ),
        ),
        if (leads.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyHint(
              icon: Icons.view_kanban_outlined,
              title: 'Pipeline is empty',
              message: 'Open a lead and mark it Contacted to start tracking it here.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => BusinessLeadCard(lead: leads[i]),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Clients

class _ClientsTab extends ConsumerWidget {
  const _ClientsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clients = ref.watch(allClientsStreamProvider).valueOrNull ?? const <Client>[];
    final payments = ref.watch(allPaymentsStreamProvider).valueOrNull ?? const <FreelancePayment>[];
    double received(String clientId) =>
        payments.where((p) => p.clientId == clientId && p.status == 'RECEIVED').fold(0.0, (sum, p) => sum + p.amount);
    final total = payments.where((p) => p.status == 'RECEIVED').fold(0.0, (sum, p) => sum + p.amount);
    final pending = payments.where((p) => p.status != 'RECEIVED').fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-client',
        tooltip: 'Add client',
        onPressed: () => showDialog(context: context, builder: (_) => const AddEditClientDialog()),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(child: StatTile(value: formatInr(total), label: 'Received', valueColor: AppTheme.success)),
              const SizedBox(width: 10),
              Expanded(child: StatTile(value: formatInr(pending), label: 'Pending')),
              const SizedBox(width: 10),
              Expanded(child: StatTile(value: '${clients.length}', label: 'Clients')),
            ],
          ),
          const SizedBox(height: 16),
          if (clients.isEmpty)
            const EmptyHint(
              icon: Icons.handshake_outlined,
              title: 'No clients yet',
              message: 'Mark a lead as Won to turn it into a client, or add one with +.',
            )
          else
            for (final c in clients)
              AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                onTap: () => context.push('/freelance/client/${c.id}'),
                child: Row(
                  children: [
                    InitialAvatar(name: c.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            [c.location, c.contactName].whereType<String>().join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(formatInr(received(c.id)), style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
