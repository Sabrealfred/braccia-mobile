import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ─── Stage metadata ───────────────────────────────────────────────────────────

const _stageOrder = [
  'sourcing',
  'nda',
  'dd',
  'negotiation',
  'legal',
  'closed_won',
  'closed_lost',
];

String _stageLabel(String stage) {
  const labels = {
    'sourcing': 'SOURCING',
    'nda': 'NDA',
    'dd': 'DUE DILIGENCE',
    'negotiation': 'NEGOTIATION',
    'legal': 'LEGAL',
    'closed_won': 'CLOSED WON',
    'closed_lost': 'CLOSED LOST',
  };
  return labels[stage] ?? stage.toUpperCase();
}

Color _stageColor(String stage) {
  switch (stage) {
    case 'sourcing':
      return AppColors.blue;
    case 'nda':
      return AppColors.purple;
    case 'dd':
      return const Color(0xFF4B7EC4);
    case 'negotiation':
      return AppColors.goldTextSoft;
    case 'legal':
      return const Color(0xFF6B8F5E);
    case 'closed_won':
      return AppColors.green;
    case 'closed_lost':
      return AppColors.red;
    default:
      return AppColors.muted;
  }
}

// ─── Seed data ────────────────────────────────────────────────────────────────

final _seedDeals = [
  Deal(
    id: 'seed-1',
    name: 'Apollo Growth Acquisition',
    clientId: 'c1',
    stage: 'negotiation',
    status: 'active',
    dealType: 'M&A',
    dealValue: 24000000,
    probability: 72,
    expectedCloseDate: '2026-09-15',
    leadConsultant: 'Sofia Pereira',
    source: 'Direct',
    isActive: true,
  ),
  Deal(
    id: 'seed-2',
    name: 'Quantum Capital Series C',
    clientId: 'c2',
    stage: 'dd',
    status: 'active',
    dealType: 'Equity',
    dealValue: 55000000,
    probability: 58,
    expectedCloseDate: '2026-08-30',
    leadConsultant: 'Raj Mehta',
    source: 'Referral',
    isActive: true,
  ),
  Deal(
    id: 'seed-3',
    name: 'Atlas Mining Bridge Loan',
    clientId: 'c3',
    stage: 'legal',
    status: 'active',
    dealType: 'Debt',
    dealValue: 12500000,
    probability: 88,
    expectedCloseDate: '2026-07-10',
    leadConsultant: 'Maria Costa',
    source: 'Referral',
    isActive: true,
  ),
  Deal(
    id: 'seed-4',
    name: 'Meridian Group NDA Review',
    clientId: 'c4',
    stage: 'nda',
    status: 'active',
    dealType: 'M&A',
    dealValue: 38000000,
    probability: 35,
    expectedCloseDate: '2026-10-01',
    leadConsultant: 'Tom Walker',
    source: 'Cold Outreach',
    isActive: true,
  ),
  Deal(
    id: 'seed-5',
    name: 'Innovation Labs Pre-IPO',
    clientId: 'c5',
    stage: 'sourcing',
    status: 'active',
    dealType: 'Equity',
    dealValue: 120000000,
    probability: 20,
    expectedCloseDate: '2026-12-31',
    leadConsultant: 'Sofia Pereira',
    source: 'Conference',
    isActive: true,
  ),
  Deal(
    id: 'seed-6',
    name: 'Clearwater Fund Restructure',
    clientId: 'c6',
    stage: 'closed_won',
    status: 'active',
    dealType: 'Restructuring',
    dealValue: 17500000,
    probability: 100,
    expectedCloseDate: '2026-06-01',
    leadConsultant: 'Raj Mehta',
    source: 'Existing Client',
    isActive: true,
  ),
];

Map<String, List<Deal>> _buildSeedMap() {
  final map = <String, List<Deal>>{};
  for (final d in _seedDeals) {
    map.putIfAbsent(d.stage, () => []).add(d);
  }
  return map;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  String _selectedStage = 'all';
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pipelineAsync = ref.watch(pipelineByStageProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: RefreshIndicator(
        color: AppColors.gold500,
        onRefresh: () async {
          ref.invalidate(dealsProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: pipelineAsync.when(
          loading: () => Column(
            children: [
              _buildHeader(context, null),
              const Expanded(child: LoadingState()),
            ],
          ),
          error: (e, _) => Column(
            children: [
              _buildHeader(context, null),
              Expanded(
                child: ErrorStateView(
                  error: e,
                  onRetry: () => ref.invalidate(dealsProvider),
                ),
              ),
            ],
          ),
          data: (liveMap) {
            final map = liveMap.isEmpty ? _buildSeedMap() : liveMap;
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, map)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  sliver: _buildBody(map),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Map<String, List<Deal>>? map) {
    final topPad = MediaQuery.of(context).padding.top;
    final totalActive = map?.values.fold<int>(0, (s, l) => s + l.length) ?? 0;

    return Container(
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top row: title + icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pipeline',
                  style: AppText.serif(size: 24, color: AppColors.ivory)),
              Row(
                children: [
                  _iconBtn(Icons.sort, onTap: () {}),
                  const SizedBox(width: 6),
                  _iconBtn(Icons.tune_rounded, onTap: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          DarkSearchField(
            hint: 'Search deals…',
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 14),
          // Stage filter chips
          if (map != null) _buildChipRow(map, totalActive),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildChipRow(Map<String, List<Deal>> map, int totalActive) {
    final stages = ['all', ..._stageOrder.where((s) => map.containsKey(s))];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final stage = stages[i];
          final isAll = stage == 'all';
          final isActive = _selectedStage == stage;
          final count = isAll
              ? totalActive
              : (map[stage]?.length ?? 0);

          return GestureDetector(
            onTap: () => setState(() => _selectedStage = stage),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.goldGradient : null,
                color: isActive ? null : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAll ? 'All' : _stageLabel(stage),
                    style: AppText.sans(
                      size: 11.5,
                      color: isActive ? AppColors.goldInk : AppColors.mutedOnDark,
                      weight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.goldInk.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: AppText.sans(
                        size: 10,
                        color: isActive ? AppColors.goldInk : AppColors.ivory,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverList _buildBody(Map<String, List<Deal>> map) {
    // Decide which stages to show
    final stagesToShow = _selectedStage == 'all'
        ? _stageOrder.where((s) => map.containsKey(s)).toList()
        : [_selectedStage];

    final items = <Widget>[];
    for (final stage in stagesToShow) {
      var deals = map[stage] ?? [];
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        deals = deals.where((d) {
          return d.name.toLowerCase().contains(q) ||
              (d.leadConsultant?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
      if (deals.isEmpty) continue;

      final stageTotal = deals.fold<double>(0, (s, d) => s + (d.dealValue ?? 0));

      items.add(_StageHeader(
        stage: stage,
        count: deals.length,
        total: stageTotal,
      ));
      items.add(const SizedBox(height: 10));

      for (int i = 0; i < deals.length; i++) {
        items.add(_DealCard(deal: deals[i]));
        if (i < deals.length - 1) items.add(const SizedBox(height: 10));
      }
      items.add(const SizedBox(height: 22));
    }

    if (items.isEmpty) {
      items.add(const EmptyStateView(
        message: 'No deals match your filter.',
        icon: Icons.work_outline,
      ));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => items[i],
        childCount: items.length,
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
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
        child: Icon(icon, size: 17, color: AppColors.goldOnDark),
      ),
    );
  }
}

// ─── Stage Header ─────────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final String stage;
  final int count;
  final double total;
  const _StageHeader({
    required this.stage,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          _stageLabel(stage),
          style: AppText.eyebrow(AppColors.mutedLight),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: AppText.sans(
                size: 10, color: color, weight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Text(
          formatCompactCurrency(total),
          style: AppText.sans(
              size: 12.5,
              color: AppColors.goldText,
              weight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Deal Card ────────────────────────────────────────────────────────────────

class _DealCard extends StatelessWidget {
  final Deal deal;
  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final prob = deal.probability;
    final isOverdue = deal.expectedCloseDate != null &&
        DateTime.tryParse(deal.expectedCloseDate!)
                ?.isBefore(DateTime.now()) ==
            true;

    return AppCard(
      radius: 20,
      onTap: () => context.push('/deal/${deal.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + $ value
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.name,
                      style: AppText.sans(
                          size: 14.5, weight: FontWeight.w600, color: AppColors.ink),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (deal.leadConsultant != null) deal.leadConsultant!,
                        if (deal.dealType != null) deal.dealType!,
                      ].join(' · '),
                      style: AppText.sans(size: 11.5, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatCompactCurrency(deal.dealValue),
                style: AppText.serif(size: 20, color: AppColors.goldText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chips + avatars row
          Row(
            children: [
              if (prob != null)
                _chip(
                  '${prob.toStringAsFixed(0)}%',
                  AppColors.green,
                  AppColors.green.withValues(alpha: 0.1),
                ),
              if (prob != null) const SizedBox(width: 6),
              if (isOverdue)
                _chip(
                  'LOI overdue',
                  AppColors.red,
                  AppColors.red.withValues(alpha: 0.1),
                )
              else if (deal.expectedCloseDate != null)
                _chip(
                  'Close ${formatDate(deal.expectedCloseDate)}',
                  AppColors.muted,
                  AppColors.hairlineSoft,
                ),
              const Spacer(),
              _OwnerStack(
                initials:
                    initialsOf(deal.leadConsultant ?? deal.ownerId ?? 'BC'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppText.sans(
            size: 10.5, color: color, weight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}

// ─── Owner Avatar Stack ───────────────────────────────────────────────────────

class _OwnerStack extends StatelessWidget {
  final String initials;
  const _OwnerStack({required this.initials});

  static const _colors = [
    Color(0xFF5B7FA5),
    Color(0xFF7A5F7D),
    Color(0xFF4B8F6E),
  ];

  @override
  Widget build(BuildContext context) {
    // Show 1-2 overlapping avatars
    return SizedBox(
      width: 22 + 14.0,
      height: 22,
      child: Stack(
        children: [
          Positioned(
            left: 14,
            child: AvatarDot(
              initials: initials,
              color: _colors[0],
              size: 22,
            ),
          ),
          Positioned(
            left: 0,
            child: AvatarDot(
              color: _colors[1],
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
