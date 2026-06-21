import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/modules.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Category-adaptive screen opened from any hub tile. Renders one of three
/// baseline templates (KPI / Chat / List) backed by a Supabase table when
/// available, so every module opens something real.
class ModuleScreen extends ConsumerWidget {
  final String moduleId;
  const ModuleScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = moduleById(moduleId);
    final name = module?.label ?? moduleId;
    final accent = module?.accent ?? AppColors.gold500;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          DarkHeader(
            title: name,
            accent: accent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left,
                      color: AppColors.goldOnDark, size: 20),
                  Text('Apps',
                      style: AppText.sans(
                          size: 14, color: AppColors.goldOnDark)),
                ],
              ),
            ),
            actions: const [
              Icon(Icons.search, color: Color(0xFF9A9BA1), size: 18),
            ],
          ),
          Expanded(
            child: module == null
                ? EmptyStateView(message: 'Unknown module: $moduleId')
                : _body(context, ref, module),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppModule m) {
    switch (m.kind) {
      case ModuleKind.kpi:
        return _KpiTemplate(module: m);
      case ModuleKind.chat:
        return _ChatTemplate(module: m);
      case ModuleKind.list:
      case ModuleKind.bespoke:
        return _ListTemplate(module: m);
    }
  }
}

class _KpiTemplate extends ConsumerWidget {
  final AppModule module;
  const _KpiTemplate({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = module.table == null
        ? const AsyncValue.data(<Map<String, dynamic>>[])
        : ref.watch(tableProvider(module.table!));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: DarkCard(
                radius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL', style: AppText.eyebrow(AppColors.muted)),
                    const SizedBox(height: 6),
                    Text('\$1.24B',
                        style:
                            AppText.serif(size: 24, color: AppColors.ivory)),
                    const SizedBox(height: 2),
                    Text('▲ 9.4% YTD',
                        style: AppText.sans(
                            size: 10.5, color: AppColors.greenOnDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppCard(
                radius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THIS MONTH',
                        style: AppText.eyebrow(AppColors.mutedLight)),
                    const SizedBox(height: 6),
                    Text('\$42.8M', style: AppText.serif(size: 24)),
                    const SizedBox(height: 2),
                    Text('▲ 5 pts',
                        style: AppText.sans(
                            size: 10.5, color: AppColors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trend',
                      style: AppText.sans(
                          size: 12.5, weight: FontWeight.w600)),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.onyx700,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text('YTD',
                          style: AppText.sans(
                              size: 9.5, color: Colors.white)),
                    ),
                    const SizedBox(width: 4),
                    Text('QTD',
                        style:
                            AppText.sans(size: 9.5, color: AppColors.muted)),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              const _LightBars(
                  values: [0.40, 0.55, 0.48, 0.70, 0.82, 0.96]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        rows.when(
          loading: () => const LoadingState(),
          error: (e, _) => _placeholderList(),
          data: (data) => data.isEmpty
              ? _placeholderList()
              : AppCard(
                  noPadding: true,
                  radius: 18,
                  child: Column(
                    children: [
                      for (int i = 0; i < data.length && i < 8; i++)
                        _kpiRow(data[i], i == data.length - 1 || i == 7),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _kpiRow(Map<String, dynamic> r, bool last) {
    final title = (r['name'] ?? r['title'] ?? r['display_name'] ?? 'Item')
        .toString();
    final amount = r['deal_value'] ?? r['total_aum'] ?? r['amount'] ?? r['balance'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                        size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(timeAgo(r['updated_at'] as String?),
                    style: AppText.sans(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
          if (amount != null)
            Text(formatCompactCurrency(num.tryParse(amount.toString())),
                style: AppText.serif(size: 16, color: AppColors.goldText)),
        ],
      ),
    );
  }

  Widget _placeholderList() {
    final demo = [
      ('Braccia Fund I LP', '68% called · 23 LPs', '\$184M'),
      ('Growth Fund II', 'Raising · 42% closed', '\$63M'),
      ('Treasury · MMF', '5.1% yield', '\$15M'),
    ];
    return AppCard(
      noPadding: true,
      radius: 18,
      child: Column(
        children: [
          for (int i = 0; i < demo.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: i == demo.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.hairlineSoft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(demo[i].$1,
                            style: AppText.sans(
                                size: 13.5, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(demo[i].$2,
                            style: AppText.sans(
                                size: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  Text(demo[i].$3,
                      style: AppText.serif(
                          size: 16, color: AppColors.goldText)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LightBars extends StatelessWidget {
  final List<double> values;
  const _LightBars({required this.values});
  @override
  Widget build(BuildContext context) {
    final n = values.length;
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < n; i++) ...[
            Expanded(
              child: Container(
                height: values[i] * 64,
                decoration: BoxDecoration(
                  gradient: i >= n - 3 ? AppColors.goldGradientVertical : null,
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

class _ChatTemplate extends ConsumerWidget {
  final AppModule module;
  const _ChatTemplate({required this.module});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Messages has a dedicated bespoke screen; this is the fallback preview.
    final demo = [
      ('deal-apollo', 'Sofia: LOI draft attached…', '3', true),
      ('compliance', 'KYC cleared for Quantum…', '9m', false),
      ('Sofia Pereira', 'You: thanks, sending now', '1h', false),
      ('general', 'Raj: Q3 sourcing list ready', '3h', false),
    ];
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 110),
      children: [
        for (final c in demo)
          ListTile(
            onTap: () => context.push('/messages'),
            leading: GlyphTile(
              icon: c.$1.contains(' ') ? Icons.person : Icons.tag,
              color: module.glyphColor,
              bg: module.tint,
            ),
            title: Text(c.$1,
                style: AppText.sans(size: 14, weight: FontWeight.w600)),
            subtitle: Text(c.$2,
                style: AppText.sans(size: 11.5, color: AppColors.muted)),
            trailing: c.$4
                ? StatusPill(
                    label: c.$3,
                    color: Colors.white,
                    bg: AppColors.redOnDark)
                : Text(c.$3,
                    style:
                        AppText.sans(size: 10, color: const Color(0xFFB7B6AD))),
          ),
      ],
    );
  }
}

class _ListTemplate extends ConsumerStatefulWidget {
  final AppModule module;
  const _ListTemplate({required this.module});

  @override
  ConsumerState<_ListTemplate> createState() => _ListTemplateState();
}

class _ListTemplateState extends ConsumerState<_ListTemplate> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    final rows = m.table == null
        ? const AsyncValue.data(<Map<String, dynamic>>[])
        : ref.watch(tableProvider(m.table!));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.input),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(children: [
                const Icon(Icons.search, size: 16, color: Color(0xFFB0AFA7)),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v),
                    style: AppText.sans(size: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search ${m.label}…',
                      hintStyle: AppText.sans(
                          size: 13, color: const Color(0xFFB0AFA7)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            rows.when(
              loading: () => const LoadingState(),
              error: (e, _) => _demoList(m),
              data: (data) {
                final filtered = data.where((r) {
                  if (_q.isEmpty) return true;
                  final t = (r['name'] ?? r['title'] ?? '').toString().toLowerCase();
                  return t.contains(_q.toLowerCase());
                }).toList();
                if (filtered.isEmpty) return _demoList(m);
                return AppCard(
                  noPadding: true,
                  radius: 18,
                  child: Column(
                    children: [
                      for (int i = 0; i < filtered.length && i < 40; i++)
                        _row(filtered[i], i == filtered.length - 1 || i == 39),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        Positioned(
          right: 2,
          bottom: 4,
          child: GoldFab(onTap: () {}),
        ),
      ],
    );
  }

  Widget _row(Map<String, dynamic> r, bool last) {
    final title =
        (r['name'] ?? r['title'] ?? r['full_name'] ?? 'Item').toString();
    final status = (r['status'] ?? r['compliance_status'])?.toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          GlyphTile(
            icon: Icons.circle,
            color: widget.module.glyphColor,
            bg: widget.module.tint,
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.sans(size: 14, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text('Updated ${timeAgo(r['updated_at'] as String?)}',
                    style: AppText.sans(size: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          if (status != null) StatusPill.forStatus(status),
        ],
      ),
    );
  }

  Widget _demoList(AppModule m) {
    final demo = [
      ('Quantum Capital', 'Updated 2h ago', 'active'),
      ('Innovation Labs', 'Updated 5h ago', 'pending'),
      ('Meridian Group', 'Updated yesterday', 'done'),
      ('Atlas Mining Ltd', 'Updated 2 days ago', 'review'),
    ];
    return AppCard(
      noPadding: true,
      radius: 18,
      child: Column(
        children: [
          for (int i = 0; i < demo.length; i++)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: i == demo.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.hairlineSoft)),
              ),
              child: Row(
                children: [
                  GlyphTile(
                    icon: m.icon,
                    color: m.glyphColor,
                    bg: m.tint,
                    size: 40,
                    radius: 12,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(demo[i].$1,
                            style: AppText.sans(
                                size: 14, weight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(demo[i].$2,
                            style: AppText.sans(
                                size: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  StatusPill.forStatus(demo[i].$3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
