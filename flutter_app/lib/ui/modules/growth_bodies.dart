import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers (local to this file)
// ─────────────────────────────────────────────────────────────────────────────

final _campaignsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('campaigns');
});

final _workflowsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('workflows');
});

final _productionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('productions');
});

// ─────────────────────────────────────────────────────────────────────────────
// Seed data helpers
// ─────────────────────────────────────────────────────────────────────────────

final _seedCampaigns = <Map<String, dynamic>>[
  {
    'id': 'c1',
    'name': 'Year-End Tax Tips',
    'channel': 'Email',
    'status': 'Sent',
    'reach': 14320,
    'ctr': 0.078,
    'engagement': 0.22,
    'sent_date': '2025-12-03T09:00:00Z',
  },
  {
    'id': 'c2',
    'name': 'Q3 Sourcing Themes',
    'channel': 'Email',
    'status': 'Sent',
    'reach': 9810,
    'ctr': 0.061,
    'engagement': 0.18,
    'sent_date': '2025-09-15T10:30:00Z',
  },
  {
    'id': 'c3',
    'name': 'LP Investor Update — Oct',
    'channel': 'Email',
    'status': 'Sent',
    'reach': 12450,
    'ctr': 0.094,
    'engagement': 0.31,
    'sent_date': '2025-10-21T08:00:00Z',
  },
  {
    'id': 'c4',
    'name': 'Q1 2026 Market Outlook',
    'channel': 'Email',
    'status': 'Scheduled',
    'reach': 0,
    'ctr': 0.0,
    'engagement': 0.0,
    'sent_date': '2026-01-08T09:00:00Z',
  },
  {
    'id': 'c5',
    'name': 'Braccia Alts Spotlight',
    'channel': 'Email',
    'status': 'Draft',
    'reach': 0,
    'ctr': 0.0,
    'engagement': 0.0,
    'sent_date': null,
  },
  {
    'id': 'c6',
    'name': 'Year-End Fund Summary',
    'channel': 'Email',
    'status': 'Scheduled',
    'reach': 0,
    'ctr': 0.0,
    'engagement': 0.0,
    'sent_date': '2025-12-28T08:00:00Z',
  },
];

final _seedWorkflows = <Map<String, dynamic>>[
  {
    'id': 'w1',
    'name': 'New lead → assign',
    'trigger': 'New lead created',
    'action': 'Assign to onboarding team',
    'runs': 342,
    'last_run': '2026-06-21T08:14:00Z',
    'active': true,
  },
  {
    'id': 'w2',
    'name': 'Deal won → invoice',
    'trigger': 'Deal stage = Closed Won',
    'action': 'Create invoice draft',
    'runs': 87,
    'last_run': '2026-06-20T16:22:00Z',
    'active': true,
  },
  {
    'id': 'w3',
    'name': 'Task overdue → notify',
    'trigger': 'Task past due date',
    'action': 'Slack & email owner',
    'runs': 521,
    'last_run': '2026-06-21T06:00:00Z',
    'active': true,
  },
  {
    'id': 'w4',
    'name': 'KYC cleared → activate',
    'trigger': 'KYC status = Cleared',
    'action': 'Set client status → Active',
    'runs': 64,
    'last_run': '2026-06-19T14:10:00Z',
    'active': true,
  },
  {
    'id': 'w5',
    'name': 'Doc signed → archive',
    'trigger': 'DocuSign webhook received',
    'action': 'Move to Signed Documents',
    'runs': 215,
    'last_run': '2026-06-18T11:05:00Z',
    'active': false,
  },
  {
    'id': 'w6',
    'name': 'LP commit → update cap table',
    'trigger': 'New LP commitment logged',
    'action': 'Refresh cap table & notify CFO',
    'runs': 38,
    'last_run': '2026-06-15T09:48:00Z',
    'active': true,
  },
];

final _seedProductions = <Map<String, dynamic>>[
  {
    'id': 'p1',
    'title': 'The Atlas Project',
    'stage': 'Production',
    'budget': 4200000,
    'progress': 0.62,
    'status': 'in_progress',
  },
  {
    'id': 'p2',
    'title': 'Northern Lights',
    'stage': 'Post',
    'budget': 1850000,
    'progress': 0.81,
    'status': 'in_progress',
  },
  {
    'id': 'p3',
    'title': 'Meridian',
    'stage': 'Released',
    'budget': 3100000,
    'progress': 1.0,
    'status': 'done',
  },
  {
    'id': 'p4',
    'title': 'Capital Heist',
    'stage': 'Pre-prod',
    'budget': 900000,
    'progress': 0.18,
    'status': 'prospect',
  },
  {
    'id': 'p5',
    'title': 'The Founder',
    'stage': 'Post',
    'budget': 2400000,
    'progress': 0.91,
    'status': 'in_progress',
  },
  {
    'id': 'p6',
    'title': 'Sovereign',
    'stage': 'Pre-prod',
    'budget': 650000,
    'progress': 0.05,
    'status': 'prospect',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// MarketingBody
// ─────────────────────────────────────────────────────────────────────────────

class MarketingBody extends ConsumerWidget {
  const MarketingBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_campaignsProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, st) => _MarketingContent(rows: _seedCampaigns),
      data: (rows) =>
          _MarketingContent(rows: rows.isEmpty ? _seedCampaigns : rows),
    );
  }
}

class _MarketingContent extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _MarketingContent({required this.rows});

  @override
  Widget build(BuildContext context) {
    // Aggregate KPIs across all Sent campaigns
    final sent = rows.where((r) => r['status'] == 'Sent').toList();
    final totalReach =
        sent.fold<int>(0, (s, r) => s + ((r['reach'] as num?)?.toInt() ?? 0));
    final avgCtr = sent.isEmpty
        ? 0.0
        : sent.fold<double>(
                0, (s, r) => s + ((r['ctr'] as num?)?.toDouble() ?? 0)) /
            sent.length;
    final avgEng = sent.isEmpty
        ? 0.0
        : sent.fold<double>(
                0, (s, r) => s + ((r['engagement'] as num?)?.toDouble() ?? 0)) /
            sent.length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── KPI row ──────────────────────────────────────
            Row(
              children: [
                _KpiChip(
                  label: 'REACH',
                  value: _compactInt(totalReach),
                  delta: '▲ 12%',
                  dark: true,
                ),
                const SizedBox(width: 10),
                _KpiChip(
                  label: 'AVG CTR',
                  value: '${(avgCtr * 100).toStringAsFixed(1)}%',
                  delta: '▲ 0.4 pts',
                  dark: false,
                ),
                const SizedBox(width: 10),
                _KpiChip(
                  label: 'ENGAGEMENT',
                  value: '${(avgEng * 100).toStringAsFixed(0)}%',
                  delta: '▲ 2 pts',
                  dark: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHead(
              'Campaigns',
              trailing: Text(
                '${rows.length} total',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
            ),
            AppCard(
              noPadding: true,
              radius: 18,
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++)
                    _CampaignRow(
                      data: rows[i],
                      last: i == rows.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(onTap: () {}, icon: Icons.add),
        ),
      ],
    );
  }

  String _compactInt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool dark;
  const _KpiChip({
    required this.label,
    required this.value,
    required this.delta,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: dark
          ? DarkCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: _chipContent(
                  labelColor: AppColors.mutedOnDark,
                  valueColor: AppColors.ivory,
                  deltaColor: AppColors.greenOnDark),
            )
          : AppCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: _chipContent(
                  labelColor: AppColors.mutedLight,
                  valueColor: AppColors.ink,
                  deltaColor: AppColors.green),
            ),
    );
  }

  Widget _chipContent({
    required Color labelColor,
    required Color valueColor,
    required Color deltaColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow(labelColor)),
        const SizedBox(height: 6),
        Text(value, style: AppText.serif(size: 20, color: valueColor)),
        const SizedBox(height: 2),
        Text(delta, style: AppText.sans(size: 10.5, color: deltaColor)),
      ],
    );
  }
}

class _CampaignRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool last;
  const _CampaignRow({required this.data, required this.last});

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Campaign').toString();
    final channel = (data['channel'] ?? 'Email').toString();
    final status = (data['status'] ?? 'Draft').toString();
    final reach = (data['reach'] as num?)?.toInt() ?? 0;
    final ctr = (data['ctr'] as num?)?.toDouble() ?? 0.0;
    final sentDate = data['sent_date'] as String?;

    StatusPill pill;
    switch (status) {
      case 'Sent':
        pill = StatusPill(
          label: 'Sent',
          color: AppColors.green,
          bg: AppColors.green.withValues(alpha: 0.12),
        );
        break;
      case 'Scheduled':
        pill = StatusPill(
          label: 'Scheduled',
          color: AppColors.goldTextSoft,
          bg: AppColors.gold500.withValues(alpha: 0.15),
        );
        break;
      default:
        pill = StatusPill(
          label: 'Draft',
          color: AppColors.muted,
          bg: AppColors.hairlineSoft,
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlyphTile(
            icon: Icons.campaign,
            color: AppColors.green,
            bg: AppColors.green.withValues(alpha: 0.12),
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 11, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(channel,
                        style:
                            AppText.sans(size: 11, color: AppColors.muted)),
                    if (reach > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${_compactInt(reach)} reach · ${(ctr * 100).toStringAsFixed(1)}% CTR',
                        style: AppText.sans(size: 11, color: AppColors.muted),
                      ),
                    ],
                    if (sentDate != null && reach == 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        formatDate(sentDate),
                        style: AppText.sans(size: 11, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              pill,
              if (sentDate != null && reach > 0) ...[
                const SizedBox(height: 4),
                Text(
                  timeAgo(sentDate),
                  style: AppText.sans(size: 10, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _compactInt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorkflowsBody
// ─────────────────────────────────────────────────────────────────────────────

class WorkflowsBody extends ConsumerWidget {
  const WorkflowsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_workflowsProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, st) => _WorkflowsContent(rows: _seedWorkflows),
      data: (rows) =>
          _WorkflowsContent(rows: rows.isEmpty ? _seedWorkflows : rows),
    );
  }
}

class _WorkflowsContent extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _WorkflowsContent({required this.rows});

  @override
  Widget build(BuildContext context) {
    final activeCount = rows.where((r) => r['active'] == true).length;
    final totalRuns = rows.fold<int>(
        0, (s, r) => s + ((r['runs'] as num?)?.toInt() ?? 0));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Summary strip ────────────────────────────────
            DarkCard(
              radius: 18,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE', style: AppText.eyebrow(AppColors.mutedOnDark)),
                        const SizedBox(height: 6),
                        Text('$activeCount',
                            style: AppText.serif(
                                size: 28, color: AppColors.ivory)),
                        const SizedBox(height: 2),
                        Text('of ${rows.length} automations',
                            style: AppText.sans(
                                size: 11, color: AppColors.mutedOnDark)),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL RUNS',
                            style: AppText.eyebrow(AppColors.mutedOnDark)),
                        const SizedBox(height: 6),
                        Text(_compactInt(totalRuns),
                            style: AppText.serif(
                                size: 28, color: AppColors.gold300)),
                        const SizedBox(height: 2),
                        Text('all time',
                            style: AppText.sans(
                                size: 11, color: AppColors.mutedOnDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionHead(
              'Automations',
              trailing: Text(
                '${rows.length} total',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
            ),
            AppCard(
              noPadding: true,
              radius: 18,
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++)
                    _WorkflowRow(
                      data: rows[i],
                      last: i == rows.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(onTap: () {}, icon: Icons.add),
        ),
      ],
    );
  }

  String _compactInt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }
}

/// Stateful nested widget to own the active toggle state.
class _WorkflowRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool last;
  const _WorkflowRow({required this.data, required this.last});

  @override
  State<_WorkflowRow> createState() => _WorkflowRowState();
}

class _WorkflowRowState extends State<_WorkflowRow> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = (widget.data['active'] as bool?) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.data['name'] ?? 'Automation').toString();
    final trigger = (widget.data['trigger'] ?? '').toString();
    final action = (widget.data['action'] ?? '').toString();
    final runs = (widget.data['runs'] as num?)?.toInt() ?? 0;
    final lastRun = widget.data['last_run'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: widget.last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlyphTile(
            icon: Icons.account_tree_outlined,
            color: AppColors.green,
            bg: AppColors.green.withValues(alpha: 0.12),
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TriggerActionChip(label: trigger),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.arrow_forward,
                          size: 10, color: AppColors.muted),
                    ),
                    Flexible(child: _TriggerActionChip(label: action)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.play_circle_outline,
                        size: 11, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text('$runs runs',
                        style: AppText.sans(size: 11, color: AppColors.muted)),
                    if (lastRun != null && lastRun.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.schedule,
                          size: 11, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Text(timeAgo(lastRun),
                          style:
                              AppText.sans(size: 11, color: AppColors.muted)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            activeThumbColor: AppColors.green,
            activeTrackColor: AppColors.green.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.muted,
            inactiveTrackColor: AppColors.hairline,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _TriggerActionChip extends StatelessWidget {
  final String label;
  const _TriggerActionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.hairlineSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sans(size: 10, color: AppColors.ink, weight: FontWeight.w500),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProductionsBody
// ─────────────────────────────────────────────────────────────────────────────

class ProductionsBody extends ConsumerWidget {
  const ProductionsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_productionsProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, st) => _ProductionsContent(rows: _seedProductions),
      data: (rows) =>
          _ProductionsContent(rows: rows.isEmpty ? _seedProductions : rows),
    );
  }
}

class _ProductionsContent extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _ProductionsContent({required this.rows});

  @override
  Widget build(BuildContext context) {
    final totalBudget = rows.fold<double>(
        0, (s, r) => s + ((r['budget'] as num?)?.toDouble() ?? 0));
    final released = rows.where((r) => r['stage'] == 'Released').length;
    final inProd =
        rows.where((r) => r['stage'] == 'Production' || r['stage'] == 'Post').length;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Hero KPI ─────────────────────────────────────
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DarkCard(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL BUDGET',
                            style: AppText.eyebrow(AppColors.mutedOnDark)),
                        const SizedBox(height: 6),
                        Text(
                          formatCompactCurrency(totalBudget),
                          style: AppText.serif(
                              size: 26, color: AppColors.gold300),
                        ),
                        const SizedBox(height: 2),
                        Text('across ${rows.length} productions',
                            style: AppText.sans(
                                size: 11, color: AppColors.mutedOnDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      AppCard(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IN PROD',
                                style: AppText.eyebrow(AppColors.mutedLight)),
                            const SizedBox(height: 4),
                            Text('$inProd',
                                style: AppText.serif(size: 20)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        radius: 14,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('RELEASED',
                                style: AppText.eyebrow(AppColors.mutedLight)),
                            const SizedBox(height: 4),
                            Text('$released',
                                style: AppText.serif(
                                    size: 20, color: AppColors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SectionHead(
              'Film Productions',
              trailing: Text(
                '${rows.length} projects',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
            ),
            for (final row in rows) ...[
              _ProductionCard(data: row),
              const SizedBox(height: 10),
            ],
          ],
        ),
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(onTap: () {}, icon: Icons.add),
        ),
      ],
    );
  }
}

class _ProductionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? 'Untitled').toString();
    final stage = (data['stage'] ?? 'Pre-prod').toString();
    final budget = (data['budget'] as num?)?.toDouble() ?? 0;
    final progress =
        ((data['progress'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    final status = (data['status'] ?? 'prospect').toString();

    return Pressable(
      onTap: () {},
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlyphTile(
                  icon: Icons.movie,
                  color: AppColors.purple,
                  bg: AppColors.purple.withValues(alpha: 0.14),
                  size: 44,
                  radius: 13,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.sans(size: 14.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _StageBadge(stage: stage),
                          const SizedBox(width: 8),
                          StatusPill.forStatus(status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatCompactCurrency(budget),
                  style: AppText.serif(size: 16, color: AppColors.goldText),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.hairline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0
                            ? AppColors.green
                            : AppColors.gold500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppText.sans(
                    size: 11.5,
                    weight: FontWeight.w600,
                    color: progress >= 1.0 ? AppColors.green : AppColors.goldText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String stage;
  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (stage) {
      case 'Pre-prod':
        color = AppColors.blue;
        bg = AppColors.blue.withValues(alpha: 0.12);
        break;
      case 'Production':
        color = AppColors.goldTextSoft;
        bg = AppColors.gold500.withValues(alpha: 0.14);
        break;
      case 'Post':
        color = AppColors.purple;
        bg = AppColors.purple.withValues(alpha: 0.13);
        break;
      case 'Released':
        color = AppColors.green;
        bg = AppColors.green.withValues(alpha: 0.12);
        break;
      default:
        color = AppColors.muted;
        bg = AppColors.hairlineSoft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        stage,
        style: AppText.sans(
            size: 10.5, color: color, weight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}
