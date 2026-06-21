import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ── Seeded demo clients ────────────────────────────────────────────────────

final _demoClients = <Client>[
  Client(
    id: 'demo-1',
    name: 'Quantum Capital Management',
    clientType: 'entity',
    status: 'active',
    company: 'Quantum Capital',
    industry: 'Asset Management',
    totalAum: 485000000,
    complianceStatus: 'cleared',
  ),
  Client(
    id: 'demo-2',
    name: 'Chen Family Office',
    clientType: 'individual',
    status: 'active',
    company: 'Chen Family Office',
    industry: 'Family Office',
    totalAum: 212000000,
    complianceStatus: 'cleared',
  ),
  Client(
    id: 'demo-3',
    name: 'Meridian Group',
    clientType: 'entity',
    status: 'prospect',
    company: 'Meridian Group LLC',
    industry: 'Private Equity',
    totalAum: 130000000,
    complianceStatus: 'pending',
  ),
  Client(
    id: 'demo-4',
    name: 'Atlas Mining Ltd',
    clientType: 'entity',
    status: 'active',
    company: 'Atlas Mining',
    industry: 'Mining & Resources',
    totalAum: 78000000,
    complianceStatus: 'cleared',
  ),
  Client(
    id: 'demo-5',
    name: 'Harrington Ventures',
    clientType: 'entity',
    status: 'prospect',
    company: 'Harrington Ventures',
    industry: 'Venture Capital',
    totalAum: 55000000,
    complianceStatus: 'dd',
  ),
  Client(
    id: 'demo-6',
    name: 'Nakamura Holdings',
    clientType: 'individual',
    status: 'active',
    company: 'Nakamura Holdings',
    industry: 'Conglomerate',
    totalAum: 310000000,
    complianceStatus: 'cleared',
  ),
  Client(
    id: 'demo-7',
    name: 'Oasis Sovereign Fund',
    clientType: 'entity',
    status: 'inactive',
    company: 'Oasis Sovereign',
    industry: 'Sovereign Wealth',
    totalAum: 920000000,
    complianceStatus: 'review',
  ),
];

// ── Filter chip enum ───────────────────────────────────────────────────────

enum _ClientFilter { all, active, prospect, byAum }

extension _ClientFilterLabel on _ClientFilter {
  String get label {
    switch (this) {
      case _ClientFilter.all:
        return 'All';
      case _ClientFilter.active:
        return 'Active';
      case _ClientFilter.prospect:
        return 'Prospect';
      case _ClientFilter.byAum:
        return 'By AUM';
    }
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _ClientFilter _filter = _ClientFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Client> _applyFilter(List<Client> clients) {
    List<Client> out = clients;

    // search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      out = out.where((c) {
        return c.name.toLowerCase().contains(q) ||
            (c.company?.toLowerCase().contains(q) ?? false) ||
            (c.industry?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // filter chip
    switch (_filter) {
      case _ClientFilter.all:
        break;
      case _ClientFilter.active:
        out = out.where((c) => c.status?.toLowerCase() == 'active').toList();
        break;
      case _ClientFilter.prospect:
        out = out.where((c) => c.status?.toLowerCase() == 'prospect').toList();
        break;
      case _ClientFilter.byAum:
        out = List<Client>.from(out)
          ..sort((a, b) => (b.totalAum ?? 0).compareTo(a.totalAum ?? 0));
        break;
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: clientsAsync.when(
        loading: () => _buildBody(context, _demoClients, loading: true),
        error: (_, _) => _buildBody(context, _demoClients),
        data: (clients) {
          final effective = clients.isEmpty ? _demoClients : clients;
          return _buildBody(context, effective);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: GoldFab(onTap: () {}),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Client> allClients, {
    bool loading = false,
  }) {
    final filtered = _applyFilter(allClients);
    final total = allClients.length;

    return RefreshIndicator(
      color: AppColors.gold500,
      onRefresh: () async {
        ref.invalidate(clientsProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Dark header ──────────────────────────────────────
          SliverToBoxAdapter(
            child: DarkHeader(
              title: 'Clients',
              actions: [
                Text(
                  '$total total',
                  style: AppText.sans(
                    size: 12,
                    color: AppColors.mutedOnDark,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
              bottom: DarkSearchField(
                hint: 'Search clients…',
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              bottomPadding: 14,
            ),
          ),
          // ── Filter chips ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterChips(
              selected: _filter,
              onSelect: (f) => setState(() => _filter = f),
            ),
          ),
          // ── Client list ───────────────────────────────────────
          if (loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: LoadingState(),
            )
          else if (filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateView(
                message: 'No clients match your search.',
                icon: Icons.people_outline,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i == 0) {
                      // section header
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 6),
                        child: Text(
                          '${filtered.length} client${filtered.length == 1 ? '' : 's'}',
                          style: AppText.eyebrow(AppColors.mutedLight),
                        ),
                      );
                    }
                    final idx = i - 1;
                    final client = filtered[idx];
                    final isLast = idx == filtered.length - 1;
                    return _ClientRow(
                      client: client,
                      isLast: isLast,
                      onTap: () => context.push('/client/${client.id}'),
                    );
                  },
                  childCount: filtered.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Filter chips widget ────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _ClientFilter selected;
  final ValueChanged<_ClientFilter> onSelect;
  const _FilterChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onyx700,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _ClientFilter.values) ...[
              _Chip(
                label: f.label,
                selected: selected == f,
                onTap: () => onSelect(f),
              ),
              if (f != _ClientFilter.byAum) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 12.5,
            color: selected ? AppColors.goldInk : AppColors.mutedOnDark,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Client row ─────────────────────────────────────────────────────────────

class _ClientRow extends StatelessWidget {
  final Client client;
  final bool isLast;
  final VoidCallback onTap;
  const _ClientRow({
    required this.client,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(client.name);
    final type = client.clientType ?? 'entity';
    final aum = client.totalAum;
    final status = client.status ?? 'active';
    final compliance = client.complianceStatus;

    // decide pill: compliance flags override status
    String pillStatus = status;
    if (compliance != null &&
        ['flag', 'review', 'dd'].contains(compliance.toLowerCase())) {
      pillStatus = compliance;
    }

    return AppCard(
      noPadding: true,
      onTap: onTap,
      radius: AppRadii.card,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.hairlineSoft),
                ),
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(AppRadii.card))
              : null,
        ),
        child: Row(
          children: [
            MonogramTile(initials: initials, size: 44),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_capitalise(type)} · ${client.industry ?? 'Finance'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (aum != null)
                  Text(
                    formatCompactCurrency(aum),
                    style: AppText.serif(
                      size: 15,
                      color: AppColors.goldText,
                    ),
                  ),
                const SizedBox(height: 4),
                StatusPill.forStatus(pillStatus),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFFC4C2BB)),
          ],
        ),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
