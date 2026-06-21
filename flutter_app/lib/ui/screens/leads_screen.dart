// leads_screen.dart — Salesforce-grade Leads screen for Braccia Capital CRM.
// Owned exclusively by this agent; do NOT edit other shared files.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'leads_data.dart';

// ─── Filter chip enum ────────────────────────────────────────────────────────

enum _LeadFilter { all, newLead, unassigned, qualified, converted }

extension _LeadFilterLabel on _LeadFilter {
  String get label {
    switch (this) {
      case _LeadFilter.all:
        return 'All';
      case _LeadFilter.newLead:
        return 'New';
      case _LeadFilter.unassigned:
        return 'Unassigned';
      case _LeadFilter.qualified:
        return 'Qualified';
      case _LeadFilter.converted:
        return 'Converted';
    }
  }
}

// ─── Root screen ─────────────────────────────────────────────────────────────

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  _LeadFilter _filter = _LeadFilter.all;

  @override
  void initState() {
    super.initState();
    // Load leads on first mount (idempotent)
    Future.microtask(() => ref.read(leadsProvider.notifier).load());
  }

  List<LeadItem> _filtered(List<LeadItem> all) {
    switch (_filter) {
      case _LeadFilter.all:
        return all;
      case _LeadFilter.newLead:
        return all.where((l) => l.status == LeadStatus.newLead).toList();
      case _LeadFilter.unassigned:
        return all
            .where((l) => l.owner == null || l.owner!.isEmpty)
            .toList();
      case _LeadFilter.qualified:
        return all.where((l) => l.status == LeadStatus.qualified).toList();
      case _LeadFilter.converted:
        return all.where((l) => l.status == LeadStatus.converted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(leadsProvider);
    final kpi = ref.watch(leadsKpiProvider);
    final visible = _filtered(leads);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Dark header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: DarkHeader(
                  title: 'Leads',
                  accent: AppColors.gold300,
                  actions: [
                    _HeaderBtn(
                      icon: Icons.tune,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _HeaderBtn(
                      icon: Icons.search,
                      onTap: () {},
                    ),
                  ],
                  bottom: _KpiStrip(
                    open: kpi.open,
                    unassigned: kpi.unassigned,
                    convRate: kpi.convRate,
                  ),
                  bottomPadding: 20,
                ),
              ),

              // ── Filter chips ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FilterRow(
                  selected: _filter,
                  onSelect: (f) => setState(() => _filter = f),
                  leads: leads,
                ),
              ),

              // ── Lead list ────────────────────────────────────────────────
              visible.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateView(
                        message: 'No leads match this filter.',
                        icon: Icons.person_search,
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LeadCard(
                              lead: visible[i],
                              isLast: i == visible.length - 1,
                            ),
                          ),
                          childCount: visible.length,
                        ),
                      ),
                    ),
            ],
          ),

          // ── FAB ───────────────────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 100,
            child: GoldFab(
              onTap: () => _showAddLeadSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLeadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddLeadSheet(
        onAdd: (lead) {
          ref.read(leadsProvider.notifier).addLead(lead);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lead "${lead.name}" added.',
                  style: AppText.sans(size: 13, color: Colors.white)),
              backgroundColor: AppColors.onyx700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Header action button ─────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Icon(icon, size: 16, color: AppColors.goldOnDark),
      ),
    );
  }
}

// ─── KPI strip ───────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final int open;
  final int unassigned;
  final double convRate;

  const _KpiStrip({
    required this.open,
    required this.unassigned,
    required this.convRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _kpi('$open', 'Open leads', AppColors.ivory),
        const SizedBox(width: 10),
        _kpi('$unassigned', 'Unassigned', AppColors.goldOnDark),
        const SizedBox(width: 10),
        _kpi('${convRate.toStringAsFixed(0)}%', 'Conversion', AppColors.greenOnDark),
      ],
    );
  }

  Widget _kpi(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.serif(size: 22, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: AppText.sans(size: 10, color: AppColors.mutedOnDark)),
          ],
        ),
      ),
    );
  }
}

// ─── Filter row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _LeadFilter selected;
  final ValueChanged<_LeadFilter> onSelect;
  final List<LeadItem> leads;

  const _FilterRow({
    required this.selected,
    required this.onSelect,
    required this.leads,
  });

  int _count(_LeadFilter f) {
    switch (f) {
      case _LeadFilter.all:
        return leads.length;
      case _LeadFilter.newLead:
        return leads.where((l) => l.status == LeadStatus.newLead).length;
      case _LeadFilter.unassigned:
        return leads.where((l) => l.owner == null || l.owner!.isEmpty).length;
      case _LeadFilter.qualified:
        return leads.where((l) => l.status == LeadStatus.qualified).length;
      case _LeadFilter.converted:
        return leads.where((l) => l.status == LeadStatus.converted).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.ivory,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _LeadFilter.values
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f.label,
                      count: _count(f),
                      active: f == selected,
                      onTap: () => onSelect(f),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: active ? Colors.transparent : AppColors.hairline,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.sans(
                size: 12.5,
                weight: FontWeight.w600,
                color: active ? AppColors.goldInk : AppColors.ink,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.goldInk.withValues(alpha: 0.15)
                      : AppColors.hairlineSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppText.sans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: active ? AppColors.goldInk : AppColors.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Lead score ring ─────────────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const _ScoreRing({required this.score, this.size = 44});

  Color get _color {
    if (score >= 70) return AppColors.green;
    if (score >= 40) return AppColors.gold500;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(fraction: fraction, color: _color),
        child: Center(
          child: Text(
            '$score',
            style: AppText.sans(
              size: size * 0.28,
              weight: FontWeight.w700,
              color: _color,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 3;
    const stroke = 3.5;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─── Lead card (list row) ─────────────────────────────────────────────────────

class _LeadCard extends ConsumerWidget {
  final LeadItem lead;
  final bool isLast;

  const _LeadCard({required this.lead, required this.isLast});

  Color _pillColor(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return AppColors.blue;
      case LeadStatus.unassigned:
        return AppColors.goldTextSoft;
      case LeadStatus.qualified:
        return AppColors.green;
      case LeadStatus.converted:
        return AppColors.purple;
    }
  }

  Color _pillBg(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return AppColors.blue.withValues(alpha: 0.10);
      case LeadStatus.unassigned:
        return AppColors.gold500.withValues(alpha: 0.12);
      case LeadStatus.qualified:
        return AppColors.green.withValues(alpha: 0.10);
      case LeadStatus.converted:
        return AppColors.purple.withValues(alpha: 0.10);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leadsProvider.notifier);

    return AppCard(
      noPadding: true,
      onTap: () => _showDetailSheet(context, ref),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score ring
            _ScoreRing(score: lead.score),
            const SizedBox(width: 13),

            // Name / source
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                        size: 14, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _SourceLabel(source: lead.source),
                      if (lead.industry != null) ...[
                        const SizedBox(width: 6),
                        Text('·',
                            style: AppText.sans(
                                size: 11.5, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            lead.industry!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                                size: 11.5, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status pill + menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(
                  label: lead.status.label,
                  color: _pillColor(lead.status),
                  bg: _pillBg(lead.status),
                ),
                const SizedBox(height: 6),
                _TrailingMenu(
                  lead: lead,
                  onAssign: () {
                    notifier.assignToMe(lead.id, 'Me');
                    ScaffoldMessenger.of(context).showSnackBar(
                      _toast('Assigned to you'),
                    );
                  },
                  onConvert: () {
                    notifier.convertToClient(lead.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      _toast('"${lead.name}" converted to client'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SnackBar _toast(String msg) {
    return SnackBar(
      content: Text(msg,
          style: AppText.sans(size: 13, color: Colors.white)),
      backgroundColor: AppColors.onyx700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadDetailSheet(lead: lead, ref: ref),
    );
  }
}

// ─── Source label chip ───────────────────────────────────────────────────────

class _SourceLabel extends StatelessWidget {
  final String source;
  const _SourceLabel({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.hairlineSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: AppText.sans(
            size: 10.5, color: AppColors.mutedLight, weight: FontWeight.w500),
      ),
    );
  }
}

// ─── Trailing action menu ─────────────────────────────────────────────────────

class _TrailingMenu extends StatelessWidget {
  final LeadItem lead;
  final VoidCallback onAssign;
  final VoidCallback onConvert;

  const _TrailingMenu({
    required this.lead,
    required this.onAssign,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      offset: const Offset(0, 28),
      icon: const Icon(Icons.more_horiz,
          size: 18, color: AppColors.mutedLight),
      onSelected: (v) {
        if (v == 'assign') onAssign();
        if (v == 'convert') onConvert();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'assign',
          child: Row(children: [
            const Icon(Icons.person_add, size: 16, color: AppColors.blue),
            const SizedBox(width: 10),
            Text('Assign to me',
                style: AppText.sans(size: 13, weight: FontWeight.w500)),
          ]),
        ),
        PopupMenuItem(
          value: 'convert',
          enabled: lead.status != LeadStatus.converted,
          child: Row(children: [
            Icon(Icons.swap_horiz,
                size: 16,
                color: lead.status == LeadStatus.converted
                    ? AppColors.muted
                    : AppColors.green),
            const SizedBox(width: 10),
            Text(
              lead.status == LeadStatus.converted
                  ? 'Already converted'
                  : 'Convert to client',
              style: AppText.sans(
                size: 13,
                weight: FontWeight.w500,
                color: lead.status == LeadStatus.converted
                    ? AppColors.muted
                    : AppColors.ink,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ─── Lead detail bottom sheet ─────────────────────────────────────────────────

class _LeadDetailSheet extends StatelessWidget {
  final LeadItem lead;
  final WidgetRef ref;

  const _LeadDetailSheet({required this.lead, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(leadsProvider.notifier);
    final isConverted = lead.status == LeadStatus.converted;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Score ring + name
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(score: lead.score, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: AppText.serif(size: 20, color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      _SourceLabel(source: lead.source),
                      if (lead.industry != null) ...[
                        const SizedBox(width: 8),
                        Text(lead.industry!,
                            style: AppText.sans(
                                size: 12, color: AppColors.muted)),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                    label: 'Source', value: lead.source),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Est. Value',
                  value: lead.estValue != null
                      ? formatCompactCurrency(lead.estValue)
                      : '—',
                  highlight: true,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Owner',
                  value: (lead.owner?.isEmpty ?? true) ? 'Unassigned' : lead.owner!,
                  warn: lead.owner == null || lead.owner!.isEmpty,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Status',
                  value: lead.status.label,
                ),
                if (lead.industry != null) ...[
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Industry', value: lead.industry!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary actions
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  label: 'Assign to me',
                  icon: Icons.person_add_alt_1,
                  onTap: isConverted
                      ? null
                      : () {
                          Navigator.pop(context);
                          notifier.assignToMe(lead.id, 'Me');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Assigned to you',
                                  style: AppText.sans(
                                      size: 13, color: Colors.white)),
                              backgroundColor: AppColors.onyx700,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutlineBtn(
                  label: isConverted ? 'Converted' : 'Convert',
                  icon: isConverted ? Icons.check_circle : Icons.swap_horiz,
                  enabled: !isConverted,
                  onTap: isConverted
                      ? null
                      : () {
                          Navigator.pop(context);
                          notifier.convertToClient(lead.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${lead.name}" converted to client',
                                style: AppText.sans(
                                    size: 13, color: Colors.white),
                              ),
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool warn;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppText.sans(size: 12.5, color: AppColors.muted)),
        Text(
          value,
          style: highlight
              ? AppText.serif(size: 14, color: AppColors.goldText)
              : AppText.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: warn ? AppColors.goldTextSoft : AppColors.ink),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap ?? () {},
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.green.withValues(alpha: 0.08) : AppColors.hairlineSoft,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: enabled ? AppColors.green.withValues(alpha: 0.30) : AppColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17,
                color: enabled ? AppColors.green : AppColors.muted),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppText.sans(
                size: 13.5,
                weight: FontWeight.w600,
                color: enabled ? AppColors.green : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add lead bottom sheet ───────────────────────────────────────────────────

class _AddLeadSheet extends StatefulWidget {
  final ValueChanged<LeadItem> onAdd;
  const _AddLeadSheet({required this.onAdd});

  @override
  State<_AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends State<_AddLeadSheet> {
  final _nameCtrl = TextEditingController();
  String _source = 'Referral';
  bool _busy = false;

  static const _sources = [
    'Referral',
    'Inbound',
    'Conference',
    'LinkedIn',
    'Partner Intro',
    'Event',
    'Cold Outreach',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _busy = true);

    final lead = LeadItem(
      id: 'lead-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      source: _source,
      score: 50,
      status: LeadStatus.newLead,
    );

    // Small delay for UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onAdd(lead);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('New Lead', style: AppText.serif(size: 20, color: AppColors.ink)),
          const SizedBox(height: 16),

          // Name field
          _InputField(
            label: 'Company / Person',
            controller: _nameCtrl,
            hint: 'e.g. Quantum Capital',
          ),
          const SizedBox(height: 14),

          // Source picker
          Text('Source',
              style: AppText.sans(
                  size: 12, color: AppColors.muted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sources
                .map(
                  (s) => Pressable(
                    onTap: () => setState(() => _source = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: s == _source
                            ? AppColors.goldGradient
                            : null,
                        color: s == _source ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: s == _source
                              ? Colors.transparent
                              : AppColors.hairline,
                        ),
                      ),
                      child: Text(
                        s,
                        style: AppText.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: s == _source
                              ? AppColors.goldInk
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          GoldButton(
            label: 'Add Lead',
            icon: Icons.add,
            loading: _busy,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.sans(
                size: 12, color: AppColors.muted, weight: FontWeight.w600)),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: AppColors.hairline),
          ),
          child: TextField(
            controller: controller,
            style: AppText.sans(size: 14),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppText.sans(size: 14, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}
