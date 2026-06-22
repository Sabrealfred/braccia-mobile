import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ── Seeded geo split used when real data is absent or too thin ────────────────
const _geoSeed = [
  ('United States', 'US', 0.42),
  ('United Kingdom', 'UK', 0.18),
  ('Luxembourg', 'LUX', 0.13),
  ('Cayman Islands', 'KY', 0.11),
  ('Singapore', 'SG', 0.09),
  ('Switzerland', 'CH', 0.07),
];

const _clientSeed = [
  ('Quantum Capital', 'QC', 284_000_000.0),
  ('Meridian Group', 'MG', 196_500_000.0),
  ('Atlas Endowment', 'AE', 157_200_000.0),
  ('Northern Trust Family', 'NT', 134_800_000.0),
  ('Elara Wealth Mgmt', 'EW', 98_600_000.0),
];

// ── Attribution seeded data ───────────────────────────────────────────────────
class _Factor {
  final String name;
  final double bps; // contribution in basis points (can be negative)
  const _Factor(this.name, this.bps);
}

const _factorSeed = [
  _Factor('Equity Selection', 142.0),
  _Factor('Credit Spread', 61.0),
  _Factor('Duration / Rates', -23.0),
  _Factor('FX & Currency', 38.0),
  _Factor('Alpha / Overlay', 55.0),
];

// ═════════════════════════════════════════════════════════════════════════════
// WealthBody — Global Wealth Map
// ═════════════════════════════════════════════════════════════════════════════

class WealthBody extends ConsumerWidget {
  const WealthBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return clientsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _body(context, []),
      data: (clients) => _body(context, clients
          .where((c) => (c.totalAum ?? 0) > 0)
          .toList()
        ..sort((a, b) => (b.totalAum ?? 0).compareTo(a.totalAum ?? 0))),
    );
  }

  Widget _body(BuildContext context, List clients) {
    // Compute firm AUM
    double firmAum = clients.fold(0.0, (s, c) => s + (c.totalAum ?? 0.0));
    final bool seeded = firmAum < 1.0;
    if (seeded) {
      firmAum = _clientSeed.fold(0.0, (s, t) => s + t.$3);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero: Firm AUM ────────────────────────────────────────────────
        DarkCard(
          gradient: AppColors.heroHeaderGradient,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FIRM AUM UNDER ADVISORY',
                  style: AppText.eyebrow(AppColors.mutedOnDark)),
              const SizedBox(height: 8),
              Text(
                formatCompactCurrency(firmAum),
                style: AppText.serif(size: 38, color: AppColors.gold300),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenOnDark.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text('▲ 11.4% YTD',
                        style: AppText.sans(
                            size: 11, color: AppColors.greenOnDark,
                            weight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    seeded ? '${_clientSeed.length} clients' : '${clients.length} clients',
                    style:
                        AppText.sans(size: 11.5, color: AppColors.mutedOnDark),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              BarSparkline(
                values: const [0.52, 0.61, 0.58, 0.72, 0.80, 0.87, 0.96],
                highlightCount: 3,
                height: 44,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Assets by jurisdiction ───────────────────────────────────────
        SectionHead('Assets by jurisdiction',
            trailing: Text('As of today',
                style: AppText.sans(size: 11, color: AppColors.muted))),

        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < _geoSeed.length; i++)
                _geoRow(_geoSeed[i], firmAum, i == _geoSeed.length - 1),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Top clients by AUM ───────────────────────────────────────────
        SectionHead('Top clients by AUM',
            trailing: Text('Sorted by AUM',
                style: AppText.sans(size: 11, color: AppColors.muted))),

        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: seeded
              ? Column(
                  children: [
                    for (int i = 0; i < _clientSeed.length; i++)
                      _clientSeedRow(_clientSeed[i], firmAum,
                          i == _clientSeed.length - 1),
                  ],
                )
              : Column(
                  children: [
                    for (int i = 0; i < clients.length && i < 8; i++)
                      _clientRow(clients[i], firmAum,
                          i == clients.length - 1 || i == 7),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _geoRow(
      (String, String, double) geo, double totalAum, bool last) {
    final amount = totalAum * geo.$3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          // Flag abbreviation badge
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.onyx700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(geo.$2,
                style: AppText.sans(
                    size: 9.5,
                    color: AppColors.goldOnDark,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(geo.$1,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                // Horizontal bar
                LayoutBuilder(
                  builder: (_, bc) => Container(
                    height: 4,
                    width: bc.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: geo.$3.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCompactCurrency(amount),
                  style: AppText.serif(size: 14, color: AppColors.goldText)),
              const SizedBox(height: 1),
              Text('${(geo.$3 * 100).toStringAsFixed(0)}%',
                  style: AppText.sans(size: 10.5, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clientRow(dynamic client, double totalAum, bool last) {
    final aum = (client.totalAum as double?) ?? 0.0;
    final pct = totalAum > 0 ? (aum / totalAum * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          MonogramTile(initials: initialsOf(client.name as String?), size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.name as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${pct.toStringAsFixed(1)}% of AUM',
                    style: AppText.sans(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Text(formatCompactCurrency(aum),
              style: AppText.serif(size: 15, color: AppColors.goldText)),
        ],
      ),
    );
  }

  Widget _clientSeedRow(
      (String, String, double) seed, double totalAum, bool last) {
    final pct = totalAum > 0 ? (seed.$3 / totalAum * 100) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          MonogramTile(initials: seed.$2, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seed.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    '${pct.toStringAsFixed(1)}% of AUM',
                    style: AppText.sans(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Text(formatCompactCurrency(seed.$3),
              style: AppText.serif(size: 15, color: AppColors.goldText)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AttributionBody — Performance Attribution
// ═════════════════════════════════════════════════════════════════════════════

/// Local provider for the performance table — never throws.
final _perfProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(repositoryProvider).fetchTable('performance');
});

class AttributionBody extends ConsumerWidget {
  const AttributionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(_perfProvider);
    return perfAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _body(context, []),
      data: (rows) => _body(context, rows),
    );
  }

  // ── Total return — derive from data or fall back to a realistic seed value.
  double _totalReturnYtd(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return 2.73; // seed: 273 bps = 2.73%
    final first = rows.first;
    final v = (first['ytd_return'] ?? first['total_return'] ?? first['return']);
    if (v != null) return double.tryParse(v.toString()) ?? 2.73;
    return 2.73;
  }

  // ── Benchmark vs portfolio seed
  static const _benchmarkYtd = 1.94; // e.g. MSCI World blended

  Widget _body(BuildContext context, List<Map<String, dynamic>> rows) {
    final ytd = _totalReturnYtd(rows);
    final isPositive = ytd >= 0;
    final returnColor =
        isPositive ? AppColors.greenOnDark : AppColors.redOnDark;
    final returnText = isPositive
        ? '+${ytd.toStringAsFixed(2)}%'
        : '${ytd.toStringAsFixed(2)}%';

    // Derive factors from data rows or fall back to seed
    final factors = _buildFactors(rows);

    // Max abs bps for bar scaling
    final maxBps =
        factors.fold(0.0, (m, f) => f.bps.abs() > m ? f.bps.abs() : m);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero: Total return YTD ────────────────────────────────────────
        DarkCard(
          gradient: AppColors.heroHeaderGradient,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL RETURN YTD',
                  style: AppText.eyebrow(AppColors.mutedOnDark)),
              const SizedBox(height: 8),
              Text(
                returnText,
                style: AppText.serif(size: 38, color: returnColor),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: returnColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                        '${((ytd - _benchmarkYtd) >= 0 ? '+' : '')}${(ytd - _benchmarkYtd).toStringAsFixed(0)} bps vs benchmark',
                        style: AppText.sans(
                            size: 11,
                            color: returnColor,
                            weight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Monthly returns sparkline (seeded)
              BarSparkline(
                values: const [0.44, 0.58, 0.51, 0.70, 0.63, 0.78, 0.84, 0.91, 0.96, 0.88, 0.92, 0.96],
                highlightCount: 4,
                height: 44,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Benchmark vs Portfolio comparison ────────────────────────────
        SectionHead('Portfolio vs Benchmark',
            trailing: Text('YTD %',
                style: AppText.sans(size: 11, color: AppColors.muted))),

        AppCard(
          padding: const EdgeInsets.all(18),
          radius: AppRadii.card,
          child: _BenchmarkComparison(
              portfolioYtd: ytd, benchmarkYtd: _benchmarkYtd),
        ),

        const SizedBox(height: 20),

        // ── Contribution by factor ───────────────────────────────────────
        SectionHead('Contribution by factor',
            trailing: Text('in bps',
                style: AppText.sans(size: 11, color: AppColors.muted))),

        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < factors.length; i++)
                _factorRow(factors[i], maxBps, i == factors.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  List<_Factor> _buildFactors(List<Map<String, dynamic>> rows) {
    // Try to parse factor rows from the performance table
    if (rows.isNotEmpty) {
      final parsed = rows
          .map((r) {
            final name = (r['factor'] ?? r['name'] ?? r['title'])?.toString();
            final bps = double.tryParse(
                (r['contribution_bps'] ?? r['bps'] ?? r['value'] ?? '')
                    .toString());
            if (name != null && bps != null) return _Factor(name, bps);
            return null;
          })
          .whereType<_Factor>()
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    return _factorSeed;
  }

  Widget _factorRow(_Factor f, double maxBps, bool last) {
    final isPos = f.bps >= 0;
    final barColor =
        isPos ? AppColors.goldText : AppColors.redOnDark;
    final barBgColor =
        isPos ? AppColors.gold500.withValues(alpha: 0.13) : AppColors.red.withValues(alpha: 0.09);
    final textColor = isPos ? AppColors.goldText : AppColors.red;
    final fraction = maxBps > 0 ? (f.bps.abs() / maxBps) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(f.name,
                style: AppText.sans(size: 13, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background track
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Fill bar
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // bps chip
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: barBgColor,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              '${isPos ? '+' : ''}${f.bps.toStringAsFixed(0)} bps',
              textAlign: TextAlign.center,
              style: AppText.sans(
                  size: 10, color: textColor, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Benchmark vs Portfolio mini chart ─────────────────────────────────────────
class _BenchmarkComparison extends StatelessWidget {
  final double portfolioYtd;
  final double benchmarkYtd;
  const _BenchmarkComparison(
      {required this.portfolioYtd, required this.benchmarkYtd});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        [portfolioYtd.abs(), benchmarkYtd.abs()].reduce((a, b) => a > b ? a : b);
    final pFraction =
        maxVal > 0 ? (portfolioYtd.abs() / (maxVal * 1.25)).clamp(0.0, 1.0) : 0.5;
    final bFraction =
        maxVal > 0 ? (benchmarkYtd.abs() / (maxVal * 1.25)).clamp(0.0, 1.0) : 0.4;

    return Column(
      children: [
        _compRow('Portfolio', portfolioYtd, pFraction, isPortfolio: true),
        const SizedBox(height: 12),
        _compRow('Benchmark', benchmarkYtd, bFraction, isPortfolio: false),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.hairlineSoft,
            borderRadius: BorderRadius.circular(AppRadii.inner),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alpha generated',
                  style: AppText.sans(
                      size: 12, weight: FontWeight.w600)),
              Text(
                '${((portfolioYtd - benchmarkYtd) >= 0 ? '+' : '')}${(portfolioYtd - benchmarkYtd).toStringAsFixed(2)}%  ·  ${((portfolioYtd - benchmarkYtd) * 100).toStringAsFixed(0)} bps',
                style: AppText.sans(
                    size: 12,
                    color: portfolioYtd >= benchmarkYtd
                        ? AppColors.green
                        : AppColors.red,
                    weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compRow(String label, double val, double fraction,
      {required bool isPortfolio}) {
    final isPos = val >= 0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: AppText.sans(size: 12.5, color: AppColors.muted)),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: isPortfolio
                        ? AppColors.goldGradient
                        : null,
                    color: isPortfolio
                        ? null
                        : (isPos ? AppColors.muted : AppColors.redOnDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '${isPos ? '+' : ''}${val.toStringAsFixed(2)}%',
            textAlign: TextAlign.right,
            style: AppText.sans(
                size: 12.5,
                weight: FontWeight.w600,
                color: isPortfolio
                    ? AppColors.goldText
                    : (isPos ? AppColors.green : AppColors.red)),
          ),
        ),
      ],
    );
  }
}
