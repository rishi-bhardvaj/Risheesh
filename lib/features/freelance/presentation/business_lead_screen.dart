import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/ai_service.dart';
import '../../../core/ai/document_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/url_helper.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../career/providers/career_providers.dart';
import '../business/business_discovery_service.dart';
import '../business/website_inspector.dart';
import '../providers/freelance_providers.dart';
import 'freelance_screen.dart';

String _leadContext(BusinessLead l) => [
      'Business: ${l.name}',
      if (l.industry != null) 'Industry: ${l.industry}',
      'Location: ${[l.city, l.country].whereType<String>().join(', ')}',
      'Estimated annual turnover: ${formatInr(l.turnoverInr)} (${l.turnoverEvidence ?? 'no detail'})',
      'Web presence: ${WebPresence.from(l.webPresence).label}. Findings: ${(l.presenceNotes ?? '').replaceAll('\n', '; ')}',
      if (l.websiteUrl != null) 'Current site: ${l.websiteUrl}',
      if (l.pitch != null) 'Opportunity: ${l.pitch}',
    ].join('\n');

String _senderContext(UserProfile? p) => p == null
    ? 'Sender: an independent web developer.'
    : 'Sender: ${p.name}, ${p.currentRole ?? 'independent developer'}. Skills: ${p.skills ?? 'web & mobile development'}.';

class BusinessLeadScreen extends ConsumerWidget {
  final String leadId;

  const BusinessLeadScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lead = ref.watch(businessLeadByIdProvider(leadId)).valueOrNull;
    if (lead == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final presence = WebPresence.from(lead.webPresence);
    final links = _decodeList(lead.linksJson, 'label');
    final sources = _decodeList(lead.sourcesJson, 'title');
    final digits = (lead.phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v != 'delete') return;
              await ref.read(databaseProvider).deleteBusinessLead(lead.id);
              if (context.mounted) context.pop();
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete lead'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              InitialAvatar(name: lead.name, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lead.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      [lead.industry, lead.city, lead.country].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatInr(lead.turnoverInr), style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.success)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('est. yearly turnover', style: theme.textTheme.bodySmall)),
              const Spacer(),
              Tag('Need ${lead.needScore}/100', color: scoreColor(lead.needScore)),
            ],
          ),
          if (lead.turnoverEvidence != null) ...[
            const SizedBox(height: 6),
            Text(lead.turnoverEvidence!, style: theme.textTheme.bodySmall),
            if (lead.turnoverSourceUrl != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                  onPressed: () => UrlHelper.launchURL(context, lead.turnoverSourceUrl),
                  child: const Text('View source'),
                ),
              ),
          ],
          const SizedBox(height: 16),
          _ContactRow(lead: lead, digits: digits),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(presence.label, color: presenceColor(presence), icon: presenceIcon(presence)),
                const SizedBox(height: 10),
                for (final note in (lead.presenceNotes ?? '').split('\n').where((n) => n.trim().isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: const EdgeInsets.only(top: 7, right: 8), child: Icon(Icons.circle, size: 5, color: theme.colorScheme.onSurfaceVariant)),
                        Expanded(child: Text(note, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                if (lead.websiteUrl != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => UrlHelper.launchURL(context, lead.websiteUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(Uri.tryParse(lead.websiteUrl!)?.host ?? lead.websiteUrl!),
                  ),
              ],
            ),
          ),
          if (lead.pitch != null && lead.pitch!.isNotEmpty) ...[
            const SectionHeader(title: 'Why they need you', padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
            Text(lead.pitch!, style: theme.textTheme.bodyMedium),
          ],
          const SectionHeader(title: 'Status', padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in leadStatuses)
                ChoiceChip(
                  label: Text(label),
                  selected: lead.status == value,
                  onSelected: (_) => ref.read(databaseProvider).updateBusinessLeadStatus(lead.id, value),
                ),
            ],
          ),
          if (lead.status == 'WON') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final id = await ref.read(freelanceRepositoryProvider).addClient(
                      name: lead.name,
                      email: lead.email,
                      phone: lead.phone,
                      location: [lead.city, lead.country].whereType<String>().join(', '),
                      platform: 'Lead finder',
                      notes: lead.pitch,
                    );
                if (context.mounted) context.push('/freelance/client/$id');
              },
              icon: const Icon(Icons.person_add_alt_rounded, size: 18),
              label: const Text('Add as client'),
            ),
          ],
          const SectionHeader(title: 'AI actions', padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
          _AiActions(lead: lead),
          if (links.isNotEmpty) ...[
            const SectionHeader(title: 'Online presence', padding: EdgeInsets.fromLTRB(0, 20, 0, 6)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in links)
                  ActionChip(
                    avatar: const Icon(Icons.link_rounded, size: 16),
                    label: Text(l.$1),
                    onPressed: () => UrlHelper.launchURL(context, l.$2),
                  ),
              ],
            ),
          ],
          if (sources.isNotEmpty)
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text('Sources (${sources.length})', style: theme.textTheme.titleSmall),
                children: [
                  for (final s in sources)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(s.$1, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(Uri.tryParse(s.$2)?.host ?? s.$2),
                      onTap: () => UrlHelper.launchURL(context, s.$2),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static List<(String, String)> _decodeList(String? json, String labelKey) {
    if (json == null || json.isEmpty) return const [];
    try {
      return (jsonDecode(json) as List)
          .whereType<Map>()
          .where((m) => m['url'] != null)
          .map((m) => ((m[labelKey] ?? m['url']).toString(), m['url'].toString()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class _ContactRow extends StatelessWidget {
  final BusinessLead lead;
  final String digits;

  const _ContactRow({required this.lead, required this.digits});

  @override
  Widget build(BuildContext context) {
    final buttons = <(IconData, String, String)>[
      if (digits.isNotEmpty) (Icons.call_rounded, 'Call', 'tel:$digits'),
      if (digits.isNotEmpty) (Icons.chat_rounded, 'WhatsApp', 'https://wa.me/${digits.replaceAll('+', '')}'),
      if (lead.email != null) (Icons.mail_rounded, 'Email', 'mailto:${lead.email}'),
      (Icons.map_rounded, 'Maps', 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${lead.name} ${lead.city ?? ''}')}'),
    ];
    return Row(
      children: [
        for (final (icon, label, url) in buttons)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onTap: () => UrlHelper.launchURL(context, url),
                child: Column(
                  children: [
                    Icon(icon, color: AppTheme.accent),
                    const SizedBox(height: 4),
                    Text(label, style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AiActions extends ConsumerStatefulWidget {
  final BusinessLead lead;

  const _AiActions({required this.lead});

  @override
  ConsumerState<_AiActions> createState() => _AiActionsState();
}

class _AiActionsState extends ConsumerState<_AiActions> {
  String? _busy;

  Future<void> _run(String key, Future<void> Function() task) async {
    setState(() => _busy = key);
    try {
      await task();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _outreach() => _run('outreach', () async {
        final profile = ref.read(careerProfileProvider).valueOrNull;
        final text = await ref.read(aiServiceProvider).quick(
              'Write a short, warm first-contact WhatsApp message (max 90 words) offering to build a website for this business. '
              'Reference one specific finding about their current web presence. No emojis, no hype, end with a simple question.\n\n'
              '${_leadContext(widget.lead)}\n${_senderContext(profile)}',
              system: 'You write concise, respectful B2B outreach. Output only the message text.',
            );
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => _OutreachSheet(text: text, phone: widget.lead.phone, email: widget.lead.email),
        );
      });

  Future<void> _proposal(DocFormat format) => _run(format.name, () async {
        final profile = ref.read(careerProfileProvider).valueOrNull;
        final doc = await ref.read(documentServiceProvider).create(
              title: 'Website proposal – ${widget.lead.name}',
              format: format,
              prompt: 'Write a one-to-two page website proposal for this business.\n'
                  'Sections: # title, ## Where you are today (use the findings), ## What we will build (pages, features; '
                  'if on Shopify, focus on custom theme/performance/conversion), ## Why it pays off (tie to their scale), '
                  '## Timeline (3 phases), ## Next step. Keep prices as [your quote].\n\n'
                  '${_leadContext(widget.lead)}\n${_senderContext(profile)}',
            );
        await DocumentService.open(doc.path);
        await ref.read(databaseProvider).updateBusinessLeadStatus(widget.lead.id, widget.lead.status == 'NEW' ? 'PROPOSAL' : widget.lead.status);
      });

  @override
  Widget build(BuildContext context) {
    Widget action(String key, IconData icon, String title, String subtitle, VoidCallback onTap) => AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          onTap: _busy == null ? onTap : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (_busy == key)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );

    return Column(
      children: [
        action('outreach', Icons.edit_note_rounded, 'Draft outreach message', 'Short WhatsApp / email intro', _outreach),
        action('pdf', Icons.picture_as_pdf_outlined, 'Website proposal (PDF)', 'Written by Gemini from these findings', () => _proposal(DocFormat.pdf)),
        action('docx', Icons.description_outlined, 'Website proposal (Word)', 'Editable .docx version', () => _proposal(DocFormat.docx)),
      ],
    );
  }
}

class _OutreachSheet extends StatelessWidget {
  final String text;
  final String? phone;
  final String? email;

  const _OutreachSheet({required this.text, this.phone, this.email});

  @override
  Widget build(BuildContext context) {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^\d]'), '');
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Outreach draft', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SelectableText(text, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 10),
              if (digits.isNotEmpty)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => UrlHelper.launchURL(context, 'https://wa.me/$digits?text=${Uri.encodeComponent(text)}'),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                )
              else if (email != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => UrlHelper.launchURL(context, 'mailto:$email?body=${Uri.encodeComponent(text)}'),
                    icon: const Icon(Icons.mail_rounded, size: 18),
                    label: const Text('Email'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
