import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Daily landing — pipeline pulse + what needs action today.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final profile = ref.watch(profileProvider).asData?.value;
    final stats = ref.watch(dealsStatsProvider);
    final leads = ref.watch(openLeadsProvider);
    final deals = ref.watch(dealsProvider);

    return RefreshIndicator(
      color: AppColors.gold500,
      onRefresh: () async {
        ref.invalidate(dealsStatsProvider);
        ref.invalidate(openLeadsProvider);
        ref.invalidate(dealsProvider);
        ref.invalidate(upcomingTasksProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Dark hero section
          Container(
            decoration: const BoxDecoration(color: AppColors.onyx700),
            padding: EdgeInsets.fromLTRB(20, topPad + 18, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting(),
                              style: AppText.sans(
                                  size: 13, color: const Color(0xFF9A9BA1))),
                          const SizedBox(height: 3),
                          Text(
                            profile?.displayName ?? 'Welcome',
                            style: AppText.serif(
                                size: 25, color: AppColors.ivory),
                          ),
                        ],
                      ),
                    ),
                    _circleIcon(Icons.search, onTap: () => context.go('/more')),
                    const SizedBox(width: 9),
                    _circleIcon(Icons.notifications_none,
                        badge: true, onTap: () => context.go('/ai')),
                  ],
                ),
                const SizedBox(height: 20),
                _HeroPipelineCard(stats: stats),
                const SizedBox(height: 14),
                _KpiRow(stats: stats, leads: leads),
              ],
            ),
          ),
          // Light body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHead(
                  'Focus today',
                  trailing: GestureDetector(
                    onTap: () => context.go('/pipeline'),
                    child: Text('View all',
                        style: AppText.sans(
                            size: 12,
                            color: AppColors.goldText,
                            weight: FontWeight.w600)),
                  ),
                ),
                _FocusCards(deals: deals),
                const SizedBox(height: 18),
                _AiInsightCard(onTap: () => context.go('/ai')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon,
      {bool badge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.goldOnDark),
            if (badge)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.redOnDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.onyx700, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroPipelineCard extends StatelessWidget {
  final AsyncValue<({int activeCount, double pipelineValue})> stats;
  const _HeroPipelineCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.asData?.value;
    return DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIVE PIPELINE',
                  style: AppText.eyebrow(AppColors.muted)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A9D7F).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text('▲ 18% QoQ',
                    style: AppText.sans(
                        size: 11,
                        color: AppColors.greenOnDark,
                        weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data == null
                    ? '—'
                    : formatCompactCurrency(data.pipelineValue),
                style: AppText.serif(size: 42, color: AppColors.ivory, height: 0.9),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${data?.activeCount ?? 0} active',
                    style: AppText.sans(
                        size: 12, color: const Color(0xFF9A9BA1))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const BarSparkline(
            values: [0.38, 0.52, 0.44, 0.64, 0.58, 0.78, 0.92],
            highlightCount: 3,
          ),
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AsyncValue<({int activeCount, double pipelineValue})> stats;
  final AsyncValue<int> leads;
  const _KpiRow({required this.stats, required this.leads});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _kpi('42%', 'Win rate', AppColors.ivory),
        const SizedBox(width: 10),
        _kpi('${leads.asData?.value ?? 0}', 'Open leads', AppColors.ivory),
        const SizedBox(width: 10),
        _kpi('100%', 'Retention', AppColors.greenOnDark),
      ],
    );
  }

  Widget _kpi(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppText.serif(size: 21, color: color)),
            const SizedBox(height: 1),
            Text(label,
                style: AppText.sans(size: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _FocusCards extends StatelessWidget {
  final AsyncValue<List<Deal>> deals;
  const _FocusCards({required this.deals});

  @override
  Widget build(BuildContext context) {
    return deals.when(
      loading: () => const LoadingState(),
      error: (e, _) => _staticFocus(context),
      data: (list) {
        final top = list.where((d) => d.isActive).take(3).toList();
        if (top.isEmpty) return _staticFocus(context);
        return Column(
          children: [
            for (final d in top) ...[
              _FocusCard(
                color: d.stage == 'negotiation'
                    ? AppColors.redOnDark
                    : AppColors.goldText,
                bg: (d.stage == 'negotiation'
                        ? AppColors.redOnDark
                        : AppColors.gold500)
                    .withValues(alpha: 0.12),
                glyph: d.stage == 'negotiation' ? '!' : '◷',
                title: d.name,
                subtitle:
                    '${d.stage} · ${formatCompactCurrency(d.dealValue)}',
                onTap: () => context.push('/deal/${d.id}'),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _staticFocus(BuildContext context) {
    return Column(
      children: [
        _FocusCard(
          color: AppColors.redOnDark,
          bg: AppColors.redOnDark.withValues(alpha: 0.1),
          glyph: '!',
          title: 'Send revised LOI — Apollo',
          subtitle: 'Overdue · Quantum Capital · \$24M',
          onTap: () => context.go('/pipeline'),
        ),
        const SizedBox(height: 10),
        _FocusCard(
          color: AppColors.goldText,
          bg: AppColors.gold500.withValues(alpha: 0.12),
          glyph: '◷',
          title: '2 leads awaiting assignment',
          subtitle: 'Quantum Capital · Atlas Mining',
          onTap: () => context.go('/more'),
        ),
      ],
    );
  }
}

class _FocusCard extends StatelessWidget {
  final Color color;
  final Color bg;
  final String glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _FocusCard({
    required this.color,
    required this.bg,
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(glyph,
                style: TextStyle(
                    fontSize: 18, color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.ink)),
                const SizedBox(height: 1),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFC4C2BB)),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AiInsightCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.all(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D1F26), Color(0xFF15161B)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Text('✦',
                style: TextStyle(fontSize: 15, color: AppColors.goldInk)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI INSIGHT',
                    style: AppText.eyebrow(AppColors.goldOnDark)),
                const SizedBox(height: 4),
                Text(
                  '3 deals are stalled >14 days. Apollo needs the LOI to keep exclusivity through Q3.',
                  style: AppText.sans(
                      size: 12.5, color: const Color(0xFFCFD0D6), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
