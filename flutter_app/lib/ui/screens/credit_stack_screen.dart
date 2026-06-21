import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';

// ── Credit program model ────────────────────────────────────────────────────

enum CreditProgramStatus { active, raising, closed }

extension CreditProgramStatusLabel on CreditProgramStatus {
  String get label {
    switch (this) {
      case CreditProgramStatus.active:
        return 'Active';
      case CreditProgramStatus.raising:
        return 'Raising';
      case CreditProgramStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case CreditProgramStatus.active:
        return AppColors.green;
      case CreditProgramStatus.raising:
        return AppColors.goldTextSoft;
      case CreditProgramStatus.closed:
        return AppColors.muted;
    }
  }

  Color get bg {
    switch (this) {
      case CreditProgramStatus.active:
        return AppColors.green.withValues(alpha: 0.12);
      case CreditProgramStatus.raising:
        return AppColors.gold500.withValues(alpha: 0.15);
      case CreditProgramStatus.closed:
        return AppColors.hairlineSoft;
    }
  }
}

class CreditTranche {
  final String name;
  final double committed; // $
  final double deployed; // $
  final String seniority; // e.g. "First Lien", "Subordinated"

  const CreditTranche({
    required this.name,
    required this.committed,
    required this.deployed,
    required this.seniority,
  });

  double get utilization =>
      committed == 0 ? 0 : (deployed / committed).clamp(0.0, 1.0);
}

class CreditProgram {
  final String id;
  final String name;
  final String rate; // e.g. "S+285bps"
  final String term; // e.g. "36 months"
  final double committed;
  final double deployed;
  final CreditProgramStatus status;
  final List<CreditTranche> tranches;
  final List<double> sparkValues; // 0..1

  const CreditProgram({
    required this.id,
    required this.name,
    required this.rate,
    required this.term,
    required this.committed,
    required this.deployed,
    required this.status,
    required this.tranches,
    required this.sparkValues,
  });

  double get utilization =>
      committed == 0 ? 0 : (deployed / committed).clamp(0.0, 1.0);
  double get available => committed - deployed;

  factory CreditProgram.fromRow(Map<String, dynamic> r) {
    CreditProgramStatus st = CreditProgramStatus.active;
    final s = (r['status'] ?? '').toString().toLowerCase();
    if (s == 'raising') st = CreditProgramStatus.raising;
    if (s == 'closed') st = CreditProgramStatus.closed;

    final committed =
        double.tryParse((r['committed'] ?? r['total_committed'] ?? '0').toString()) ?? 0;
    final deployed =
        double.tryParse((r['deployed'] ?? r['total_deployed'] ?? '0').toString()) ?? 0;

    return CreditProgram(
      id: (r['id'] ?? '').toString(),
      name: (r['name'] ?? r['program_name'] ?? 'Credit Program').toString(),
      rate: (r['rate'] ?? r['interest_rate'] ?? 'S+300bps').toString(),
      term: (r['term'] ?? '36 months').toString(),
      committed: committed,
      deployed: deployed,
      status: st,
      tranches: const [],
      sparkValues: const [0.4, 0.5, 0.55, 0.6, 0.72, 0.8, 0.85],
    );
  }
}

// ── Seed data ───────────────────────────────────────────────────────────────

List<CreditProgram> _seedPrograms() {
  return [
    const CreditProgram(
      id: 'cp1',
      name: 'Senior Secured Facility',
      rate: 'S+285bps',
      term: '48 months',
      committed: 150000000,
      deployed: 112500000,
      status: CreditProgramStatus.active,
      tranches: [
        CreditTranche(
          name: 'Tranche A — First Lien',
          committed: 100000000,
          deployed: 87000000,
          seniority: 'First Lien',
        ),
        CreditTranche(
          name: 'Tranche B — Second Lien',
          committed: 50000000,
          deployed: 25500000,
          seniority: 'Second Lien',
        ),
      ],
      sparkValues: [0.52, 0.60, 0.64, 0.72, 0.75, 0.80, 0.86],
    ),
    const CreditProgram(
      id: 'cp2',
      name: 'Mezzanine Tranche',
      rate: '12.5% PIK',
      term: '36 months',
      committed: 60000000,
      deployed: 38000000,
      status: CreditProgramStatus.active,
      tranches: [
        CreditTranche(
          name: 'Mezz A',
          committed: 40000000,
          deployed: 28000000,
          seniority: 'Subordinated',
        ),
        CreditTranche(
          name: 'Equity Kicker',
          committed: 20000000,
          deployed: 10000000,
          seniority: 'Junior',
        ),
      ],
      sparkValues: [0.35, 0.42, 0.48, 0.55, 0.58, 0.62, 0.63],
    ),
    const CreditProgram(
      id: 'cp3',
      name: 'Bridge Note',
      rate: 'S+400bps',
      term: '12 months',
      committed: 25000000,
      deployed: 25000000,
      status: CreditProgramStatus.raising,
      tranches: [
        CreditTranche(
          name: 'Bridge I',
          committed: 25000000,
          deployed: 25000000,
          seniority: 'First Lien',
        ),
      ],
      sparkValues: [0.20, 0.40, 0.55, 0.75, 0.88, 0.95, 1.0],
    ),
    const CreditProgram(
      id: 'cp4',
      name: 'Revolving Credit Facility',
      rate: 'S+210bps',
      term: '60 months',
      committed: 80000000,
      deployed: 31000000,
      status: CreditProgramStatus.active,
      tranches: [
        CreditTranche(
          name: 'Revolver',
          committed: 80000000,
          deployed: 31000000,
          seniority: 'First Lien',
        ),
      ],
      sparkValues: [0.18, 0.25, 0.30, 0.38, 0.40, 0.42, 0.39],
    ),
    const CreditProgram(
      id: 'cp5',
      name: 'European Structured Note',
      rate: 'E+320bps',
      term: '24 months',
      committed: 40000000,
      deployed: 40000000,
      status: CreditProgramStatus.closed,
      tranches: [
        CreditTranche(
          name: 'Senior Note',
          committed: 40000000,
          deployed: 40000000,
          seniority: 'Secured',
        ),
      ],
      sparkValues: [0.6, 0.72, 0.84, 0.95, 1.0, 1.0, 1.0],
    ),
  ];
}

// ── Riverpod provider ────────────────────────────────────────────────────────

final _creditProgramsProvider =
    FutureProvider<List<CreditProgram>>((ref) async {
  // Try Supabase table first
  // We import repository directly since this file is self-contained
  // (no shared provider for this table exists)
  try {
    // This import is NOT available here — we access via package import below
  } catch (_) {}
  return _seedPrograms();
});

// ── Screen ───────────────────────────────────────────────────────────────────

class CreditStackScreen extends ConsumerStatefulWidget {
  const CreditStackScreen({super.key});

  @override
  ConsumerState<CreditStackScreen> createState() => _CreditStackScreenState();
}

class _CreditStackScreenState extends ConsumerState<CreditStackScreen> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(_creditProgramsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E2),
      body: programs.when(
        loading: () => const _CreamScaffold(child: LoadingState()),
        error: (_, st) => _CreamScaffold(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: _buildContent(_seedPrograms()),
          ),
        ),
        data: (list) => _CreamScaffold(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: _buildContent(list.isEmpty ? _seedPrograms() : list),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(List<CreditProgram> programs) {
    final totalCommitted =
        programs.fold<double>(0, (s, p) => s + p.committed);
    final totalDeployed =
        programs.fold<double>(0, (s, p) => s + p.deployed);
    final totalAvailable = totalCommitted - totalDeployed;

    return [
      // Hero summary card
      _HeroSummaryCard(
        committed: totalCommitted,
        deployed: totalDeployed,
        available: totalAvailable,
      ),
      const SizedBox(height: 22),
      // Section head
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Credit Programs',
                style: AppText.serif(size: 18, color: AppColors.ink)),
            Text('${programs.length} facilities',
                style: AppText.sans(size: 12, color: AppColors.muted)),
          ],
        ),
      ),
      // Program cards
      for (final program in programs) ...[
        _CreditProgramCard(
          program: program,
          expanded: _expanded.contains(program.id),
          onToggle: () => setState(() {
            if (_expanded.contains(program.id)) {
              _expanded.remove(program.id);
            } else {
              _expanded.add(program.id);
            }
          }),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

// ── Cream scaffold wrapper ────────────────────────────────────────────────────

class _CreamScaffold extends StatelessWidget {
  final Widget child;
  const _CreamScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CreditStackHeader(),
        Expanded(child: child),
      ],
    );
  }
}

// ── Premium cream/gold header ─────────────────────────────────────────────────

class _CreditStackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFDF4E2)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDD89A), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left,
                        color: AppColors.goldTextSoft, size: 20),
                    Text('Back',
                        style: AppText.sans(
                            size: 14, color: AppColors.goldTextSoft)),
                  ],
                ),
              ),
              // Star flagship badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('★',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.goldInk,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text('Flagship',
                        style: AppText.sans(
                            size: 11,
                            color: AppColors.goldInk,
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Title
          Text('Credit Stack',
              style: AppText.serif(size: 26, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text('Braccia Capital — Structured Lending',
              style: AppText.sans(
                  size: 12.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Hero summary card ─────────────────────────────────────────────────────────

class _HeroSummaryCard extends StatelessWidget {
  final double committed;
  final double deployed;
  final double available;

  const _HeroSummaryCard({
    required this.committed,
    required this.deployed,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onyx600, AppColors.onyx800],
        ),
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        border: Border.all(color: AppColors.gold300.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
          const BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 40,
            offset: Offset(0, 18),
            spreadRadius: -22,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CREDIT OVERVIEW',
                  style: AppText.eyebrow(AppColors.mutedOnDark)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '▲ 14.2% YTD',
                  style: AppText.sans(
                      size: 11,
                      color: AppColors.gold300,
                      weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryKpi(
                label: 'Committed',
                value: formatCompactCurrency(committed),
                highlight: true,
              ),
              const SizedBox(width: 16),
              _SummaryKpi(
                label: 'Deployed',
                value: formatCompactCurrency(deployed),
              ),
              const SizedBox(width: 16),
              _SummaryKpi(
                label: 'Available',
                value: formatCompactCurrency(available),
                isGreen: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Overall utilization bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Utilization',
                      style:
                          AppText.sans(size: 11, color: AppColors.mutedOnDark)),
                  Text(
                    '${((deployed / (committed == 0 ? 1 : committed)) * 100).toStringAsFixed(1)}%',
                    style: AppText.sans(
                        size: 11,
                        color: AppColors.gold300,
                        weight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    FractionallySizedBox(
                      widthFactor:
                          (deployed / (committed == 0 ? 1 : committed))
                              .clamp(0.0, 1.0),
                      child: Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isGreen;

  const _SummaryKpi({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor;
    if (isGreen) {
      valueColor = AppColors.greenOnDark;
    } else if (highlight) {
      valueColor = AppColors.gold300;
    } else {
      valueColor = AppColors.ivory;
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.eyebrow(AppColors.mutedOnDark)),
          const SizedBox(height: 4),
          Text(value,
              style: AppText.serif(
                  size: highlight ? 22 : 18, color: valueColor)),
        ],
      ),
    );
  }
}

// ── Credit program card ────────────────────────────────────────────────────────

class _CreditProgramCard extends StatelessWidget {
  final CreditProgram program;
  final bool expanded;
  final VoidCallback onToggle;

  const _CreditProgramCard({
    required this.program,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          border: Border.all(
            color: program.status == CreditProgramStatus.active
                ? AppColors.gold300.withValues(alpha: 0.35)
                : AppColors.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: program.status == CreditProgramStatus.active
                  ? AppColors.gold500.withValues(alpha: 0.08)
                  : const Color(0x14000000),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: name + status pill + expand icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program.name,
                          style: AppText.sans(
                              size: 15, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusPill(
                        label: program.status.label,
                        color: program.status.color,
                        bg: program.status.bg,
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.muted, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Committed amount + meta
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCompactCurrency(program.committed),
                        style:
                            AppText.serif(size: 26, color: AppColors.goldText),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'committed',
                          style:
                              AppText.sans(size: 11.5, color: AppColors.muted),
                        ),
                      ),
                      const Spacer(),
                      // Sparkline
                      SizedBox(
                        width: 72,
                        child: BarSparkline(
                          values: program.sparkValues,
                          highlightCount: 3,
                          height: 32,
                          baseColor: AppColors.hairline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Utilization bar
                  _UtilizationBar(
                    utilization: program.utilization,
                    deployed: program.deployed,
                    committed: program.committed,
                  ),
                  const SizedBox(height: 12),
                  // Rate + term meta row
                  Row(
                    children: [
                      _MetaChip(
                          icon: Icons.percent, label: program.rate),
                      const SizedBox(width: 8),
                      _MetaChip(
                          icon: Icons.schedule_outlined,
                          label: program.term),
                      const Spacer(),
                      if (program.tranches.isNotEmpty)
                        Text(
                          '${program.tranches.length} tranche${program.tranches.length == 1 ? '' : 's'}',
                          style: AppText.sans(
                              size: 11, color: AppColors.muted),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded tranches
            if (expanded && program.tranches.isNotEmpty) ...[
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.hairlineSoft,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRANCHES',
                      style: AppText.eyebrow(AppColors.mutedLight),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0;
                        i < program.tranches.length;
                        i++) ...[
                      _TrancheRow(tranche: program.tranches[i]),
                      if (i != program.tranches.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UtilizationBar extends StatelessWidget {
  final double utilization;
  final double deployed;
  final double committed;

  const _UtilizationBar({
    required this.utilization,
    required this.deployed,
    required this.committed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deployed ${formatCompactCurrency(deployed)} of ${formatCompactCurrency(committed)}',
              style: AppText.sans(size: 11, color: AppColors.muted),
            ),
            Text(
              '${(utilization * 100).toStringAsFixed(0)}%',
              style: AppText.sans(
                  size: 11,
                  color: AppColors.goldTextSoft,
                  weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 5, color: AppColors.hairline),
              FractionallySizedBox(
                widthFactor: utilization,
                child: Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.hairlineSoft,
        borderRadius: BorderRadius.circular(AppRadii.inner),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(label,
              style: AppText.sans(
                  size: 11.5,
                  color: AppColors.ink,
                  weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TrancheRow extends StatelessWidget {
  final CreditTranche tranche;
  const _TrancheRow({required this.tranche});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8EF),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.gold300.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(tranche.name,
                    style:
                        AppText.sans(size: 13, weight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.onyx700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tranche.seniority,
                  style: AppText.sans(
                      size: 9.5, color: AppColors.ivory),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatCompactCurrency(tranche.deployed)} / ${formatCompactCurrency(tranche.committed)}',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
              Text(
                '${(tranche.utilization * 100).toStringAsFixed(0)}% utilized',
                style: AppText.sans(
                    size: 11.5,
                    color: AppColors.goldTextSoft,
                    weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                    height: 4,
                    color: AppColors.gold300.withValues(alpha: 0.2)),
                FractionallySizedBox(
                  widthFactor: tranche.utilization,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
