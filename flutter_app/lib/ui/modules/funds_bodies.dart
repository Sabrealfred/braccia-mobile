import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _fundsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('funds');
});

final _fundFormationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('fund_formations');
});

// ── Seed data ─────────────────────────────────────────────────────────────────

const _seedFunds = [
  _FundSeed(
    name: 'Braccia Fund I LP',
    status: 'Active',
    calledPct: 0.68,
    lpCount: 23,
    committed: 184e6,
    tvpi: 1.84,
    dpi: 0.62,
    irr: 22.1,
  ),
  _FundSeed(
    name: 'Growth Fund II',
    status: 'Raising',
    calledPct: 0.41,
    lpCount: 11,
    committed: 63e6,
    tvpi: 1.21,
    dpi: 0.18,
    irr: 14.7,
  ),
  _FundSeed(
    name: 'Treasury MMF',
    status: 'Active',
    calledPct: 1.0,
    lpCount: 4,
    committed: 15e6,
    tvpi: 1.05,
    dpi: 1.05,
    irr: 5.1,
  ),
];

const _seedFormations = [
  _FormationSeed(
    name: 'Growth Fund III',
    stage: 'Raising',
    stageIndex: 2,
    closedPct: 0.42,
    targetSize: 150e6,
  ),
  _FormationSeed(
    name: 'Opportunity Fund',
    stage: 'Structuring',
    stageIndex: 0,
    closedPct: 0.0,
    targetSize: 75e6,
  ),
  _FormationSeed(
    name: 'Credit Opportunities I',
    stage: 'Docs',
    stageIndex: 1,
    closedPct: 0.12,
    targetSize: 200e6,
  ),
];

// ── Value objects ─────────────────────────────────────────────────────────────

class _FundSeed {
  final String name;
  final String status;
  final double calledPct;
  final int lpCount;
  final double committed;
  final double tvpi;
  final double dpi;
  final double irr;

  const _FundSeed({
    required this.name,
    required this.status,
    required this.calledPct,
    required this.lpCount,
    required this.committed,
    required this.tvpi,
    required this.dpi,
    required this.irr,
  });
}

class _FormationSeed {
  final String name;
  final String stage;
  final int stageIndex;
  final double closedPct;
  final double targetSize;

  const _FormationSeed({
    required this.name,
    required this.stage,
    required this.stageIndex,
    required this.closedPct,
    required this.targetSize,
  });
}

// ── FundsBody ─────────────────────────────────────────────────────────────────

/// Fund Accounting module body — AUM hero, KPI chips, fund list, capital calls.
/// Rendered inside ModuleScreen's frame (header already provided).
class FundsBody extends ConsumerWidget {
  const FundsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_fundsProvider);
    final funds = async.whenData((rows) => rows).valueOrNull ?? [];
    final seeds = funds.isEmpty ? _seedFunds : _rowsToSeeds(funds);

    // Aggregate AUM
    final totalAum = seeds.fold<double>(0, (s, f) => s + f.committed);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Hero row ──────────────────────────────────────
            _HeroRow(totalAum: totalAum, seeds: seeds),
            const SizedBox(height: 12),

            // ── KPI chips ─────────────────────────────────────
            _KpiChipRow(seeds: seeds),
            const SizedBox(height: 20),

            // ── Fund list ─────────────────────────────────────
            SectionHead(
              'Funds',
              trailing: async.isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.goldTextSoft),
                      ),
                    )
                  : null,
            ),
            AppCard(
              noPadding: true,
              radius: AppRadii.card,
              child: Column(
                children: [
                  for (int i = 0; i < seeds.length; i++)
                    _FundRow(seed: seeds[i], isLast: i == seeds.length - 1),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Capital calls mini-section ─────────────────────
            const SectionHead('Capital Calls'),
            _CapitalCallsCard(seeds: seeds),
          ],
        ),
        // FAB
        Positioned(
          right: 2,
          bottom: 4,
          child: GoldFab(
            icon: Icons.add,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  List<_FundSeed> _rowsToSeeds(List<Map<String, dynamic>> rows) {
    return rows.take(8).map((r) {
      final name =
          (r['name'] ?? r['fund_name'] ?? r['title'] ?? 'Fund').toString();
      final status = (r['status'] ?? 'Active').toString();
      final calledPct =
          (r['called_pct'] ?? r['called_percent'] ?? 0.5) as num;
      final lpCount = (r['lp_count'] ?? r['num_lps'] ?? 10) as num;
      final committed =
          (r['committed'] ?? r['committed_capital'] ?? r['amount'] ?? 50e6)
              as num;
      final tvpi = (r['tvpi'] ?? 1.5) as num;
      final dpi = (r['dpi'] ?? 0.5) as num;
      final irr = (r['irr'] ?? r['net_irr'] ?? 15.0) as num;
      return _FundSeed(
        name: name,
        status: status,
        calledPct: calledPct.toDouble().clamp(0, 1),
        lpCount: lpCount.toInt(),
        committed: committed.toDouble(),
        tvpi: tvpi.toDouble(),
        dpi: dpi.toDouble(),
        irr: irr.toDouble(),
      );
    }).toList();
  }
}

// ── Hero row ──────────────────────────────────────────────────────────────────

class _HeroRow extends StatelessWidget {
  final double totalAum;
  final List<_FundSeed> seeds;

  const _HeroRow({required this.totalAum, required this.seeds});

  @override
  Widget build(BuildContext context) {
    final activeFunds = seeds.where((s) => s.status == 'Active').length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AUM dark card
        Expanded(
          flex: 3,
          child: DarkCard(
            padding: const EdgeInsets.all(18),
            radius: AppRadii.cardLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FIRM AUM',
                    style: AppText.eyebrow(AppColors.mutedOnDark)),
                const SizedBox(height: 8),
                Text(
                  formatCompactCurrency(totalAum),
                  style: AppText.serif(
                    size: 28,
                    color: AppColors.gold300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '▲ 11.2% YTD',
                  style: AppText.sans(
                    size: 11,
                    color: AppColors.greenOnDark,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                BarSparkline(
                  values: const [0.38, 0.52, 0.47, 0.65, 0.78, 0.91],
                  highlightCount: 3,
                  height: 44,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Active funds metric card
        Expanded(
          flex: 2,
          child: AppCard(
            padding: const EdgeInsets.all(16),
            radius: AppRadii.cardLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE', style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 8),
                Text(
                  '$activeFunds',
                  style: AppText.serif(size: 28, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Funds',
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Text(
                  '${seeds.length} Total',
                  style: AppText.sans(
                    size: 11,
                    color: AppColors.goldText,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── KPI chip row ─────────────────────────────────────────────────────────────

class _KpiChipRow extends StatelessWidget {
  final List<_FundSeed> seeds;

  const _KpiChipRow({required this.seeds});

  @override
  Widget build(BuildContext context) {
    // Weighted-average TVPI / DPI / IRR across all funds
    final totalCommitted =
        seeds.fold<double>(0, (s, f) => s + f.committed);
    double tvpi = 0, dpi = 0, irr = 0;
    if (totalCommitted > 0) {
      for (final f in seeds) {
        final w = f.committed / totalCommitted;
        tvpi += f.tvpi * w;
        dpi += f.dpi * w;
        irr += f.irr * w;
      }
    }
    return Row(
      children: [
        _KpiChip(label: 'TVPI', value: '${tvpi.toStringAsFixed(2)}x'),
        const SizedBox(width: 8),
        _KpiChip(label: 'DPI', value: '${dpi.toStringAsFixed(2)}x'),
        const SizedBox(width: 8),
        _KpiChip(
            label: 'Net IRR', value: '${irr.toStringAsFixed(1)}%', gold: true),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;

  const _KpiChip({
    required this.label,
    required this.value,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: gold
              ? AppColors.gold500.withValues(alpha: 0.10)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.inner),
          border: Border.all(
            color: gold ? AppColors.gold300.withValues(alpha: 0.40) : AppColors.hairline,
          ),
          boxShadow: gold
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    spreadRadius: -6,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.eyebrow(AppColors.mutedLight)),
            const SizedBox(height: 5),
            Text(
              value,
              style: AppText.serif(
                size: 17,
                color: gold ? AppColors.goldText : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fund row ──────────────────────────────────────────────────────────────────

class _FundRow extends StatelessWidget {
  final _FundSeed seed;
  final bool isLast;

  const _FundRow({required this.seed, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final pctLabel = '${(seed.calledPct * 100).toStringAsFixed(0)}% called';
    final lpLabel = '${seed.lpCount} LPs';

    return Pressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.hairlineSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    seed.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.sans(size: 14, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatCompactCurrency(seed.committed),
                  style:
                      AppText.serif(size: 16, color: AppColors.goldText),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusPill.forStatus(seed.status.toLowerCase()),
                const SizedBox(width: 8),
                Text(
                  '$pctLabel · $lpLabel',
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 9),
            // Called-% progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: seed.calledPct,
                minHeight: 4,
                backgroundColor: AppColors.hairline,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Capital calls mini-section ────────────────────────────────────────────────

class _CapitalCallsCard extends StatelessWidget {
  final List<_FundSeed> seeds;

  const _CapitalCallsCard({required this.seeds});

  @override
  Widget build(BuildContext context) {
    // Derive pending calls from funds not yet fully called
    final pending = seeds.where((f) => f.calledPct < 1.0).toList();
    if (pending.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No pending capital calls'),
          ),
        ),
      );
    }

    return AppCard(
      noPadding: true,
      radius: AppRadii.card,
      child: Column(
        children: [
          for (int i = 0; i < pending.length; i++)
            _CallRow(fund: pending[i], isLast: i == pending.length - 1),
        ],
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  final _FundSeed fund;
  final bool isLast;

  const _CallRow({required this.fund, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final uncalled = fund.committed * (1 - fund.calledPct);
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
            icon: Icons.call_made_rounded,
            color: AppColors.goldText,
            bg: AppColors.gold500.withValues(alpha: 0.10),
            size: 38,
            radius: 11,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${((1 - fund.calledPct) * 100).toStringAsFixed(0)}% uncalled',
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCurrency(uncalled),
                style: AppText.serif(size: 15, color: AppColors.goldText),
              ),
              const SizedBox(height: 2),
              const StatusPill(
                label: 'Pending',
                color: AppColors.goldTextSoft,
                bg: Color(0x1AC79A3E),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── FundFormationBody ─────────────────────────────────────────────────────────

/// Fund Formation pipeline — stage tracker + forming-fund list.
/// Rendered inside ModuleScreen's frame (header already provided).
class FundFormationBody extends ConsumerWidget {
  const FundFormationBody({super.key});

  static const _stages = ['Structuring', 'Docs', 'Raising', 'Closing'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_fundFormationsProvider);
    final rows = async.whenData((r) => r).valueOrNull ?? [];
    final formations =
        rows.isEmpty ? _seedFormations : _rowsToFormations(rows);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Stage tracker ──────────────────────────────────
            AppCard(
              padding: const EdgeInsets.all(16),
              radius: AppRadii.cardLarge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PIPELINE STAGE',
                      style: AppText.eyebrow(AppColors.mutedLight)),
                  const SizedBox(height: 14),
                  _StageTracker(stages: _stages, formations: formations),
                  const SizedBox(height: 14),
                  // Count per stage
                  Row(
                    children: [
                      for (final s in _stages) ...[
                        Expanded(
                          child: Center(
                            child: Text(
                              _countForStage(formations, s).toString(),
                              style: AppText.sans(
                                size: 12,
                                weight: FontWeight.w700,
                                color: _countForStage(formations, s) > 0
                                    ? AppColors.goldText
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Forming funds list ─────────────────────────────
            SectionHead(
              'Forming Funds',
              trailing: async.isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.goldTextSoft),
                      ),
                    )
                  : Text(
                      '${formations.length}',
                      style:
                          AppText.sans(size: 13, color: AppColors.mutedLight),
                    ),
            ),
            AppCard(
              noPadding: true,
              radius: AppRadii.card,
              child: Column(
                children: [
                  for (int i = 0; i < formations.length; i++)
                    _FormationRow(
                      seed: formations[i],
                      isLast: i == formations.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Summary metrics ────────────────────────────────
            _FormationSummaryCard(formations: formations),
          ],
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: GoldFab(
            icon: Icons.add,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  int _countForStage(List<_FormationSeed> fs, String stage) =>
      fs.where((f) => f.stage == stage).length;

  List<_FormationSeed> _rowsToFormations(List<Map<String, dynamic>> rows) {
    return rows.take(12).map((r) {
      final name =
          (r['name'] ?? r['fund_name'] ?? r['title'] ?? 'New Fund').toString();
      final stage = (r['stage'] ?? r['current_stage'] ?? 'Structuring').toString();
      final idx = _stages.indexOf(stage).clamp(0, _stages.length - 1);
      final closedPct =
          (r['closed_pct'] ?? r['pct_closed'] ?? r['raise_pct'] ?? 0.0) as num;
      final target =
          (r['target_size'] ?? r['target'] ?? r['amount'] ?? 100e6) as num;
      return _FormationSeed(
        name: name,
        stage: stage,
        stageIndex: idx,
        closedPct: closedPct.toDouble().clamp(0, 1),
        targetSize: target.toDouble(),
      );
    }).toList();
  }
}

// ── Stage tracker widget ──────────────────────────────────────────────────────

class _StageTracker extends StatelessWidget {
  final List<String> stages;
  final List<_FormationSeed> formations;

  const _StageTracker({required this.stages, required this.formations});

  @override
  Widget build(BuildContext context) {
    // Highest active stage index across all formations
    final maxActive = formations.isEmpty
        ? -1
        : formations.map((f) => f.stageIndex).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                // Dot
                _StageDot(
                  active: i <= maxActive,
                  current: i == maxActive,
                  label: stages[i],
                ),
              ],
            ),
          ),
          if (i != stages.length - 1)
            Expanded(
              flex: 0,
              child: Container(
                width: 28,
                height: 2,
                color: i < maxActive
                    ? AppColors.gold500
                    : AppColors.hairline,
              ),
            ),
        ],
      ],
    );
  }
}

class _StageDot extends StatelessWidget {
  final bool active;
  final bool current;
  final String label;

  const _StageDot({
    required this.active,
    required this.current,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: active ? AppColors.goldGradient : null,
            color: active ? null : AppColors.hairlineSoft,
            border: current
                ? Border.all(
                    color: AppColors.gold300,
                    width: 2,
                  )
                : null,
            boxShadow: current
                ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: active
              ? Icon(
                  current ? Icons.radio_button_checked : Icons.check,
                  size: 14,
                  color: AppColors.goldInk,
                )
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.sans(
            size: 9.5,
            color: active ? AppColors.goldText : AppColors.muted,
            weight: active ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Formation row ─────────────────────────────────────────────────────────────

class _FormationRow extends StatelessWidget {
  final _FormationSeed seed;
  final bool isLast;

  const _FormationRow({required this.seed, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.hairlineSoft)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlyphTile(
                  icon: Icons.business_center_rounded,
                  color: AppColors.goldText,
                  bg: AppColors.gold500.withValues(alpha: 0.10),
                  size: 40,
                  radius: 12,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seed.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.sans(size: 14, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatCompactCurrency(seed.targetSize)} target',
                        style: AppText.sans(
                            size: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StageLabel(stage: seed.stage),
                    const SizedBox(height: 4),
                    Text(
                      '${(seed.closedPct * 100).toStringAsFixed(0)}% closed',
                      style: AppText.sans(
                        size: 11,
                        color: AppColors.goldText,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Raise progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: seed.closedPct,
                minHeight: 5,
                backgroundColor: AppColors.hairline,
                valueColor: AlwaysStoppedAnimation(
                  seed.closedPct >= 0.75
                      ? AppColors.green
                      : AppColors.gold500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCompactCurrency(seed.targetSize * seed.closedPct),
                  style: AppText.sans(size: 10.5, color: AppColors.muted),
                ),
                Text(
                  formatCompactCurrency(seed.targetSize),
                  style: AppText.sans(size: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageLabel extends StatelessWidget {
  final String stage;

  const _StageLabel({required this.stage});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (stage) {
      case 'Raising':
        color = AppColors.goldTextSoft;
        bg = AppColors.gold500.withValues(alpha: 0.14);
      case 'Closing':
        color = AppColors.green;
        bg = AppColors.green.withValues(alpha: 0.12);
      case 'Docs':
        color = AppColors.blue;
        bg = AppColors.blue.withValues(alpha: 0.12);
      default: // Structuring
        color = AppColors.muted;
        bg = AppColors.hairlineSoft;
    }
    return StatusPill(label: stage, color: color, bg: bg);
  }
}

// ── Formation summary card ────────────────────────────────────────────────────

class _FormationSummaryCard extends StatelessWidget {
  final List<_FormationSeed> formations;

  const _FormationSummaryCard({required this.formations});

  @override
  Widget build(BuildContext context) {
    final totalTarget =
        formations.fold<double>(0, (s, f) => s + f.targetSize);
    final totalClosed = formations.fold<double>(
        0, (s, f) => s + f.targetSize * f.closedPct);
    final overallPct = totalTarget > 0 ? totalClosed / totalTarget : 0.0;

    return DarkCard(
      padding: const EdgeInsets.all(20),
      radius: AppRadii.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RAISE SUMMARY',
              style: AppText.eyebrow(AppColors.mutedOnDark)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCurrency(totalClosed),
                style: AppText.serif(size: 26, color: AppColors.gold300),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'of ${formatCompactCurrency(totalTarget)}',
                  style: AppText.sans(
                      size: 12, color: AppColors.mutedOnDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallPct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.gold300),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(overallPct * 100).toStringAsFixed(0)}% of pipeline target raised across ${formations.length} funds',
            style: AppText.sans(size: 11.5, color: AppColors.mutedOnDark),
          ),
        ],
      ),
    );
  }
}
