import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ── Seeded fallback client ──────────────────────────────────────────────────

Client _seedClient(String id) => Client(
      id: id,
      name: 'Quantum Capital Management',
      clientType: 'entity',
      status: 'active',
      company: 'Quantum Capital Management LP',
      industry: 'Asset Management',
      totalAum: 485000000,
      complianceStatus: 'cleared',
    );

// ── Seeded demo deals for fallback ─────────────────────────────────────────

List<Deal> _seedDeals(String clientId) => [
      Deal(
        id: 'seed-deal-1',
        name: 'Braccia Growth Fund III — Series B',
        clientId: clientId,
        stage: 'negotiation',
        status: 'active',
        dealType: 'Fund Investment',
        dealValue: 25000000,
        probability: 72,
        expectedCloseDate: '2026-09-30',
        isActive: true,
      ),
      Deal(
        id: 'seed-deal-2',
        name: 'Co-Investment: Atlas Infra SPV',
        clientId: clientId,
        stage: 'due_diligence',
        status: 'active',
        dealType: 'Co-Investment',
        dealValue: 8500000,
        probability: 55,
        expectedCloseDate: '2026-10-15',
        isActive: true,
      ),
    ];

// ── Seeded notes / timeline ─────────────────────────────────────────────────

const _seedNotes = [
  (
    icon: Icons.sticky_note_2_outlined,
    color: AppColors.goldText,
    title: 'Call with James Chen — Q3 allocation review',
    body:
        'Client confirmed increasing allocation to 10% of NAV. Interested in the new infrastructure sleeve. Follow up with term sheet.',
    when: '2 days ago',
  ),
  (
    icon: Icons.check_circle_outline,
    color: AppColors.green,
    title: 'KYC / AML review completed',
    body: 'Compliance cleared. All documentation on file. Annual refresh due Q4.',
    when: '1 week ago',
  ),
  (
    icon: Icons.phone_outlined,
    color: AppColors.blue,
    title: 'Introductory call — new mandate discussion',
    body:
        'Discussed potential secondary fund strategy. Client requested deck and track record.',
    when: '3 weeks ago',
  ),
];

const _seedActivity = [
  (
    icon: Icons.edit_outlined,
    color: AppColors.goldText,
    title: 'Deal updated: Series B — moved to Negotiation',
    when: '20m ago',
  ),
  (
    icon: Icons.person_outline,
    color: AppColors.blue,
    title: 'Profile updated by Sofia Pereira',
    when: '3h ago',
  ),
  (
    icon: Icons.upload_file_outlined,
    color: AppColors.purple,
    title: 'Document uploaded: Q3 Investor Letter',
    when: 'yesterday',
  ),
  (
    icon: Icons.mail_outline,
    color: AppColors.green,
    title: 'Email sent: Fund III subscription documents',
    when: '2 days ago',
  ),
  (
    icon: Icons.check_box_outlined,
    color: AppColors.greenOnDark,
    title: 'Task completed: Send NDA to client',
    when: '4 days ago',
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class ClientDetailScreen extends ConsumerStatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  ConsumerState<ClientDetailScreen> createState() =>
      _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientProvider(widget.clientId));

    return clientAsync.when(
      loading: () => _scaffold(context, null, loading: true),
      error: (e, _) => _scaffold(context, _seedClient(widget.clientId)),
      data: (c) => _scaffold(context, c ?? _seedClient(widget.clientId)),
    );
  }

  Widget _scaffold(BuildContext context, Client? client,
      {bool loading = false}) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: loading
          ? Column(
              children: [
                _HeroHeader(
                  client: null,
                  tabs: _tabs,
                  onBack: () => context.pop(),
                ),
                const Expanded(child: LoadingState()),
              ],
            )
          : Column(
              children: [
                _HeroHeader(
                  client: client,
                  tabs: _tabs,
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      _OverviewTab(client: client!),
                      _DealsTab(
                        clientId: widget.clientId,
                        client: client,
                      ),
                      _NotesTab(),
                      _ActivityTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Hero header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final Client? client;
  final TabController tabs;
  final VoidCallback onBack;
  const _HeroHeader({
    required this.client,
    required this.tabs,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 14;
    final c = client;

    return Container(
      color: AppColors.onyx700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back + actions row
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          color: AppColors.goldOnDark, size: 22),
                      Text(
                        'Clients',
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.goldOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _headerIcon(Icons.more_horiz),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // monogram + name + status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MonogramTile(
                  initials: initialsOf(c?.name ?? '?'),
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c?.name ?? '—',
                        style:
                            AppText.serif(size: 22, color: AppColors.ivory),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            _capitalise(c?.clientType ?? 'entity'),
                            style: AppText.sans(
                              size: 12,
                              color: AppColors.mutedOnDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill.forStatus(c?.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // big AUM figure
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL AUM',
                    style: AppText.eyebrow(AppColors.mutedOnDark)),
                const SizedBox(height: 4),
                Text(
                  c?.totalAum != null
                      ? formatCompactCurrency(c!.totalAum)
                      : '—',
                  style: AppText.serif(size: 36, color: AppColors.ivory),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // segmented tabs
          TabBar(
            controller: tabs,
            labelStyle: AppText.sans(size: 13, weight: FontWeight.w600),
            unselectedLabelStyle: AppText.sans(size: 13),
            labelColor: AppColors.gold300,
            unselectedLabelColor: AppColors.mutedOnDark,
            indicatorColor: AppColors.gold300,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.white.withValues(alpha: 0.08),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Deals'),
              Tab(text: 'Notes'),
              Tab(text: 'Activity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Icon(icon, size: 18, color: AppColors.mutedOnDark),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Client client;
  const _OverviewTab({required this.client});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        // Key facts
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key Facts',
                  style: AppText.serif(size: 17, color: AppColors.ink)),
              const SizedBox(height: 14),
              _fact('Type', _capitalise(client.clientType ?? 'Entity')),
              _divider(),
              _fact('Industry', client.industry ?? '—'),
              _divider(),
              _fact('Status', _capitalise(client.status ?? '—')),
              _divider(),
              _fact('Compliance / KYC',
                  _capitalise(client.complianceStatus ?? '—')),
              _divider(),
              _fact(
                'Total AUM',
                client.totalAum != null
                    ? formatCompactCurrency(client.totalAum)
                    : '—',
                valueStyle: AppText.serif(size: 15, color: AppColors.goldText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Contact actions
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact',
                  style: AppText.serif(size: 17, color: AppColors.ink)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _contactAction(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    color: AppColors.green,
                    bg: AppColors.green.withValues(alpha: 0.1),
                  ),
                  _contactAction(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    color: AppColors.blue,
                    bg: AppColors.blue.withValues(alpha: 0.1),
                  ),
                  _contactAction(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message',
                    color: AppColors.goldText,
                    bg: AppColors.gold500.withValues(alpha: 0.1),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Quick stats row
        Row(
          children: [
            _miniKpi('2', 'Active Deals'),
            const SizedBox(width: 10),
            _miniKpi('3', 'Total Deals'),
            const SizedBox(width: 10),
            _miniKpi('100%', 'Retention'),
          ],
        ),
      ],
    );
  }

  Widget _fact(
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppText.sans(size: 13, color: AppColors.muted)),
          ),
          Text(
            value,
            style: valueStyle ??
                AppText.sans(
                    size: 13.5,
                    color: AppColors.ink,
                    weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.hairlineSoft,
      );

  Widget _contactAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Column(
      children: [
        GlyphTile(icon: icon, color: color, bg: bg, size: 46, radius: 14),
        const SizedBox(height: 6),
        Text(label, style: AppText.sans(size: 11.5, color: AppColors.muted)),
      ],
    );
  }

  Widget _miniKpi(String value, String label) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppText.serif(size: 20, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label,
                style: AppText.sans(size: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Deals tab ────────────────────────────────────────────────────────────────

class _DealsTab extends ConsumerWidget {
  final String clientId;
  final Client client;
  const _DealsTab({required this.clientId, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDealsAsync = ref.watch(dealsProvider);

    return allDealsAsync.when(
      loading: () => const LoadingState(),
      error: (_, _) => _buildList(context, _seedDeals(clientId)),
      data: (all) {
        final mine = all
            .where((d) => d.clientId == clientId && d.isActive)
            .toList();
        return _buildList(
          context,
          mine.isEmpty ? _seedDeals(clientId) : mine,
        );
      },
    );
  }

  Widget _buildList(BuildContext context, List<Deal> deals) {
    if (deals.isEmpty) {
      return const EmptyStateView(
        message: 'No deals linked to this client.',
        icon: Icons.handshake_outlined,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text(
          '${deals.length} deal${deals.length == 1 ? '' : 's'}',
          style: AppText.eyebrow(AppColors.mutedLight),
        ),
        const SizedBox(height: 10),
        for (final deal in deals) ...[
          _DealCard(deal: deal),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/deal/${deal.id}'),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 14, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.forStatus(deal.stage),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (deal.dealType != null) ...[
                _tag(deal.dealType!),
                const SizedBox(width: 6),
              ],
              if (deal.probability != null)
                _tag('${deal.probability!.round()}% prob'),
            ],
          ),
          if (deal.dealValue != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  deal.expectedCloseDate != null
                      ? 'Close ${formatDate(deal.expectedCloseDate)}'
                      : '',
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
                Text(
                  formatCompactCurrency(deal.dealValue),
                  style: AppText.serif(size: 16, color: AppColors.goldText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.hairlineSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppText.sans(
            size: 10.5, color: AppColors.muted, weight: FontWeight.w500),
      ),
    );
  }
}

// ── Notes tab ────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text('Recent Notes', style: AppText.serif(size: 18)),
        const SizedBox(height: 12),
        for (int i = 0; i < _seedNotes.length; i++) ...[
          _NoteCard(note: _seedNotes[i]),
          if (i < _seedNotes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ({
    IconData icon,
    Color color,
    String title,
    String body,
    String when,
  }) note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlyphTile(
                icon: note.icon,
                color: note.color,
                bg: note.color.withValues(alpha: 0.1),
                size: 36,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                            size: 13, weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(note.when,
                        style: AppText.sans(
                            size: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note.body,
            style: AppText.sans(
                size: 12.5, color: AppColors.muted, height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ── Activity tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Text('Activity Timeline', style: AppText.serif(size: 18)),
        const SizedBox(height: 16),
        for (int i = 0; i < _seedActivity.length; i++)
          _ActivityRow(
            item: _seedActivity[i],
            isLast: i == _seedActivity.length - 1,
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ({IconData icon, Color color, String title, String when}) item;
  final bool isLast;
  const _ActivityRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // timeline line + dot
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 14, color: item.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: AppColors.hairline,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style:
                          AppText.sans(size: 13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.when,
                      style:
                          AppText.sans(size: 11, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
