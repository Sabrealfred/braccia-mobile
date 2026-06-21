import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ---------------------------------------------------------------------------
// Seed data helpers
// ---------------------------------------------------------------------------

class _ReconItem {
  final String id;
  final String description;
  final double amount;
  final String counterparty;
  final String status; // 'matched' | 'exception' | 'pending'
  const _ReconItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.counterparty,
    required this.status,
  });
}

const _kReconSeed = [
  _ReconItem(
    id: 'r1',
    description: 'Trade break — Helios Fund III',
    amount: 2_850_000,
    counterparty: 'Helios Capital Partners',
    status: 'exception',
  ),
  _ReconItem(
    id: 'r2',
    description: 'Dividend receipt — MSCI EM ETF',
    amount: 184_320,
    counterparty: 'Vanguard Asset Management',
    status: 'matched',
  ),
  _ReconItem(
    id: 'r3',
    description: 'FX settlement — EUR/USD 1.08',
    amount: 5_400_000,
    counterparty: 'Deutsche Bank AG',
    status: 'matched',
  ),
  _ReconItem(
    id: 'r4',
    description: 'Custody fee discrepancy Q3',
    amount: 12_750,
    counterparty: 'BNY Mellon Custody',
    status: 'exception',
  ),
  _ReconItem(
    id: 'r5',
    description: 'LP capital call — Braccia Fund II',
    amount: 10_000_000,
    counterparty: 'Braccia Fund II LP',
    status: 'pending',
  ),
  _ReconItem(
    id: 'r6',
    description: 'Interest accrual — Treasury MMF',
    amount: 64_880,
    counterparty: 'BlackRock TRF',
    status: 'matched',
  ),
  _ReconItem(
    id: 'r7',
    description: 'Margin call — Apex Credit Facility',
    amount: 750_000,
    counterparty: 'Apex Financial Services',
    status: 'exception',
  ),
  _ReconItem(
    id: 'r8',
    description: 'Subscription proceeds — Growth Fund',
    amount: 3_200_000,
    counterparty: 'Meridian Group Holdings',
    status: 'pending',
  ),
];

class _ComplianceCase {
  final String id;
  final String clientName;
  final String caseType; // KYC | AML | PEP | Sanctions
  final String status; // 'cleared' | 'review' | 'pending'
  final String openedAt;
  final bool isHighAlert;
  const _ComplianceCase({
    required this.id,
    required this.clientName,
    required this.caseType,
    required this.status,
    required this.openedAt,
    this.isHighAlert = false,
  });
}

final _kComplianceSeed = [
  const _ComplianceCase(
    id: 'c1',
    clientName: 'Atlas Mining Ltd',
    caseType: 'PEP',
    status: 'review',
    openedAt: '2026-06-19T09:14:00Z',
    isHighAlert: true,
  ),
  const _ComplianceCase(
    id: 'c2',
    clientName: 'Quantum Capital Group',
    caseType: 'KYC',
    status: 'cleared',
    openedAt: '2026-06-15T14:30:00Z',
  ),
  const _ComplianceCase(
    id: 'c3',
    clientName: 'Meridian International SA',
    caseType: 'Sanctions',
    status: 'review',
    openedAt: '2026-06-20T08:45:00Z',
    isHighAlert: true,
  ),
  const _ComplianceCase(
    id: 'c4',
    clientName: 'Helios Capital Partners',
    caseType: 'AML',
    status: 'pending',
    openedAt: '2026-06-18T11:00:00Z',
  ),
  const _ComplianceCase(
    id: 'c5',
    clientName: 'Nova Infrastructure Fund',
    caseType: 'KYC',
    status: 'cleared',
    openedAt: '2026-06-10T16:20:00Z',
  ),
  const _ComplianceCase(
    id: 'c6',
    clientName: 'Apex Financial Services',
    caseType: 'AML',
    status: 'pending',
    openedAt: '2026-06-21T07:30:00Z',
  ),
];

// ---------------------------------------------------------------------------
// ReconBody
// ---------------------------------------------------------------------------

/// Reconciliation module body — trade breaks, matched settlements, recoverable
/// amounts. Rendered inside ModuleScreen's frame (no Scaffold/header).
class ReconBody extends ConsumerStatefulWidget {
  const ReconBody({super.key});

  @override
  ConsumerState<ReconBody> createState() => _ReconBodyState();
}

class _ReconBodyState extends ConsumerState<ReconBody> {
  String _filter = 'All'; // All | Exceptions | Matched

  List<_ReconItem> _fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _kReconSeed;
    return rows.map((r) {
      return _ReconItem(
        id: (r['id'] ?? '').toString(),
        description:
            (r['description'] ?? r['title'] ?? r['name'] ?? 'Break').toString(),
        amount: (num.tryParse((r['amount'] ?? r['deal_value'] ?? 0).toString()) ?? 0)
            .toDouble(),
        counterparty: (r['counterparty'] ?? r['client'] ?? '—').toString(),
        status: (r['status'] ?? 'pending').toString().toLowerCase(),
      );
    }).toList();
  }

  List<_ReconItem> _applyFilter(List<_ReconItem> items) {
    switch (_filter) {
      case 'Exceptions':
        return items.where((i) => i.status == 'exception').toList();
      case 'Matched':
        return items.where((i) => i.status == 'matched').toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tableProvider('reconciliations'));

    return async.when(
      loading: () => const LoadingState(),
      error: (_, _) => _buildContent(_kReconSeed),
      data: (rows) => _buildContent(_fromRows(rows)),
    );
  }

  Widget _buildContent(List<_ReconItem> allItems) {
    final matched = allItems.where((i) => i.status == 'matched').length;
    final exceptions = allItems.where((i) => i.status == 'exception').length;
    final recoverable = allItems
        .where((i) => i.status == 'exception')
        .fold<double>(0, (s, i) => s + i.amount);

    final filtered = _applyFilter(allItems);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── KPI row ──────────────────────────────────────────
        _KpiRow(matched: matched, exceptions: exceptions, recoverable: recoverable),
        const SizedBox(height: 14),

        // ── Filter chips ─────────────────────────────────────
        _FilterChips(
          selected: _filter,
          options: const ['All', 'Exceptions', 'Matched'],
          onSelect: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 14),

        // ── Section head ─────────────────────────────────────
        SectionHead(
          'Breaks & Settlements',
          trailing: Text(
            '${filtered.length} items',
            style: AppText.sans(size: 11.5, color: AppColors.muted),
          ),
        ),

        // ── Exception list ───────────────────────────────────
        if (filtered.isEmpty)
          const EmptyStateView(
            message: 'No items match this filter',
            icon: Icons.check_circle_outline,
          )
        else
          AppCard(
            noPadding: true,
            radius: 18,
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++)
                  _ReconRow(
                    item: filtered[i],
                    isLast: i == filtered.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final int matched;
  final int exceptions;
  final double recoverable;
  const _KpiRow({
    required this.matched,
    required this.exceptions,
    required this.recoverable,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DarkCard(
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MATCHED', style: AppText.eyebrow(AppColors.mutedOnDark)),
                const SizedBox(height: 6),
                Text(
                  '$matched',
                  style: AppText.serif(size: 26, color: AppColors.ivory),
                ),
                const SizedBox(height: 2),
                Text(
                  'settlements',
                  style: AppText.sans(size: 10.5, color: AppColors.greenOnDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EXCEPTIONS',
                    style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text(
                  '$exceptions',
                  style: AppText.serif(
                      size: 26,
                      color: exceptions > 0 ? AppColors.red : AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'require action',
                  style: AppText.sans(
                      size: 10.5,
                      color: exceptions > 0
                          ? AppColors.red
                          : AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECOVERABLE',
                    style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text(
                  formatCompactCurrency(recoverable),
                  style: AppText.serif(size: 20, color: AppColors.goldText),
                ),
                const SizedBox(height: 2),
                Text(
                  'outstanding',
                  style: AppText.sans(size: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelect;
  const _FilterChips({
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opt = options[i];
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient:
                    isActive ? AppColors.goldGradient : null,
                color: isActive ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : AppColors.hairline,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                opt,
                style: AppText.sans(
                  size: 12.5,
                  color: isActive ? AppColors.goldInk : AppColors.muted,
                  weight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReconRow extends StatelessWidget {
  final _ReconItem item;
  final bool isLast;
  const _ReconRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isException = item.status == 'exception';
    final isPending = item.status == 'pending';

    Color pillColor;
    Color pillBg;
    String pillLabel;
    IconData glyphIcon;
    Color glyphColor;
    Color glyphBg;

    if (isException) {
      pillLabel = 'Exception';
      pillColor = AppColors.red;
      pillBg = AppColors.red.withValues(alpha: 0.10);
      glyphIcon = Icons.warning_amber_rounded;
      glyphColor = AppColors.red;
      glyphBg = AppColors.red.withValues(alpha: 0.08);
    } else if (isPending) {
      pillLabel = 'Pending';
      pillColor = AppColors.goldTextSoft;
      pillBg = AppColors.gold500.withValues(alpha: 0.14);
      glyphIcon = Icons.hourglass_top_rounded;
      glyphColor = AppColors.goldTextSoft;
      glyphBg = AppColors.gold300.withValues(alpha: 0.10);
    } else {
      pillLabel = 'Matched';
      pillColor = AppColors.green;
      pillBg = AppColors.green.withValues(alpha: 0.10);
      glyphIcon = Icons.check_circle_rounded;
      glyphColor = AppColors.green;
      glyphBg = AppColors.green.withValues(alpha: 0.08);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlyphTile(
            icon: glyphIcon,
            color: glyphColor,
            bg: glyphBg,
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  item.counterparty,
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      bg: pillBg,
                    ),
                    if (isException) ...[
                      const SizedBox(width: 8),
                      _ResolveButton(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatCompactCurrency(item.amount),
            style: AppText.serif(size: 15, color: AppColors.goldText),
          ),
        ],
      ),
    );
  }
}

class _ResolveButton extends StatefulWidget {
  @override
  State<_ResolveButton> createState() => _ResolveButtonState();
}

class _ResolveButtonState extends State<_ResolveButton> {
  bool _resolving = false;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () async {
        if (_resolving) return;
        setState(() => _resolving = true);
        // Optimistic: simulate async op
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() => _resolving = false);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppRadii.inner),
        ),
        child: _resolving
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
                ),
              )
            : Text(
                'Resolve',
                style: AppText.sans(
                  size: 11,
                  color: AppColors.goldInk,
                  weight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ComplianceBody
// ---------------------------------------------------------------------------

/// Compliance & Screening module body — open KYC/AML/PEP/Sanctions cases
/// with alert card for screening hits. Rendered inside ModuleScreen's frame.
class ComplianceBody extends ConsumerWidget {
  const ComplianceBody({super.key});

  List<_ComplianceCase> _fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return _kComplianceSeed;
    return rows.map((r) {
      return _ComplianceCase(
        id: (r['id'] ?? '').toString(),
        clientName:
            (r['client_name'] ?? r['name'] ?? r['full_name'] ?? 'Unknown')
                .toString(),
        caseType: (r['case_type'] ?? r['type'] ?? 'KYC').toString(),
        status: (r['status'] ?? 'pending').toString().toLowerCase(),
        openedAt: (r['opened_at'] ?? r['created_at'] ?? r['updated_at'] ?? '')
            .toString(),
        isHighAlert: ['pep', 'sanctions']
            .contains((r['case_type'] ?? '').toString().toLowerCase()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tableProvider('compliance_cases'));

    return async.when(
      loading: () => const LoadingState(),
      error: (_, _) => _buildContent(_kComplianceSeed),
      data: (rows) => _buildContent(_fromRows(rows)),
    );
  }

  Widget _buildContent(List<_ComplianceCase> cases) {
    final openCount = cases.where((c) => c.status != 'cleared').length;
    final screeningHits = cases
        .where((c) => ['pep', 'sanctions']
            .contains(c.caseType.toLowerCase()))
        .length;
    final cleared = cases.where((c) => c.status == 'cleared').length;

    final alertCases =
        cases.where((c) => c.isHighAlert && c.status == 'review').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── KPI row ──────────────────────────────────────────
        _ComplianceKpiRow(
          open: openCount,
          hits: screeningHits,
          cleared: cleared,
        ),
        const SizedBox(height: 14),

        // ── Screening alert card ──────────────────────────────
        if (alertCases.isNotEmpty) ...[
          _ScreeningAlertCard(cases: alertCases),
          const SizedBox(height: 14),
        ],

        // ── Case list ─────────────────────────────────────────
        SectionHead(
          'Active Cases',
          trailing: Text(
            '${cases.length} total',
            style: AppText.sans(size: 11.5, color: AppColors.muted),
          ),
        ),

        if (cases.isEmpty)
          const EmptyStateView(
            message: 'No compliance cases found',
            icon: Icons.verified_outlined,
          )
        else
          AppCard(
            noPadding: true,
            radius: 18,
            child: Column(
              children: [
                for (int i = 0; i < cases.length; i++)
                  _ComplianceCaseRow(
                    item: cases[i],
                    isLast: i == cases.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ComplianceKpiRow extends StatelessWidget {
  final int open;
  final int hits;
  final int cleared;
  const _ComplianceKpiRow({
    required this.open,
    required this.hits,
    required this.cleared,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DarkCard(
            radius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OPEN CASES',
                    style: AppText.eyebrow(AppColors.mutedOnDark)),
                const SizedBox(height: 6),
                Text(
                  '$open',
                  style: AppText.serif(
                    size: 26,
                    color: open > 0 ? AppColors.gold300 : AppColors.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'under review',
                  style: AppText.sans(
                      size: 10.5, color: AppColors.mutedOnDark),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCREENING',
                    style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text(
                  '$hits',
                  style: AppText.serif(
                    size: 26,
                    color: hits > 0 ? AppColors.red : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'hits flagged',
                  style: AppText.sans(
                    size: 10.5,
                    color: hits > 0 ? AppColors.red : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CLEARED',
                    style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text(
                  '$cleared',
                  style: AppText.serif(size: 26, color: AppColors.green),
                ),
                const SizedBox(height: 2),
                Text(
                  'this period',
                  style: AppText.sans(size: 10.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreeningAlertCard extends StatelessWidget {
  final List<_ComplianceCase> cases;
  const _ScreeningAlertCard({required this.cases});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  size: 16,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screening hit · review required',
                      style: AppText.sans(
                        size: 13,
                        color: AppColors.red,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'PEP / Sanctions match detected',
                      style: AppText.sans(size: 11, color: AppColors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in cases)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  MonogramTile(
                      initials: initialsOf(c.clientName), size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.clientName,
                          style: AppText.sans(
                              size: 12.5, weight: FontWeight.w600),
                        ),
                        Text(
                          c.caseType,
                          style: AppText.sans(
                              size: 10.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  _EscalateButton(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComplianceCaseRow extends StatelessWidget {
  final _ComplianceCase item;
  final bool isLast;
  const _ComplianceCaseRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Color pillColor;
    Color pillBg;
    String pillLabel;
    IconData glyphIcon;
    Color glyphColor;
    Color glyphBg;

    switch (item.status) {
      case 'cleared':
        pillLabel = 'Cleared';
        pillColor = AppColors.green;
        pillBg = AppColors.green.withValues(alpha: 0.10);
        glyphIcon = Icons.verified_rounded;
        glyphColor = AppColors.green;
        glyphBg = AppColors.green.withValues(alpha: 0.08);
      case 'review':
        pillLabel = 'Review';
        pillColor = AppColors.red;
        pillBg = AppColors.red.withValues(alpha: 0.10);
        glyphIcon = Icons.policy_rounded;
        glyphColor = AppColors.red;
        glyphBg = AppColors.red.withValues(alpha: 0.08);
      default:
        pillLabel = 'Pending';
        pillColor = AppColors.goldTextSoft;
        pillBg = AppColors.gold500.withValues(alpha: 0.14);
        glyphIcon = Icons.pending_outlined;
        glyphColor = AppColors.goldTextSoft;
        glyphBg = AppColors.gold300.withValues(alpha: 0.10);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlyphTile(
            icon: glyphIcon,
            color: glyphColor,
            bg: glyphBg,
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _CaseTypePill(type: item.caseType),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo(item.openedAt),
                      style:
                          AppText.sans(size: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      bg: pillBg,
                    ),
                    if (item.status == 'review') ...[
                      const SizedBox(width: 6),
                      _ApproveButton(),
                      const SizedBox(width: 6),
                      _EscalateButton(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseTypePill extends StatelessWidget {
  final String type;
  const _CaseTypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (type.toLowerCase()) {
      case 'pep':
        color = AppColors.red;
        bg = AppColors.red.withValues(alpha: 0.10);
      case 'sanctions':
        color = AppColors.redOnDark;
        bg = AppColors.red.withValues(alpha: 0.14);
      case 'aml':
        color = AppColors.blue;
        bg = AppColors.blue.withValues(alpha: 0.10);
      default: // KYC
        color = AppColors.purple;
        bg = AppColors.purple.withValues(alpha: 0.10);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.inner),
      ),
      child: Text(
        type,
        style: AppText.sans(
            size: 10, color: color, weight: FontWeight.w700),
      ),
    );
  }
}

class _ApproveButton extends StatefulWidget {
  @override
  State<_ApproveButton> createState() => _ApproveButtonState();
}

class _ApproveButtonState extends State<_ApproveButton> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () async {
        if (_working) return;
        setState(() => _working = true);
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) setState(() => _working = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(AppRadii.inner),
        ),
        child: _working
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
                ),
              )
            : Text(
                'Approve',
                style: AppText.sans(
                  size: 11,
                  color: AppColors.goldInk,
                  weight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _EscalateButton extends StatefulWidget {
  @override
  State<_EscalateButton> createState() => _EscalateButtonState();
}

class _EscalateButtonState extends State<_EscalateButton> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () async {
        if (_working) return;
        setState(() => _working = true);
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) setState(() => _working = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.inner),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
        ),
        child: _working
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation(AppColors.red),
                ),
              )
            : Text(
                'Escalate',
                style: AppText.sans(
                  size: 11,
                  color: AppColors.red,
                  weight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
