import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local providers (owned by this file)
// ─────────────────────────────────────────────────────────────────────────────

final _reportsTableProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('reports');
});

// ─────────────────────────────────────────────────────────────────────────────
// Seed data helpers
// ─────────────────────────────────────────────────────────────────────────────

// Seeded performer data when deals list is empty.
const _seedPerformers = [
  ('Sofia Pereira', 'SF', '\$42.1M', 7),
  ('Raj Mehta', 'RM', '\$38.4M', 5),
  ('Tomas Brandt', 'TB', '\$24.7M', 4),
  ('Amara Diallo', 'AD', '\$19.2M', 3),
];

// Seeded stage data when deals list is empty.
const _seedStages = [
  ('Sourcing', 0.72, '\$84M'),
  ('Due Diligence', 0.52, '\$62M'),
  ('Negotiation', 0.36, '\$41M'),
  ('Closing', 0.20, '\$24M'),
];

// Pipeline stage order.
const _stageOrder = [
  'sourcing',
  'due_diligence',
  'negotiation',
  'closing',
  'closed_won',
];

// ─────────────────────────────────────────────────────────────────────────────
// Seeded reports used when the Supabase table is empty/missing.
// ─────────────────────────────────────────────────────────────────────────────

class _ReportItem {
  final String title;
  final String type; // PDF | XLSX
  final String group; // Executive | Portfolio | Compliance
  final String cadence; // e.g. "PDF · auto every 1st"  |  "on demand"
  final String lastRun; // ISO date string for timeAgo
  const _ReportItem({
    required this.title,
    required this.type,
    required this.group,
    required this.cadence,
    required this.lastRun,
  });
}

final _seedReports = [
  _ReportItem(
    title: 'Quarterly Board Pack',
    type: 'PDF',
    group: 'Executive',
    cadence: 'PDF · auto every 1st',
    lastRun: DateTime.now()
        .subtract(const Duration(days: 20))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'LP Capital Account Summary',
    type: 'PDF',
    group: 'Executive',
    cadence: 'PDF · on demand',
    lastRun: DateTime.now()
        .subtract(const Duration(days: 3))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'Client AUM Summary',
    type: 'XLSX',
    group: 'Portfolio',
    cadence: 'XLSX · auto every 1st',
    lastRun: DateTime.now()
        .subtract(const Duration(hours: 6))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'Monthly Pipeline',
    type: 'PDF',
    group: 'Portfolio',
    cadence: 'PDF · auto monthly',
    lastRun: DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'Performance Attribution',
    type: 'XLSX',
    group: 'Portfolio',
    cadence: 'XLSX · on demand',
    lastRun: DateTime.now()
        .subtract(const Duration(hours: 14))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'KYC / AML Status Report',
    type: 'PDF',
    group: 'Compliance',
    cadence: 'PDF · auto weekly',
    lastRun: DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String(),
  ),
  _ReportItem(
    title: 'Regulatory Filing Summary',
    type: 'PDF',
    group: 'Compliance',
    cadence: 'PDF · on demand',
    lastRun: DateTime.now()
        .subtract(const Duration(days: 12))
        .toIso8601String(),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// BiBody — Business Intelligence dashboard
// ─────────────────────────────────────────────────────────────────────────────

class BiBody extends ConsumerWidget {
  const BiBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(dealsProvider);
    final statsAsync = ref.watch(dealsStatsProvider);

    return dealsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(dealsProvider)),
      data: (deals) {
        final stats = statsAsync.valueOrNull;
        return _BiContent(deals: deals, stats: stats);
      },
    );
  }
}

class _BiContent extends StatelessWidget {
  final List<Deal> deals;
  final ({int activeCount, double pipelineValue})? stats;

  const _BiContent({required this.deals, required this.stats});

  // ── compute derived numbers ──────────────────────────────────────────────

  double get _pipelineTotal {
    if (stats != null) return stats!.pipelineValue;
    if (deals.isEmpty) return 247_600_000;
    return deals.fold<double>(0, (s, d) => s + (d.dealValue ?? 0));
  }

  double get _pipelineYtd => _pipelineTotal * 0.094; // proxy for growth

  double get _winRate {
    if (deals.isEmpty) return 0.38;
    final closed = deals.where((d) =>
        d.stage.toLowerCase() == 'closed_won' ||
        d.status?.toLowerCase() == 'won').length;
    final total = deals.where((d) =>
        d.stage.toLowerCase() == 'closed_won' ||
        d.stage.toLowerCase() == 'closed_lost' ||
        d.status?.toLowerCase() == 'won' ||
        d.status?.toLowerCase() == 'lost').length;
    return total == 0 ? 0.38 : closed / total;
  }

  double get _avgDealSize {
    final active = deals.where((d) => d.isActive && d.dealValue != null);
    if (active.isEmpty) return 18_300_000;
    final total = active.fold<double>(0, (s, d) => s + d.dealValue!);
    return total / active.length;
  }

  // Stage breakdown — use real deals or seed fallback
  List<(String label, double fraction, String amount)> get _stageRows {
    if (deals.isEmpty) return _seedStages.toList();
    final byStage = <String, double>{};
    for (final d in deals) {
      if (d.isActive) {
        byStage[d.stage] = (byStage[d.stage] ?? 0) + (d.dealValue ?? 0);
      }
    }
    if (byStage.isEmpty) return _seedStages.toList();
    final maxVal = byStage.values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return _seedStages.toList();

    final ordered = _stageOrder
        .where(byStage.containsKey)
        .map((s) => s)
        .toList();
    // add any unrecognised stages
    for (final s in byStage.keys) {
      if (!ordered.contains(s)) ordered.add(s);
    }

    return ordered.map((s) {
      final v = byStage[s] ?? 0;
      final label = _stageName(s);
      return (label, v / maxVal, formatCompactCurrency(v));
    }).toList();
  }

  String _stageName(String s) {
    switch (s) {
      case 'due_diligence':
        return 'Due Diligence';
      case 'closed_won':
        return 'Closed Won';
      case 'closed_lost':
        return 'Closed Lost';
      default:
        return s.isEmpty
            ? s
            : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
    }
  }

  // Top performers — group by leadConsultant or ownerId
  List<(String name, String initials, String amount, int count)>
      get _topPerformers {
    if (deals.isEmpty) return _seedPerformers.toList();
    final byOwner = <String, double>{};
    final countMap = <String, int>{};
    for (final d in deals) {
      final owner = d.leadConsultant ?? d.ownerId ?? 'Unknown';
      byOwner[owner] = (byOwner[owner] ?? 0) + (d.dealValue ?? 0);
      countMap[owner] = (countMap[owner] ?? 0) + 1;
    }
    if (byOwner.isEmpty) return _seedPerformers.toList();
    final sorted = byOwner.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) {
      return (
        e.key,
        initialsOf(e.key),
        formatCompactCurrency(e.value),
        countMap[e.key] ?? 0,
      );
    }).toList();
  }

  // Trend bar values (last 6 months — synthesised from pipeline)
  List<double> get _trendBars {
    if (deals.isEmpty) {
      return [0.38, 0.52, 0.47, 0.68, 0.82, 0.95];
    }
    // Simple heuristic: distribute pipeline across 6 buckets by updated_at month
    final buckets = List<double>.filled(6, 0);
    final now = DateTime.now();
    for (final d in deals) {
      final updatedAt = DateTime.tryParse(d.updatedAt ?? '');
      if (updatedAt == null) continue;
      final monthsAgo = (now.year - updatedAt.year) * 12 +
          (now.month - updatedAt.month);
      if (monthsAgo >= 0 && monthsAgo < 6) {
        buckets[5 - monthsAgo] += d.dealValue ?? 0;
      }
    }
    final maxBucket = buckets.reduce((a, b) => a > b ? a : b);
    if (maxBucket == 0) return [0.38, 0.52, 0.47, 0.68, 0.82, 0.95];
    return buckets.map((v) => (v / maxBucket).clamp(0.08, 1.0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = _pipelineTotal;
    final ytdPct = pipeline > 0 ? (_pipelineYtd / pipeline * 100) : 9.4;
    final winRate = _winRate;
    final avgDeal = _avgDealSize;
    final stages = _stageRows;
    final performers = _topPerformers;
    final trendBars = _trendBars;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero metric row ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: DarkCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                gradient: AppColors.darkCardGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIPELINE',
                        style: AppText.eyebrow(AppColors.mutedOnDark)),
                    const SizedBox(height: 7),
                    Text(
                      formatCompactCurrency(pipeline),
                      style: AppText.serif(size: 26, color: AppColors.ivory),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward,
                            size: 11, color: Color(0xFF7FD0AD)),
                        const SizedBox(width: 3),
                        Text(
                          '${ytdPct.toStringAsFixed(1)}% YTD',
                          style: AppText.sans(
                              size: 10.5, color: AppColors.greenOnDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WIN RATE',
                        style: AppText.eyebrow(AppColors.mutedLight)),
                    const SizedBox(height: 7),
                    Text(
                      '${(winRate * 100).toStringAsFixed(0)}%',
                      style: AppText.serif(size: 26),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg deal ${formatCompactCurrency(avgDeal)}',
                      style: AppText.sans(size: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Trend bar-chart card ─────────────────────────────────────────
        AppCard(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pipeline Trend',
                      style:
                          AppText.sans(size: 13, weight: FontWeight.w600)),
                  Row(
                    children: [
                      _PillChip(label: 'YTD', active: true),
                      const SizedBox(width: 4),
                      _PillChip(label: 'QTD', active: false),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _monthLabels(),
                style: AppText.sans(size: 9.5, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              _LightBarChart(values: trendBars, height: 60),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Deals by stage ───────────────────────────────────────────────
        SectionHead('Deals by Stage',
            trailing: Text(
              '${deals.where((d) => d.isActive).isNotEmpty ? deals.where((d) => d.isActive).length : stages.length} active',
              style: AppText.sans(size: 12, color: AppColors.muted),
            )),
        AppCard(
          radius: 18,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                _StageBar(
                  label: stages[i].$1,
                  fraction: stages[i].$2,
                  amount: stages[i].$3,
                ),
                if (i < stages.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Top performers ───────────────────────────────────────────────
        SectionHead('Top Performers',
            trailing: Text('This quarter',
                style: AppText.sans(size: 12, color: AppColors.muted))),
        AppCard(
          noPadding: true,
          radius: 18,
          child: Column(
            children: [
              for (int i = 0; i < performers.length; i++)
                _PerformerRow(
                  name: performers[i].$1,
                  initials: performers[i].$2,
                  amount: performers[i].$3,
                  dealCount: performers[i].$4,
                  rank: i + 1,
                  isLast: i == performers.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthLabels() {
    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i, 1);
      return monthNames[m.month - 1];
    });
    return months.join('          ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BiBody sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PillChip extends StatelessWidget {
  final String label;
  final bool active;
  const _PillChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:
            active ? AppColors.onyx700 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppText.sans(
          size: 9.5,
          color: active ? Colors.white : AppColors.muted,
          weight: active ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _LightBarChart extends StatelessWidget {
  final List<double> values;
  final double height;
  const _LightBarChart({required this.values, required this.height});

  @override
  Widget build(BuildContext context) {
    final n = values.length;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < n; i++) ...[
            Expanded(
              child: Container(
                height: values[i].clamp(0.05, 1.0) * height,
                decoration: BoxDecoration(
                  gradient:
                      i >= n - 3 ? AppColors.goldGradientVertical : null,
                  color: i >= n - 3 ? null : AppColors.hairline,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
            if (i != n - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  final String label;
  final double fraction; // 0..1
  final String amount;
  const _StageBar(
      {required this.label, required this.fraction, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppText.sans(size: 12.5, weight: FontWeight.w500)),
            Text(amount,
                style:
                    AppText.sans(size: 12.5, color: AppColors.goldText,
                        weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Container(
                height: 6,
                width: w,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 6,
                width: w * fraction.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _PerformerRow extends StatelessWidget {
  final String name;
  final String initials;
  final String amount;
  final int dealCount;
  final int rank;
  final bool isLast;
  const _PerformerRow({
    required this.name,
    required this.initials,
    required this.amount,
    required this.dealCount,
    required this.rank,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 22,
            child: Text(
              '#$rank',
              style: AppText.sans(
                  size: 11,
                  color: rank == 1
                      ? AppColors.goldText
                      : AppColors.mutedLight,
                  weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          MonogramTile(initials: initials, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dealCount deal${dealCount == 1 ? '' : 's'}',
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(amount,
              style: AppText.serif(size: 15, color: AppColors.goldText)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ReportsBody — Reports library
// ─────────────────────────────────────────────────────────────────────────────

class ReportsBody extends ConsumerWidget {
  const ReportsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(_reportsTableProvider);

    return rowsAsync.when(
      loading: () => const LoadingState(),
      error: (e, st) => _ReportsContent(items: _seedReports),
      data: (rows) {
        final items = _mapRows(rows);
        return Stack(
          children: [
            _ReportsContent(items: items.isEmpty ? _seedReports : items),
            Positioned(
              right: 20,
              bottom: 30,
              child: GoldFab(
                icon: Icons.add,
                onTap: () {},
              ),
            ),
          ],
        );
      },
    );
  }

  List<_ReportItem> _mapRows(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      final type = (r['type'] ?? r['format'] ?? 'PDF').toString().toUpperCase();
      return _ReportItem(
        title: (r['name'] ?? r['title'] ?? 'Report').toString(),
        type: type.contains('XLS') ? 'XLSX' : 'PDF',
        group: (r['group'] ?? r['category'] ?? 'General').toString(),
        cadence: (r['cadence'] ?? r['schedule'] ?? 'on demand').toString(),
        lastRun: (r['last_run'] ?? r['updated_at'] ?? '').toString(),
      );
    }).toList();
  }
}

class _ReportsContent extends StatelessWidget {
  final List<_ReportItem> items;
  const _ReportsContent({required this.items});

  // KPI aggregates
  int get _total => items.length;

  int get _scheduled =>
      items.where((r) => !r.cadence.contains('on demand')).length;

  int get _generatedThisMonth {
    final now = DateTime.now();
    return items.where((r) {
      final d = DateTime.tryParse(r.lastRun);
      return d != null &&
          d.year == now.year &&
          d.month == now.month;
    }).length;
  }

  // Group items by group label
  Map<String, List<_ReportItem>> get _grouped {
    final map = <String, List<_ReportItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.group, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── KPI row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiMini(
                label: 'TOTAL',
                value: '$_total',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiMini(
                label: 'SCHEDULED',
                value: '$_scheduled',
                icon: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiMini(
                label: 'THIS MONTH',
                value: '$_generatedThisMonth',
                icon: Icons.bar_chart_outlined,
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Generate report CTA ──────────────────────────────────────────
        GoldButton(
          label: 'Generate Report',
          icon: Icons.play_arrow_rounded,
          onTap: () {},
        ),
        const SizedBox(height: 20),

        // ── Grouped report cards ─────────────────────────────────────────
        for (final entry in grouped.entries) ...[
          SectionHead(entry.key),
          AppCard(
            noPadding: true,
            radius: 18,
            child: Column(
              children: [
                for (int i = 0; i < entry.value.length; i++)
                  _ReportRow(
                    item: entry.value[i],
                    isLast: i == entry.value.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ReportsBody sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _KpiMini extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const _KpiMini({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: highlight ? AppColors.goldText : AppColors.muted),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.serif(
              size: 22,
              color: highlight ? AppColors.goldText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.eyebrow(AppColors.mutedLight)),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final _ReportItem item;
  final bool isLast;
  const _ReportRow({required this.item, required this.isLast});

  IconData get _typeIcon =>
      item.type == 'XLSX' ? Icons.table_chart_outlined : Icons.picture_as_pdf_outlined;

  Color get _typeColor =>
      item.type == 'XLSX' ? AppColors.green : AppColors.red;

  Color get _typeBg =>
      item.type == 'XLSX'
          ? AppColors.green.withValues(alpha: 0.10)
          : AppColors.red.withValues(alpha: 0.10);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          GlyphTile(
            icon: _typeIcon,
            color: _typeColor,
            bg: _typeBg,
            size: 40,
            radius: 11,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.cadence,
                      style:
                          AppText.sans(size: 11, color: AppColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.lastRun.isEmpty
                          ? 'Never'
                          : timeAgo(item.lastRun),
                      style:
                          AppText.sans(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Trailing action
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.hairlineSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_outlined,
                  size: 16, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
