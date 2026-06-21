import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ─── Stage pipeline definition ────────────────────────────────────────────────

const _pipelineStages = [
  'sourcing',
  'nda',
  'dd',
  'negotiation',
  'legal',
  'closed_won',
];

const _pipelineLabels = [
  'Source',
  'NDA',
  'DD',
  'Negot.',
  'Legal',
  'Close',
];

String? _nextStage(String current) {
  final idx = _pipelineStages.indexOf(current);
  if (idx < 0 || idx >= _pipelineStages.length - 1) return null;
  return _pipelineStages[idx + 1];
}

// ─── Seed fallback deal ───────────────────────────────────────────────────────

Deal _seedDeal(String id) => Deal(
      id: id,
      name: 'Apollo Growth Acquisition',
      clientId: 'c1',
      stage: 'negotiation',
      status: 'active',
      dealType: 'M&A',
      dealValue: 24000000,
      probability: 72,
      expectedCloseDate: '2026-09-15',
      ownerId: 'u1',
      leadConsultant: 'Sofia Pereira',
      source: 'Direct',
      isActive: true,
      updatedAt: DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
    );

// ─── Activity seed data ───────────────────────────────────────────────────────

class _ActivityItem {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  const _ActivityItem(this.label, this.time, this.icon, this.color);
}

final _seedActivity = [
  _ActivityItem('LOI sent to Apollo legal team', '2h ago', Icons.send_rounded,
      AppColors.blue),
  _ActivityItem('Probability updated to 72%', 'yesterday',
      Icons.trending_up_rounded, AppColors.green),
  _ActivityItem('NDA counter-signed', '3 days ago', Icons.verified_rounded,
      AppColors.goldText),
  _ActivityItem(
      'Deal created', '2 weeks ago', Icons.add_circle_rounded, AppColors.muted),
];

// ─── Local advance-stage state provider ──────────────────────────────────────

final _advancingProvider =
    StateProvider.family<bool, String>((ref, id) => false);

// ─── Main screen ─────────────────────────────────────────────────────────────

class DealDetailScreen extends ConsumerStatefulWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(dealProvider(widget.dealId));
    final isAdvancing = ref.watch(_advancingProvider(widget.dealId));

    return dealAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.ivory,
        body: Column(
          children: [
            _buildHeroHeader(context, null),
            const Expanded(child: LoadingState()),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.ivory,
        body: Column(
          children: [
            _buildHeroHeader(context, null),
            Expanded(
              child: ErrorStateView(
                error: e,
                onRetry: () => ref.invalidate(dealProvider(widget.dealId)),
              ),
            ),
          ],
        ),
      ),
      data: (liveDeal) {
        final deal = liveDeal ?? _seedDeal(widget.dealId);
        return Scaffold(
          backgroundColor: AppColors.ivory,
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeroHeader(context, deal),
                  _buildStageStepper(deal),
                  _buildTabBar(),
                  Expanded(child: _buildTabBody(deal)),
                ],
              ),
              _buildStickyBottomBar(deal, isAdvancing),
            ],
          ),
        );
      },
    );
  }

  // ─── Hero header ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context, Deal? deal) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroHeaderGradient),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left,
                        color: AppColors.goldOnDark, size: 22),
                    Text('Pipeline',
                        style: AppText.sans(
                            size: 14, color: AppColors.goldOnDark)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Text('⋯',
                      style: TextStyle(
                          color: AppColors.ivory,
                          fontSize: 14,
                          height: 1.1)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Company + type eyebrow
          if (deal != null)
            Text(
              [
                if (deal.dealType != null) deal.dealType!,
                if (deal.source != null) deal.source!,
              ].join(' · '),
              style: AppText.eyebrow(AppColors.mutedOnDark),
            ),
          const SizedBox(height: 6),
          // Deal name (serif 27)
          Text(
            deal?.name ?? 'Deal Detail',
            style: AppText.serif(size: 27, color: AppColors.ivory, height: 1.15),
          ),
          const SizedBox(height: 12),
          if (deal != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Big gold $ value
                Text(
                  formatCompactCurrency(deal.dealValue),
                  style: AppText.serif(
                      size: 30,
                      color: AppColors.gold300,
                      height: 1.0),
                ),
                const SizedBox(width: 12),
                // Stage pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    deal.stage.toUpperCase().replaceAll('_', ' '),
                    style: AppText.sans(
                        size: 10.5,
                        color: AppColors.goldInk,
                        weight: FontWeight.w700,
                        letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Stage stepper ───────────────────────────────────────────────────────

  Widget _buildStageStepper(Deal deal) {
    final currentIdx = _pipelineStages.indexOf(deal.stage);
    return Container(
      color: AppColors.onyx800,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: [
          // Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                for (int i = 0; i < _pipelineStages.length; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: i <= currentIdx
                            ? AppColors.goldGradient
                            : null,
                        color: i <= currentIdx
                            ? null
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  if (i < _pipelineStages.length - 1)
                    const SizedBox(width: 3),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            children: [
              for (int i = 0; i < _pipelineLabels.length; i++)
                Expanded(
                  child: Text(
                    _pipelineLabels[i],
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      size: 9.5,
                      color: i <= currentIdx
                          ? AppColors.goldOnDark
                          : AppColors.mutedOnDark,
                      weight: i == currentIdx
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tab bar ─────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    const tabs = ['Overview', 'Tasks', 'Docs', 'Notes'];
    const trackColor = Color(0xFFECE9E1);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _tabController.index == i
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: _tabController.index == i
                          ? [
                              BoxShadow(
                                color: AppColors.ink.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      tabs[i],
                      style: AppText.sans(
                        size: 12.5,
                        color: _tabController.index == i
                            ? AppColors.ink
                            : AppColors.muted,
                        weight: _tabController.index == i
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Tab body ────────────────────────────────────────────────────────────

  Widget _buildTabBody(Deal deal) {
    return IndexedStack(
      index: _tabController.index,
      children: [
        _OverviewTab(deal: deal),
        _TasksTab(dealId: deal.id),
        _DocsTab(),
        _NotesTab(),
      ],
    );
  }

  // ─── Sticky bottom bar ───────────────────────────────────────────────────

  Widget _buildStickyBottomBar(Deal deal, bool isAdvancing) {
    final next = _nextStage(deal.stage);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivory,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPad + 14),
        child: Row(
          children: [
            Expanded(
              child: GoldButton(
                label: next == null
                    ? 'Deal Closed'
                    : 'Advance to ${next.toUpperCase().replaceAll("_", " ")}',
                loading: isAdvancing,
                onTap: next == null
                    ? null
                    : () => _advanceStage(deal, next),
              ),
            ),
            const SizedBox(width: 10),
            // AI shortcut button
            Pressable(
              onTap: () => context.push('/ai'),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.darkCardGradient,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  '✦',
                  style: TextStyle(
                      fontSize: 18, color: AppColors.goldOnDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advanceStage(Deal deal, String next) async {
    ref.read(_advancingProvider(deal.id).notifier).state = true;
    try {
      await repository.advanceDealStage(deal.id, next);
    } catch (_) {
      // degrade gracefully
    } finally {
      ref.invalidate(dealProvider(deal.id));
      ref.invalidate(dealsProvider);
      ref.read(_advancingProvider(deal.id).notifier).state = false;
    }
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Deal deal;
  const _OverviewTab({required this.deal});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        // Key facts card
        AppCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Key Facts',
                  style:
                      AppText.sans(size: 13, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              _fact('Owner',
                  deal.leadConsultant ?? deal.ownerId ?? 'Unassigned'),
              _divider(),
              _fact('Close Date', formatDate(deal.expectedCloseDate)),
              _divider(),
              _fact(
                'Probability',
                '${deal.probability?.toStringAsFixed(0) ?? '—'}%',
                valueColor: AppColors.green,
              ),
              _divider(),
              _fact('Source', deal.source ?? '—'),
              _divider(),
              _fact('Type', deal.dealType ?? '—'),
              _divider(),
              _fact('Status', deal.status ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Activity timeline
        _ActivityTimeline(deal: deal),
      ],
    );
  }

  Widget _fact(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppText.sans(size: 12.5, color: AppColors.muted)),
          ),
          Text(
            value,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w600,
              color: valueColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.hairlineSoft);
}

// ─── Activity Timeline ────────────────────────────────────────────────────────

class _ActivityTimeline extends StatelessWidget {
  final Deal deal;
  const _ActivityTimeline({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHead('Recent Activity', serif: true),
        AppCard(
          radius: 20,
          noPadding: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (int i = 0; i < _seedActivity.length; i++)
                  _TimelineItem(
                    item: _seedActivity[i],
                    isLast: i == _seedActivity.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;
  const _TimelineItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon node + connector line
          SizedBox(
            width: 28,
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
                  child: Icon(item.icon, size: 13, color: item.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.hairline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style:
                        AppText.sans(size: 13, weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(item.time,
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

// ─── Tasks Tab ────────────────────────────────────────────────────────────────

class _TasksTab extends ConsumerWidget {
  final String dealId;
  const _TasksTab({required this.dealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => _demoTasks(),
      data: (all) {
        final tasks =
            all.where((t) => t.dealId == dealId).toList();
        if (tasks.isEmpty) return _demoTasks();
        return _taskList(tasks);
      },
    );
  }

  Widget _taskList(List<Task> tasks) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        AppCard(
          radius: 20,
          noPadding: true,
          child: Column(
            children: [
              for (int i = 0; i < tasks.length; i++)
                _TaskRow(
                    task: tasks[i], isLast: i == tasks.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _demoTasks() {
    final demo = [
      Task(
          id: 'd1',
          title: 'Send revised LOI to counsel',
          status: 'open',
          priority: 'high',
          dueDate:
              DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          dealId: dealId),
      Task(
          id: 'd2',
          title: 'Schedule management call',
          status: 'open',
          priority: 'medium',
          dueDate:
              DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          dealId: dealId),
      Task(
          id: 'd3',
          title: 'Review financial model v3',
          status: 'completed',
          priority: 'medium',
          completionDate:
              DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          dealId: dealId),
    ];
    return _taskList(demo);
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final bool isLast;
  const _TaskRow({required this.task, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          Icon(
            task.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 20,
            color: task.isDone ? AppColors.green : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppText.sans(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: task.isDone
                        ? AppColors.muted
                        : AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      task.isOverdue
                          ? 'Overdue · ${formatDate(task.dueDate)}'
                          : 'Due ${formatDate(task.dueDate)}',
                      style: AppText.sans(
                        size: 11,
                        color: task.isOverdue
                            ? AppColors.red
                            : AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (task.priority != null)
            _priorityDot(task.priority!),
        ],
      ),
    );
  }

  Widget _priorityDot(String priority) {
    final color = switch (priority.toLowerCase()) {
      'high' => AppColors.red,
      'medium' => AppColors.goldTextSoft,
      _ => AppColors.muted,
    };
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─── Docs Tab ────────────────────────────────────────────────────────────────

class _DocsTab extends StatelessWidget {
  const _DocsTab();

  @override
  Widget build(BuildContext context) {
    final docs = [
      ('NDA — Executed', 'PDF · 142 KB · 3 days ago', Icons.description_rounded,
          AppColors.blue),
      ('Financial Model v3', 'XLSX · 4.2 MB · yesterday',
          Icons.table_chart_rounded, AppColors.green),
      ('LOI Draft', 'DOCX · 88 KB · 2h ago', Icons.article_rounded,
          AppColors.goldTextSoft),
      ('Board Deck', 'PDF · 6.7 MB · 1 week ago', Icons.slideshow_rounded,
          AppColors.purple),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        AppCard(
          radius: 20,
          noPadding: true,
          child: Column(
            children: [
              for (int i = 0; i < docs.length; i++)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: i == docs.length - 1
                        ? null
                        : const Border(
                            bottom:
                                BorderSide(color: AppColors.hairlineSoft)),
                  ),
                  child: Row(
                    children: [
                      GlyphTile(
                        icon: docs[i].$3,
                        color: docs[i].$4,
                        bg: docs[i].$4.withValues(alpha: 0.12),
                        size: 42,
                        radius: 12,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(docs[i].$1,
                                style: AppText.sans(
                                    size: 13.5, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(docs[i].$2,
                                style: AppText.sans(
                                    size: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.download_rounded,
                          size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Notes Tab ───────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    final notes = [
      (
        'Management call notes',
        'Team is highly motivated. CFO seems cautious — address dilution concerns in next meeting. Overall signal is positive.',
        '2 days ago',
        'Sofia Pereira'
      ),
      (
        'Legal review flag',
        'IP clause in schedule 4 needs clarification. Counsel to respond by EOW.',
        'yesterday',
        'Tom Walker'
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        for (final note in notes) ...[
          AppCard(
            radius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(note.$1,
                        style: AppText.sans(
                            size: 13.5, weight: FontWeight.w600)),
                    Text(note.$3,
                        style:
                            AppText.sans(size: 11, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(note.$2,
                    style: AppText.sans(
                        size: 13, color: AppColors.muted, height: 1.55)),
                const SizedBox(height: 8),
                Text('— ${note.$4}',
                    style: AppText.sans(
                        size: 11.5, color: AppColors.goldText, weight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
