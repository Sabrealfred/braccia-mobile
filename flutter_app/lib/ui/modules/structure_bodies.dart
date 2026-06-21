import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seed / demo data helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A single node in the ownership tree.
class _EntityNode {
  final String name;
  final String type; // Holdco | Opco | SPV | Trust | LLC | LP
  final String jurisdiction;
  final String? ownershipPct; // e.g. "100%", "51%"
  final List<_EntityNode> children;

  const _EntityNode({
    required this.name,
    required this.type,
    required this.jurisdiction,
    this.ownershipPct,
    this.children = const [],
  });
}

// Realistic Braccia Capital seed structure.
final List<_EntityNode> _seedTree = [
  _EntityNode(
    name: 'Braccia Holdings S.A.',
    type: 'Holdco',
    jurisdiction: 'LUX',
    children: [
      _EntityNode(
        name: 'Braccia Capital B.V.',
        type: 'Opco',
        jurisdiction: 'NL',
        ownershipPct: '100%',
        children: [
          _EntityNode(
            name: 'Braccia Fund I GP Ltd',
            type: 'SPV',
            jurisdiction: 'Cayman',
            ownershipPct: '100%',
          ),
          _EntityNode(
            name: 'Braccia Advisory GmbH',
            type: 'Opco',
            jurisdiction: 'DE',
            ownershipPct: '100%',
          ),
        ],
      ),
      _EntityNode(
        name: 'Braccia SPV Malta Ltd',
        type: 'SPV',
        jurisdiction: 'MT',
        ownershipPct: '100%',
        children: [
          _EntityNode(
            name: 'Atlas Royalties Trust',
            type: 'Trust',
            jurisdiction: 'Cayman',
            ownershipPct: '75%',
          ),
        ],
      ),
      _EntityNode(
        name: 'Braccia US LLC',
        type: 'LLC',
        jurisdiction: 'DE (USA)',
        ownershipPct: '80%',
      ),
    ],
  ),
];

// Flat list derived from the seed tree for the "Entity List" section.
List<_EntityNode> _flattenTree(List<_EntityNode> nodes) {
  final result = <_EntityNode>[];
  for (final n in nodes) {
    result.add(n);
    result.addAll(_flattenTree(n.children));
  }
  return result;
}

_EntityNode _entityFromClient(Client c) => _EntityNode(
      name: c.name,
      type: c.raw['entity_type'] as String? ?? 'Entity',
      jurisdiction: c.raw['jurisdiction'] as String? ?? c.industry ?? '—',
      ownershipPct: c.raw['ownership_pct'] as String?,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio seed data
// ─────────────────────────────────────────────────────────────────────────────

class _Allocation {
  final String label;
  final double fraction; // 0..1
  final Color color;
  final Color onColor;
  final double value; // USD

  const _Allocation({
    required this.label,
    required this.fraction,
    required this.color,
    required this.onColor,
    required this.value,
  });
}

class _Holding {
  final String name;
  final String assetClass;
  final double value;
  final double weight; // 0..1

  const _Holding({
    required this.name,
    required this.assetClass,
    required this.value,
    required this.weight,
  });
}

const _seedTotal = 487_300_000.0;

final List<_Allocation> _seedAllocations = [
  _Allocation(
    label: 'Equities',
    fraction: 0.42,
    color: AppColors.gold500,
    onColor: AppColors.goldText,
    value: _seedTotal * 0.42,
  ),
  _Allocation(
    label: 'Fixed Income',
    fraction: 0.28,
    color: AppColors.blue,
    onColor: AppColors.blueOnDark,
    value: _seedTotal * 0.28,
  ),
  _Allocation(
    label: 'Alternatives',
    fraction: 0.22,
    color: AppColors.green,
    onColor: AppColors.greenOnDark,
    value: _seedTotal * 0.22,
  ),
  _Allocation(
    label: 'Cash',
    fraction: 0.08,
    color: AppColors.purple,
    onColor: AppColors.purpleOnDark,
    value: _seedTotal * 0.08,
  ),
];

final List<_Holding> _seedHoldings = [
  _Holding(
    name: 'Braccia Fund I LP',
    assetClass: 'Alternatives',
    value: 84_200_000,
    weight: 0.173,
  ),
  _Holding(
    name: 'MSCI World ETF',
    assetClass: 'Equities',
    value: 71_600_000,
    weight: 0.147,
  ),
  _Holding(
    name: 'Bund 2031 4.25%',
    assetClass: 'Fixed Income',
    value: 62_400_000,
    weight: 0.128,
  ),
  _Holding(
    name: 'S&P 500 Index',
    assetClass: 'Equities',
    value: 55_900_000,
    weight: 0.115,
  ),
  _Holding(
    name: 'US Treasury 10Y',
    assetClass: 'Fixed Income',
    value: 44_100_000,
    weight: 0.090,
  ),
  _Holding(
    name: 'Atlas Royalties Trust',
    assetClass: 'Alternatives',
    value: 23_500_000,
    weight: 0.048,
  ),
  _Holding(
    name: 'EUR/USD MMF',
    assetClass: 'Cash',
    value: 19_800_000,
    weight: 0.041,
  ),
  _Holding(
    name: 'EU Tech Growth Fund',
    assetClass: 'Equities',
    value: 18_400_000,
    weight: 0.038,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Type-badge color helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'holdco':
      return AppColors.goldText;
    case 'opco':
      return AppColors.blue;
    case 'spv':
      return AppColors.green;
    case 'trust':
      return AppColors.purple;
    case 'llc':
      return AppColors.muted;
    case 'lp':
      return AppColors.red;
    default:
      return AppColors.muted;
  }
}

Color _typeBg(String type) => _typeColor(type).withValues(alpha: 0.12);

Color _assetClassColor(String ac) {
  switch (ac.toLowerCase()) {
    case 'equities':
      return AppColors.goldText;
    case 'fixed income':
      return AppColors.blue;
    case 'alternatives':
      return AppColors.green;
    case 'cash':
      return AppColors.purple;
    default:
      return AppColors.muted;
  }
}

Color _assetClassBg(String ac) => _assetClassColor(ac).withValues(alpha: 0.12);

// ─────────────────────────────────────────────────────────────────────────────
// EntitiesBody
// ─────────────────────────────────────────────────────────────────────────────

class EntitiesBody extends ConsumerWidget {
  const EntitiesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildContent(context, [], useSeed: true),
      data: (clients) {
        final entities = clients
            .where((c) =>
                c.clientType?.toLowerCase() == 'entity' ||
                c.clientType?.toLowerCase() == 'corporate')
            .toList();
        return _buildContent(context, entities, useSeed: entities.isEmpty);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Client> entities, {
    required bool useSeed,
  }) {
    final treeNodes = useSeed ? _seedTree : <_EntityNode>[];
    final flatList = useSeed
        ? _flattenTree(_seedTree)
        : entities.map(_entityFromClient).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero summary ──────────────────────────────────────
        DarkCard(
          gradient: AppColors.heroHeaderGradient,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENTITIES', style: AppText.eyebrow(AppColors.mutedOnDark)),
                    const SizedBox(height: 6),
                    Text(
                      '${flatList.length}',
                      style: AppText.serif(size: 32, color: AppColors.ivory),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Legal entities under management',
                      style: AppText.sans(size: 11.5, color: AppColors.mutedOnDark),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: AppColors.gold300,
                  size: 26,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Ownership tree ────────────────────────────────────
        if (treeNodes.isNotEmpty) ...[
          const SectionHead('Ownership Structure'),
          AppCard(
            noPadding: true,
            radius: AppRadii.card,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final root in treeNodes)
                    _TreeNodeWidget(node: root, depth: 0, isLast: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Flat entity list ──────────────────────────────────
        SectionHead(
          'All Entities',
          trailing: Text(
            '${flatList.length} total',
            style: AppText.sans(size: 11.5, color: AppColors.muted),
          ),
        ),
        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < flatList.length; i++)
                _EntityRow(
                  node: flatList[i],
                  isLast: i == flatList.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tree node widget — recursive
// ─────────────────────────────────────────────────────────────────────────────

class _TreeNodeWidget extends StatelessWidget {
  final _EntityNode node;
  final int depth;
  final bool isLast;

  const _TreeNodeWidget({
    required this.node,
    required this.depth,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    const indentPerLevel = 20.0;
    const connectorW = 14.0;
    const lineColor = AppColors.hairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: depth == 0 ? 16.0 : depth * indentPerLevel + 4,
            right: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Connector lines for non-root nodes
              if (depth > 0) ...[
                Container(
                  width: connectorW,
                  height: 24,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: lineColor, width: 1.5),
                      bottom: BorderSide(color: lineColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Type badge icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _typeBg(node.type),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _typeIcon(node.type),
                  size: 15,
                  color: _typeColor(node.type),
                ),
              ),
              const SizedBox(width: 10),

              // Name + jurisdiction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 13,
                        weight: depth == 0
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      node.jurisdiction,
                      style: AppText.sans(size: 10.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),

              // Badges
              const SizedBox(width: 8),
              StatusPill(
                label: node.type,
                color: _typeColor(node.type),
                bg: _typeBg(node.type),
              ),
              if (node.ownershipPct != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.hairlineSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    node.ownershipPct!,
                    style: AppText.sans(
                        size: 10,
                        color: AppColors.muted,
                        weight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Separator line (not after last)
        if (!isLast || node.children.isNotEmpty)
          Container(
            height: 1,
            margin: EdgeInsets.only(
              left: depth == 0 ? 16.0 : depth * indentPerLevel + 4,
            ),
            color: AppColors.hairlineSoft,
          ),

        // Children
        for (int i = 0; i < node.children.length; i++)
          _TreeNodeWidget(
            node: node.children[i],
            depth: depth + 1,
            isLast: i == node.children.length - 1,
          ),
      ],
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'holdco':
        return Icons.corporate_fare;
      case 'opco':
        return Icons.business;
      case 'spv':
        return Icons.account_balance;
      case 'trust':
        return Icons.shield_outlined;
      case 'llc':
        return Icons.apartment;
      case 'lp':
        return Icons.people_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat entity row
// ─────────────────────────────────────────────────────────────────────────────

class _EntityRow extends StatelessWidget {
  final _EntityNode node;
  final bool isLast;

  const _EntityRow({required this.node, required this.isLast});

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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.heroHeaderGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 17,
              color: AppColors.gold300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  node.jurisdiction,
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusPill(
            label: node.type,
            color: _typeColor(node.type),
            bg: _typeBg(node.type),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PortfoliosBody
// ─────────────────────────────────────────────────────────────────────────────

// Local provider scoped to this file.
final _portfoliosProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('portfolios');
});

class PortfoliosBody extends ConsumerWidget {
  const PortfoliosBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_portfoliosProvider);

    return dataAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildContent(context, [], useSeed: true),
      data: (rows) => _buildContent(context, rows, useSeed: rows.isEmpty),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, dynamic>> rows, {
    required bool useSeed,
  }) {
    final allocations = useSeed ? _seedAllocations : _buildAllocations(rows);
    final holdings = useSeed ? _seedHoldings : _buildHoldings(rows);
    final total = useSeed
        ? _seedTotal
        : holdings.fold<double>(0, (s, h) => s + h.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero: total portfolio value ────────────────────────
        DarkCard(
          gradient: AppColors.heroHeaderGradient,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PORTFOLIO VALUE',
                style: AppText.eyebrow(AppColors.mutedOnDark),
              ),
              const SizedBox(height: 8),
              Text(
                formatCompactCurrency(total),
                style: AppText.serif(size: 38, color: AppColors.ivory),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    size: 12,
                    color: AppColors.greenOnDark,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '12.4% YTD · ${allocations.length} asset classes',
                    style:
                        AppText.sans(size: 11.5, color: AppColors.greenOnDark),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Mini sparkline showing historical monthly performance
              BarSparkline(
                values: const [
                  0.52, 0.61, 0.57, 0.72, 0.68, 0.79,
                  0.84, 0.88, 0.75, 0.92, 0.96, 1.0
                ],
                highlightCount: 3,
                height: 44,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Jan', style: AppText.sans(size: 9, color: AppColors.mutedOnDark)),
                  Text('Jun', style: AppText.sans(size: 9, color: AppColors.mutedOnDark)),
                  Text('Dec', style: AppText.sans(size: 9, color: AppColors.mutedOnDark)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Allocation breakdown ──────────────────────────────
        const SectionHead('Allocation by Asset Class'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          radius: AppRadii.card,
          child: Column(
            children: [
              for (final alloc in allocations) ...[
                _AllocationRow(alloc: alloc, total: total),
                if (alloc != allocations.last)
                  const SizedBox(height: 14),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Holdings list ─────────────────────────────────────
        SectionHead(
          'Holdings',
          trailing: Text(
            '${holdings.length} positions',
            style: AppText.sans(size: 11.5, color: AppColors.muted),
          ),
        ),
        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < holdings.length; i++)
                _HoldingRow(
                  holding: holdings[i],
                  isLast: i == holdings.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_Allocation> _buildAllocations(List<Map<String, dynamic>> rows) {
    // Attempt to aggregate by asset_class field if available.
    final totals = <String, double>{};
    for (final r in rows) {
      final cls = (r['asset_class'] ?? r['category'] ?? 'Other').toString();
      final val = double.tryParse((r['value'] ?? r['amount'] ?? 0).toString()) ?? 0;
      totals[cls] = (totals[cls] ?? 0) + val;
    }
    if (totals.isEmpty) return _seedAllocations;
    final grand = totals.values.fold<double>(0, (s, v) => s + v);
    if (grand == 0) return _seedAllocations;

    final colors = [
      AppColors.gold500,
      AppColors.blue,
      AppColors.green,
      AppColors.purple,
      AppColors.red,
    ];
    final onColors = [
      AppColors.goldText,
      AppColors.blueOnDark,
      AppColors.greenOnDark,
      AppColors.purpleOnDark,
      AppColors.redOnDark,
    ];
    final entries = totals.entries.toList();
    return [
      for (int i = 0; i < entries.length; i++)
        _Allocation(
          label: entries[i].key,
          fraction: entries[i].value / grand,
          color: colors[i % colors.length],
          onColor: onColors[i % onColors.length],
          value: entries[i].value,
        ),
    ];
  }

  List<_Holding> _buildHoldings(List<Map<String, dynamic>> rows) {
    final grand = rows.fold<double>(0, (s, r) {
      return s + (double.tryParse((r['value'] ?? r['amount'] ?? 0).toString()) ?? 0);
    });
    return rows.map((r) {
      final val = double.tryParse((r['value'] ?? r['amount'] ?? 0).toString()) ?? 0;
      return _Holding(
        name: (r['name'] ?? r['title'] ?? 'Holding').toString(),
        assetClass: (r['asset_class'] ?? r['category'] ?? '—').toString(),
        value: val,
        weight: grand > 0 ? val / grand : 0,
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Allocation row — label + horizontal bar + value
// ─────────────────────────────────────────────────────────────────────────────

class _AllocationRow extends StatelessWidget {
  final _Allocation alloc;
  final double total;

  const _AllocationRow({required this.alloc, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (alloc.fraction * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: alloc.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                alloc.label,
                style: AppText.sans(size: 13, weight: FontWeight.w600),
              ),
            ),
            Text(
              '$pct%',
              style: AppText.sans(
                  size: 12, color: AppColors.muted, weight: FontWeight.w500),
            ),
            const SizedBox(width: 10),
            Text(
              formatCompactCurrency(alloc.value),
              style: AppText.serif(size: 14, color: AppColors.goldText),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Horizontal progress bar
        LayoutBuilder(
          builder: (context, constraints) {
            final barW = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 7,
                  width: barW,
                  decoration: BoxDecoration(
                    color: alloc.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 7,
                  width: barW * alloc.fraction.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: alloc.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Holding row
// ─────────────────────────────────────────────────────────────────────────────

class _HoldingRow extends StatelessWidget {
  final _Holding holding;
  final bool isLast;

  const _HoldingRow({required this.holding, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final pct = (holding.weight * 100).toStringAsFixed(1);
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
          // Left accent bar showing weight
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: _assetClassColor(holding.assetClass),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                StatusPill(
                  label: holding.assetClass,
                  color: _assetClassColor(holding.assetClass),
                  bg: _assetClassBg(holding.assetClass),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCurrency(holding.value),
                style: AppText.serif(size: 15, color: AppColors.goldText),
              ),
              const SizedBox(height: 2),
              Text(
                '$pct%',
                style: AppText.sans(size: 11, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
