import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Local providers
// ─────────────────────────────────────────────────────────────────────────────

final _altsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('alternatives');
});

final _custodiansProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('custodians');
});

// ─────────────────────────────────────────────────────────────────────────────
// Seed data helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FundRow {
  final String name;
  final int vintage;
  final double commitment; // $M
  final double nav; // $M
  final double multiple; // TVPI
  final double dpi;
  final double irr; // %

  const _FundRow({
    required this.name,
    required this.vintage,
    required this.commitment,
    required this.nav,
    required this.multiple,
    required this.dpi,
    required this.irr,
  });
}

const _seedFunds = [
  _FundRow(
    name: 'Braccia Buyout Fund I',
    vintage: 2018,
    commitment: 220,
    nav: 381,
    multiple: 1.93,
    dpi: 0.82,
    irr: 19.4,
  ),
  _FundRow(
    name: 'Braccia Growth Equity II',
    vintage: 2020,
    commitment: 180,
    nav: 267,
    multiple: 1.54,
    dpi: 0.28,
    irr: 22.1,
  ),
  _FundRow(
    name: 'Braccia Credit Opps III',
    vintage: 2021,
    commitment: 140,
    nav: 161,
    multiple: 1.21,
    dpi: 0.11,
    irr: 14.7,
  ),
  _FundRow(
    name: 'Braccia Real Assets IV',
    vintage: 2022,
    commitment: 95,
    nav: 102,
    multiple: 1.08,
    dpi: 0.00,
    irr: 8.3,
  ),
  _FundRow(
    name: 'Braccia Ventures V',
    vintage: 2023,
    commitment: 60,
    nav: 61,
    multiple: 1.02,
    dpi: 0.00,
    irr: 4.5,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// AltsBody — Alternatives (private markets)
// ─────────────────────────────────────────────────────────────────────────────

class AltsBody extends ConsumerWidget {
  const AltsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_altsProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => _AltsContent(rows: const []),
      data: (rows) => _AltsContent(rows: rows),
    );
  }
}

class _AltsContent extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _AltsContent({required this.rows});

  List<_FundRow> _resolveFunds() {
    if (rows.isEmpty) return _seedFunds;
    return rows.map((r) {
      return _FundRow(
        name: (r['name'] ?? r['fund_name'] ?? 'Fund').toString(),
        vintage: int.tryParse((r['vintage'] ?? '').toString()) ?? 2020,
        commitment:
            (num.tryParse((r['commitment'] ?? '').toString()) ?? 100).toDouble(),
        nav: (num.tryParse((r['nav'] ?? '').toString()) ?? 100).toDouble(),
        multiple:
            (num.tryParse((r['multiple'] ?? r['tvpi'] ?? '').toString()) ?? 1.0)
                .toDouble(),
        dpi: (num.tryParse((r['dpi'] ?? '').toString()) ?? 0.0).toDouble(),
        irr: (num.tryParse((r['irr'] ?? '').toString()) ?? 10.0).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final funds = _resolveFunds();

    // Portfolio-level aggregates
    final totalNav = funds.fold<double>(0, (s, f) => s + f.nav);
    final totalCommit = funds.fold<double>(0, (s, f) => s + f.commitment);
    final avgTvpi = totalCommit > 0 ? totalNav / totalCommit : 1.0;
    final avgDpi =
        funds.isNotEmpty ? funds.fold<double>(0, (s, f) => s + f.dpi) / funds.length : 0.0;
    final avgIrr =
        funds.isNotEmpty ? funds.fold<double>(0, (s, f) => s + f.irr) / funds.length : 0.0;

    // Distributions: sum DPI * commitment
    final totalDist =
        funds.fold<double>(0, (s, f) => s + f.dpi * f.commitment);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── KPI row ──────────────────────────────────────────
        _KpiRow(tvpi: avgTvpi, dpi: avgDpi, irr: avgIrr),
        const SizedBox(height: 14),

        // ── J-Curve chart card ────────────────────────────────
        AppCard(
          radius: AppRadii.cardLarge,
          noPadding: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('J-Curve — Cumulative Cashflow',
                        style: AppText.sans(
                            size: 13, weight: FontWeight.w600)),
                    StatusPill(
                      label: 'Vintages 2018–23',
                      color: AppColors.goldTextSoft,
                      bg: AppColors.gold500.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: CustomPaint(
                  size: const Size(double.infinity, 148),
                  painter: _JCurvePainter(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.gold500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Blended portfolio',
                        style: AppText.sans(
                            size: 10.5, color: AppColors.muted)),
                    const Spacer(),
                    Text('Year 1 → Year 10',
                        style:
                            AppText.sans(size: 10.5, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Fund / vintage list ───────────────────────────────
        SectionHead('Fund Portfolio',
            trailing: Text(
              '${funds.length} funds · ${formatCompactCurrency(totalCommit * 1e6)} committed',
              style: AppText.sans(size: 11.5, color: AppColors.muted),
            )),
        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < funds.length; i++)
                _FundTile(fund: funds[i], last: i == funds.length - 1),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Distributions mini-section ────────────────────────
        SectionHead('Distributions',
            trailing: Text(
              formatCompactCurrency(totalDist * 1e6),
              style: AppText.serif(size: 16, color: AppColors.goldText),
            )),
        AppCard(
          radius: AppRadii.card,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (final f in funds.where((f) => f.dpi > 0))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      MonogramTile(
                          initials: f.name.split(' ').take(2).map((w) => w[0]).join(),
                          size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sans(
                                    size: 12.5, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              'DPI ${f.dpi.toStringAsFixed(2)}x  ·  Vintage ${f.vintage}',
                              style: AppText.sans(
                                  size: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCompactCurrency(f.dpi * f.commitment * 1e6),
                        style:
                            AppText.serif(size: 14, color: AppColors.goldText),
                      ),
                    ],
                  ),
                ),
              if (funds.where((f) => f.dpi > 0).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No distributions yet — funds in early J-curve.',
                      style: AppText.sans(size: 12.5, color: AppColors.muted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── KPI row widget ────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final double tvpi;
  final double dpi;
  final double irr;
  const _KpiRow({required this.tvpi, required this.dpi, required this.irr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DarkCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            radius: AppRadii.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TVPI', style: AppText.eyebrow(AppColors.mutedOnDark)),
                const SizedBox(height: 6),
                Text('${tvpi.toStringAsFixed(2)}x',
                    style:
                        AppText.serif(size: 22, color: AppColors.gold300)),
                const SizedBox(height: 2),
                Text('Total value', style: AppText.sans(size: 10, color: AppColors.mutedOnDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            radius: AppRadii.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DPI', style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text('${dpi.toStringAsFixed(2)}x',
                    style: AppText.serif(size: 22, color: AppColors.goldText)),
                const SizedBox(height: 2),
                Text('Distributions', style: AppText.sans(size: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            radius: AppRadii.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IRR', style: AppText.eyebrow(AppColors.mutedLight)),
                const SizedBox(height: 6),
                Text('${irr.toStringAsFixed(1)}%',
                    style: AppText.serif(size: 22, color: AppColors.green)),
                const SizedBox(height: 2),
                Text('Net return', style: AppText.sans(size: 10, color: AppColors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fund tile ─────────────────────────────────────────────────────────────────

class _FundTile extends StatelessWidget {
  final _FundRow fund;
  final bool last;
  const _FundTile({required this.fund, required this.last});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          MonogramTile(
              initials: fund.name
                  .split(' ')
                  .take(2)
                  .map((w) => w[0])
                  .join(),
              size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fund.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  '${fund.vintage}  ·  ${formatCompactCurrency(fund.commitment * 1e6)} committed',
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCurrency(fund.nav * 1e6),
                style: AppText.serif(size: 15, color: AppColors.goldText),
              ),
              const SizedBox(height: 3),
              Text(
                '${fund.multiple.toStringAsFixed(2)}x TVPI',
                style: AppText.sans(size: 10.5, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── J-Curve CustomPainter ────────────────────────────────────────────────────

class _JCurvePainter extends CustomPainter {
  const _JCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const hPad = 32.0;
    const vPad = 16.0;

    // Normalised J-curve points (x 0..1, y: negative = dip, positive = gains)
    // Represents cumulative cashflow in % of commitment
    final points = <Offset>[
      const Offset(0.00, 0.00),
      const Offset(0.06, -0.08),
      const Offset(0.13, -0.20),
      const Offset(0.20, -0.32),
      const Offset(0.27, -0.38), // trough
      const Offset(0.33, -0.30),
      const Offset(0.42, -0.15),
      const Offset(0.50, 0.05),
      const Offset(0.58, 0.22),
      const Offset(0.67, 0.42),
      const Offset(0.75, 0.60),
      const Offset(0.83, 0.74),
      const Offset(0.91, 0.84),
      const Offset(1.00, 0.92),
    ];

    // Map normalised → canvas
    // y: -0.45 → bottom, +1.0 → top  (range 1.45)
    const yMin = -0.45;
    const yMax = 1.0;
    const yRange = yMax - yMin;

    Offset toCanvas(Offset p) {
      final cx = hPad + p.dx * (w - hPad * 2);
      final cy = vPad + (1 - (p.dy - yMin) / yRange) * (h - vPad * 2);
      return Offset(cx, cy);
    }

    final canvasPoints = points.map(toCanvas).toList();

    // Zero line
    final zeroY = toCanvas(const Offset(0, 0)).dy;
    final zeroPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(hPad, zeroY),
      Offset(w - hPad, zeroY),
      zeroPaint,
    );

    // Grid lines (horizontal, light)
    final gridPaint = Paint()
      ..color = AppColors.hairlineSoft.withValues(alpha: 0.5)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;
    for (final yVal in [-0.3, 0.3, 0.6, 0.9]) {
      final gy = toCanvas(Offset(0, yVal)).dy;
      canvas.drawLine(Offset(hPad, gy), Offset(w - hPad, gy), gridPaint);
    }

    // Filled area below the curve (gold with opacity for positive, muted for negative)
    final posPath = Path();
    final negPath = Path();
    posPath.moveTo(canvasPoints.first.dx, zeroY);
    negPath.moveTo(canvasPoints.first.dx, zeroY);

    for (int i = 0; i < canvasPoints.length; i++) {
      final pt = canvasPoints[i];
      if (i == 0) {
        posPath.lineTo(pt.dx, pt.dy);
        negPath.lineTo(pt.dx, pt.dy);
      } else {
        final prev = canvasPoints[i - 1];
        final cp1 = Offset(prev.dx + (pt.dx - prev.dx) / 2, prev.dy);
        final cp2 = Offset(prev.dx + (pt.dx - prev.dx) / 2, pt.dy);
        posPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pt.dx, pt.dy);
        negPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pt.dx, pt.dy);
      }
    }
    posPath.lineTo(canvasPoints.last.dx, zeroY);
    posPath.close();
    negPath.lineTo(canvasPoints.first.dx, zeroY);
    negPath.close();

    // Clip and fill positive (above zero) area in gold
    canvas.save();
    final posClip = Path()
      ..addRect(Rect.fromLTRB(0, 0, w, zeroY));
    canvas.clipPath(posClip);
    canvas.drawPath(
      posPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold300.withValues(alpha: 0.35),
            AppColors.gold500.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.restore();

    // Clip and fill negative (below zero) area in muted red
    canvas.save();
    final negClip = Path()
      ..addRect(Rect.fromLTRB(0, zeroY, w, h));
    canvas.clipPath(negClip);
    canvas.drawPath(
      negPath,
      Paint()
        ..color = AppColors.red.withValues(alpha: 0.12),
    );
    canvas.restore();

    // Build main cubic spline path for stroke
    final path = Path();
    path.moveTo(canvasPoints.first.dx, canvasPoints.first.dy);
    for (int i = 1; i < canvasPoints.length; i++) {
      final prev = canvasPoints[i - 1];
      final pt = canvasPoints[i];
      final cp1 = Offset(prev.dx + (pt.dx - prev.dx) / 2, prev.dy);
      final cp2 = Offset(prev.dx + (pt.dx - prev.dx) / 2, pt.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pt.dx, pt.dy);
    }

    // Shadow glow
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold500.withValues(alpha: 0.28)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main curve stroke
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.gold300, AppColors.gold500],
        ).createShader(Rect.fromLTWH(hPad, 0, w - hPad * 2, h))
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Trough marker dot
    final troughPt = toCanvas(const Offset(0.27, -0.38));
    canvas.drawCircle(
      troughPt,
      4,
      Paint()..color = AppColors.red.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      troughPt,
      2,
      Paint()..color = AppColors.surface,
    );

    // Current value marker (latest point)
    final endPt = canvasPoints.last;
    canvas.drawCircle(
      endPt,
      5,
      Paint()
        ..color = AppColors.gold300
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      endPt,
      5,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Year labels
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    for (int yr = 1; yr <= 10; yr += 3) {
      final x = toCanvas(Offset((yr - 1) / 9, 0)).dx;
      labelPaint
        ..text = TextSpan(
          text: 'Y$yr',
          style: TextStyle(
            fontSize: 8.5,
            color: AppColors.muted.withValues(alpha: 0.7),
            fontFamily: 'DM Sans',
          ),
        )
        ..layout(maxWidth: 30);
      labelPaint.paint(
          canvas, Offset(x - labelPaint.width / 2, h - vPad + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CustodiansBody — Custodian Hub
// ─────────────────────────────────────────────────────────────────────────────

class _CustodianRow {
  final String name;
  final double assets; // $B
  final int accounts;
  final String syncLabel;
  final bool synced;

  const _CustodianRow({
    required this.name,
    required this.assets,
    required this.accounts,
    required this.syncLabel,
    required this.synced,
  });
}

const _seedCustodians = [
  _CustodianRow(
    name: 'Fidelity Investments',
    assets: 0.482,
    accounts: 14,
    syncLabel: 'Synced 14m ago',
    synced: true,
  ),
  _CustodianRow(
    name: 'Charles Schwab',
    assets: 0.317,
    accounts: 9,
    syncLabel: 'Synced 1h ago',
    synced: true,
  ),
  _CustodianRow(
    name: 'J.P. Morgan Custody',
    assets: 0.256,
    accounts: 6,
    syncLabel: 'Re-auth needed',
    synced: false,
  ),
  _CustodianRow(
    name: 'BNY Mellon',
    assets: 0.185,
    accounts: 5,
    syncLabel: 'Synced 3h ago',
    synced: true,
  ),
];

class CustodiansBody extends ConsumerWidget {
  const CustodiansBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_custodiansProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => const _CustodiansContent(rows: []),
      data: (rows) => _CustodiansContent(rows: rows),
    );
  }
}

class _CustodiansContent extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  const _CustodiansContent({required this.rows});

  @override
  State<_CustodiansContent> createState() => _CustodiansContentState();
}

class _CustodiansContentState extends State<_CustodiansContent> {
  final Set<int> _syncing = {};

  List<_CustodianRow> _resolve() {
    if (widget.rows.isEmpty) return _seedCustodians;
    return widget.rows.map((r) {
      final synced = (r['sync_status'] ?? r['status'] ?? '')
              .toString()
              .toLowerCase()
              .contains('sync') ||
          (r['sync_status'] ?? '').toString().toLowerCase() == 'ok';
      return _CustodianRow(
        name: (r['name'] ?? r['custodian_name'] ?? 'Custodian').toString(),
        assets:
            (num.tryParse((r['assets'] ?? r['total_assets'] ?? '').toString()) ??
                    0.1)
                .toDouble(),
        accounts: int.tryParse((r['accounts'] ?? '').toString()) ?? 1,
        syncLabel: synced ? 'Synced recently' : 'Re-auth needed',
        synced: synced,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final custodians = _resolve();
    final totalAssets =
        custodians.fold<double>(0, (s, c) => s + c.assets);
    final totalAccounts =
        custodians.fold<int>(0, (s, c) => s + c.accounts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // ── Hero banner ───────────────────────────────────────
        DarkCard(
          gradient: AppColors.heroHeaderGradient,
          radius: AppRadii.cardLarge,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL ASSETS HELD',
                        style: AppText.eyebrow(AppColors.mutedOnDark)),
                    const SizedBox(height: 6),
                    Text(
                      formatCompactCurrency(totalAssets * 1e9),
                      style: AppText.serif(size: 28, color: AppColors.gold300),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalAccounts accounts synced across ${custodians.length} custodians',
                      style: AppText.sans(
                          size: 12, color: AppColors.mutedOnDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _CustodianPie(custodians: custodians),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Custodian list ────────────────────────────────────
        SectionHead('Custodians',
            trailing: Text(
              '${custodians.where((c) => c.synced).length} of ${custodians.length} synced',
              style: AppText.sans(size: 11.5, color: AppColors.muted),
            )),
        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < custodians.length; i++)
                _CustodianTile(
                  custodian: custodians[i],
                  index: i,
                  last: i == custodians.length - 1,
                  syncing: _syncing.contains(i),
                  onSync: () async {
                    setState(() => _syncing.add(i));
                    await Future<void>.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _syncing.remove(i));
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Add custodian CTA ─────────────────────────────────
        GoldButton(
          label: 'Connect New Custodian',
          icon: Icons.add_link_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}

// ── Custodian tile ────────────────────────────────────────────────────────────

class _CustodianTile extends StatelessWidget {
  final _CustodianRow custodian;
  final int index;
  final bool last;
  final bool syncing;
  final VoidCallback onSync;

  const _CustodianTile({
    required this.custodian,
    required this.index,
    required this.last,
    required this.syncing,
    required this.onSync,
  });

  // Distinctive icon per custodian index
  IconData _icon() {
    const icons = [
      Icons.account_balance_rounded,
      Icons.savings_rounded,
      Icons.corporate_fare_rounded,
      Icons.business_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _tint() {
    const tints = [
      Color(0xFFE8F0FE),
      Color(0xFFE6F4EA),
      Color(0xFFFFF3E0),
      Color(0xFFF3E5F5),
    ];
    return tints[index % tints.length];
  }

  Color _glyphColor() {
    const colors = [
      AppColors.blue,
      AppColors.green,
      AppColors.goldText,
      AppColors.purple,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlyphTile(
            icon: _icon(),
            color: _glyphColor(),
            bg: _tint(),
            size: 44,
            radius: 13,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(custodian.name,
                    style:
                        AppText.sans(size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${custodian.accounts} accounts',
                      style:
                          AppText.sans(size: 11.5, color: AppColors.muted),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: custodian.syncLabel,
                      color: custodian.synced
                          ? AppColors.green
                          : AppColors.red,
                      bg: custodian.synced
                          ? AppColors.green.withValues(alpha: 0.12)
                          : AppColors.red.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  formatCompactCurrency(custodian.assets * 1e9),
                  style:
                      AppText.serif(size: 17, color: AppColors.goldText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Sync now action
          Pressable(
            onTap: onSync,
            child: Container(
              width: 72,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairline),
                borderRadius: BorderRadius.circular(10),
                color: AppColors.ivory,
              ),
              child: syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.gold500),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sync_rounded,
                            size: 13, color: AppColors.goldText),
                        const SizedBox(width: 4),
                        Text('Sync',
                            style: AppText.sans(
                                size: 11.5,
                                color: AppColors.goldText,
                                weight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini pie chart for hero banner ───────────────────────────────────────────

class _CustodianPie extends StatelessWidget {
  final List<_CustodianRow> custodians;
  const _CustodianPie({required this.custodians});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: CustomPaint(
        painter: _PiePainter(custodians: custodians),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<_CustodianRow> custodians;
  const _PiePainter({required this.custodians});

  static const _sliceColors = [
    AppColors.gold300,
    AppColors.gold500,
    Color(0xFF7B97C2),
    Color(0xFFB09CC8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (custodians.isEmpty) return;
    final total = custodians.fold<double>(0, (s, c) => s + c.assets);
    if (total == 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 2;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < custodians.length; i++) {
      final sweep = (custodians[i].assets / total) * 2 * math.pi;
      final paint = Paint()
        ..color = _sliceColors[i % _sliceColors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }

    // Donut hole
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.52,
      Paint()..color = AppColors.onyx800,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
