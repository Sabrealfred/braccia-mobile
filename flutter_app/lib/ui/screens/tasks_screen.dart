// tasks_screen.dart — Asana-grade task manager for Braccia Capital CRM.
// Owned exclusively by the tasks feature agent.
//
// Features:
//   • Dark DarkHeader with search + list/board view toggle.
//   • Filter chips: All / Today / Upcoming / Overdue / Completed.
//   • List view: tasks grouped into Overdue / Today / Upcoming / Completed.
//   • Board view: columns To Do / In Progress / Done.
//   • Circular animated checkbox with optimistic toggle.
//   • GoldFab → bottom sheet (title, due date, priority) → insertTask.
//   • Pull-to-refresh (invalidate tasksProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';
import 'tasks_data.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _Filter { all, today, upcoming, overdue, completed }

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'All';
      case _Filter.today:
        return 'Today';
      case _Filter.upcoming:
        return 'Upcoming';
      case _Filter.overdue:
        return 'Overdue';
      case _Filter.completed:
        return 'Completed';
    }
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtl = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;
  bool _boardView = false;

  late final AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool _isToday(Task t) {
    if (t.isDone || t.dueDate == null) return false;
    final d = DateTime.tryParse(t.dueDate!);
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  bool _isUpcoming(Task t) {
    if (t.isDone || t.dueDate == null) return false;
    final d = DateTime.tryParse(t.dueDate!);
    if (d == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return d.isAfter(
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day)
            .subtract(const Duration(seconds: 1)));
  }

  List<Task> _applyFilter(List<Task> tasks) {
    List<Task> out;
    switch (_filter) {
      case _Filter.all:
        out = tasks;
        break;
      case _Filter.today:
        out = tasks.where(_isToday).toList();
        break;
      case _Filter.upcoming:
        out = tasks.where(_isUpcoming).toList();
        break;
      case _Filter.overdue:
        out = tasks.where((t) => t.isOverdue).toList();
        break;
      case _Filter.completed:
        out = tasks.where((t) => t.isDone).toList();
        break;
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      out = out.where((t) => t.title.toLowerCase().contains(q)).toList();
    }
    return out;
  }

  // ── Bottom sheet: add task ─────────────────────────────────────────────────

  Future<void> _showAddSheet() async {
    final titleCtl = TextEditingController();
    DateTime? dueDate;
    String priority = 'medium';
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
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
                  const SizedBox(height: 18),
                  Text('New Task',
                      style: AppText.serif(size: 20, color: AppColors.ink)),
                  const SizedBox(height: 18),
                  // Title field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(AppRadii.input),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: titleCtl,
                      autofocus: true,
                      style: AppText.sans(size: 14, color: AppColors.ink),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Task title…',
                        hintStyle:
                            AppText.sans(size: 14, color: AppColors.muted),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Due date + priority row
                  Row(
                    children: [
                      // Due date picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 730)),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(
                                          primary: AppColors.gold500),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setSheet(() => dueDate = picked);
                            }
                          },
                          child: Container(
                            height: 44,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                              color: AppColors.ivory,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.input),
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppColors.muted),
                                const SizedBox(width: 7),
                                Text(
                                  dueDate == null
                                      ? 'Due date'
                                      : DateFormat('MMM d, yyyy')
                                          .format(dueDate!),
                                  style: AppText.sans(
                                      size: 13,
                                      color: dueDate == null
                                          ? AppColors.muted
                                          : AppColors.ink),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Priority dropdown
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius:
                                BorderRadius.circular(AppRadii.input),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: priority,
                              isDense: true,
                              style: AppText.sans(
                                  size: 13, color: AppColors.ink),
                              items: const [
                                DropdownMenuItem(
                                    value: 'high', child: Text('High')),
                                DropdownMenuItem(
                                    value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(
                                    value: 'low', child: Text('Low')),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setSheet(() => priority = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GoldButton(
                    label: 'Add Task',
                    loading: saving,
                    icon: Icons.add,
                    onTap: saving
                        ? null
                        : () async {
                            final title = titleCtl.text.trim();
                            if (title.isEmpty) return;
                            setSheet(() => saving = true);

                            final id =
                                'local-${DateTime.now().millisecondsSinceEpoch}';
                            final optimistic = Task(
                              id: id,
                              title: title,
                              status: 'open',
                              priority: priority,
                              dueDate: dueDate?.toIso8601String(),
                              raw: {'assignee': 'You'},
                            );
                            await ref
                                .read(tasksOverrideProvider.notifier)
                                .insertAndAdd(
                              {
                                'title': title,
                                'status': 'open',
                                'priority': priority,
                                if (dueDate != null)
                                  'due_date': dueDate!
                                      .toIso8601String()
                                      .substring(0, 10),
                              },
                              optimistic,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(mergedTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: GoldFab(onTap: _showAddSheet),
        ),
      ),
      body: Column(
        children: [
          // ── Dark header ──────────────────────────────────────────────────
          _TasksHeader(
            searchCtl: _searchCtl,
            boardView: _boardView,
            onSearchChanged: (v) => setState(() => _query = v),
            onToggleView: () => setState(() => _boardView = !_boardView),
            filter: _filter,
            onFilterChanged: (f) => setState(() => _filter = f),
          ),
          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.gold500,
              onRefresh: () async {
                ref.invalidate(tasksProvider);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: tasksAsync.when(
                loading: () => const LoadingState(),
                error: (e, _) => ErrorStateView(
                  error: e,
                  onRetry: () => ref.invalidate(tasksProvider),
                ),
                data: (allTasks) {
                  final tasks = _applyFilter(allTasks);
                  if (_boardView) {
                    return _BoardView(
                        tasks: tasks,
                        allTasks: allTasks,
                        filter: _filter);
                  }
                  return _ListView(
                      tasks: tasks,
                      allTasks: allTasks,
                      filter: _filter);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark header ───────────────────────────────────────────────────────────────

class _TasksHeader extends StatelessWidget {
  final TextEditingController searchCtl;
  final bool boardView;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleView;
  final _Filter filter;
  final ValueChanged<_Filter> onFilterChanged;

  const _TasksHeader({
    required this.searchCtl,
    required this.boardView,
    required this.onSearchChanged,
    required this.onToggleView,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 14;
    return Container(
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tasks',
                  style: AppText.serif(size: 24, color: AppColors.ivory)),
              // List / Board toggle
              GestureDetector(
                onTap: onToggleView,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_list_rounded,
                        size: 16,
                        color: boardView
                            ? AppColors.mutedOnDark
                            : AppColors.goldOnDark,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.view_column_rounded,
                        size: 16,
                        color: boardView
                            ? AppColors.goldOnDark
                            : AppColors.mutedOnDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search field
          DarkSearchField(
            hint: 'Search tasks…',
            controller: searchCtl,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (final f in _Filter.values) ...[
                  _FilterChip(
                    label: f.label,
                    selected: filter == f,
                    onTap: () => onFilterChanged(f),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.goldGradient : null,
          color: selected
              ? null
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.10),
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

// ── List view ─────────────────────────────────────────────────────────────────

class _ListView extends ConsumerWidget {
  final List<Task> tasks;
  final List<Task> allTasks;
  final _Filter filter;

  const _ListView({
    required this.tasks,
    required this.allTasks,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: EmptyStateView(
            message: 'No tasks here — all clear!',
            icon: Icons.check_circle_outline,
          ),
        ),
      );
    }

    // When a filter is active, render a flat list without section groupings.
    if (filter != _Filter.all) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  noPadding: true,
                  child: Column(
                    children: [
                      for (int i = 0; i < tasks.length; i++)
                        _TaskRow(
                          task: tasks[i],
                          isLast: i == tasks.length - 1,
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      );
    }

    // Group tasks into sections.
    final overdue = allTasks.where((t) => t.isOverdue).toList();
    final today = allTasks.where((t) {
      if (t.isDone || t.isOverdue || t.dueDate == null) return false;
      final d = DateTime.tryParse(t.dueDate!);
      if (d == null) return false;
      final n = DateTime.now();
      return d.year == n.year && d.month == n.month && d.day == n.day;
    }).toList();
    final upcoming = allTasks.where((t) {
      if (t.isDone || t.isOverdue || t.dueDate == null) return false;
      final d = DateTime.tryParse(t.dueDate!);
      if (d == null) return false;
      final n = DateTime.now();
      final isToday = d.year == n.year && d.month == n.month && d.day == n.day;
      return !isToday;
    }).toList();
    final noDate = allTasks
        .where((t) => !t.isDone && !t.isOverdue && t.dueDate == null)
        .toList();
    final completed = allTasks.where((t) => t.isDone).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Overdue',
                  count: overdue.length,
                  color: AppColors.redOnDark,
                  icon: Icons.warning_amber_rounded,
                ),
                _TaskSection(tasks: overdue),
                const SizedBox(height: 16),
              ],
              if (today.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Today',
                  count: today.length,
                  color: AppColors.goldText,
                ),
                _TaskSection(tasks: today),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Upcoming',
                  count: upcoming.length,
                  color: AppColors.ink,
                ),
                _TaskSection(tasks: upcoming),
                const SizedBox(height: 16),
              ],
              if (noDate.isNotEmpty) ...[
                _SectionHeader(
                  title: 'No Due Date',
                  count: noDate.length,
                  color: AppColors.muted,
                ),
                _TaskSection(tasks: noDate),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Completed',
                  count: completed.length,
                  color: AppColors.green,
                  icon: Icons.check_circle_outline,
                ),
                _TaskSection(tasks: completed),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData? icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: AppText.sans(
                size: 12, color: color, weight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: AppText.sans(size: 10, color: color, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final List<Task> tasks;
  const _TaskSection({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      noPadding: true,
      child: Column(
        children: [
          for (int i = 0; i < tasks.length; i++)
            _TaskRow(task: tasks[i], isLast: i == tasks.length - 1),
        ],
      ),
    );
  }
}

// ── Individual task row ───────────────────────────────────────────────────────

class _TaskRow extends ConsumerStatefulWidget {
  final Task task;
  final bool isLast;

  const _TaskRow({required this.task, required this.isLast});

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _checkScale = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.35)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.35, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_checkAnim);
    if (widget.task.isDone) _checkAnim.value = 1.0;
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final done = !widget.task.isDone;
    if (done) {
      await _checkAnim.forward(from: 0);
    } else {
      _checkAnim.value = 0;
    }
    await ref
        .read(tasksOverrideProvider.notifier)
        .toggleDone(widget.task.id, done);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDone = t.isDone;
    final isOverdue = t.isOverdue;

    final dueDateStr = t.dueDate != null ? formatDate(t.dueDate) : null;
    final dueDateColor = isOverdue ? AppColors.redOnDark : AppColors.muted;

    // Meta link text (deal or client name from raw)
    final linkName = (t.raw['deal_name'] ?? t.raw['client_name']) as String?;
    // Assignee
    final assignee = t.raw['assignee'] as String?;

    return Container(
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft),
              ),
      ),
      child: Pressable(
        onTap: () {}, // Future: push task detail
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated circular checkbox
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: ScaleTransition(
                    scale: _checkScale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDone ? AppColors.goldGradient : null,
                        border: isDone
                            ? null
                            : Border.all(
                                color: isOverdue
                                    ? AppColors.redOnDark
                                    : AppColors.muted,
                                width: 1.8,
                              ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 13, color: AppColors.goldInk)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      t.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 13.5,
                        weight: FontWeight.w500,
                        color: isDone ? AppColors.muted : AppColors.ink,
                        height: 1.35,
                      ).copyWith(
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Meta row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (dueDateStr != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 10.5,
                                color: dueDateColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                dueDateStr,
                                style: AppText.sans(
                                    size: 11, color: dueDateColor),
                              ),
                            ],
                          ),
                        if (t.priority != null)
                          _PriorityPill(priority: t.priority!),
                        if (linkName != null)
                          Text(
                            linkName,
                            style: AppText.sans(
                                size: 11,
                                color: AppColors.goldTextSoft,
                                weight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Assignee avatar
              if (assignee != null) ...[
                const SizedBox(width: 8),
                AvatarDot(
                  initials: initialsOf(assignee),
                  color: _avatarColor(assignee),
                  size: 24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color _avatarColor(String name) {
  final colors = [
    const Color(0xFF5B7FA5),
    const Color(0xFF7A5F7D),
    const Color(0xFF2E7D65),
    const Color(0xFF3D6A90),
    AppColors.goldText,
  ];
  return colors[name.hashCode.abs() % colors.length];
}

class _PriorityPill extends StatelessWidget {
  final String priority;
  const _PriorityPill({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (priority.toLowerCase()) {
      case 'high':
        color = AppColors.redOnDark;
        bg = AppColors.red.withValues(alpha: 0.10);
        break;
      case 'medium':
        color = AppColors.goldTextSoft;
        bg = AppColors.gold500.withValues(alpha: 0.12);
        break;
      default:
        color = AppColors.muted;
        bg = AppColors.hairlineSoft;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1),
        style: AppText.sans(
            size: 10, color: color, weight: FontWeight.w600, height: 1.3),
      ),
    );
  }
}

// ── Board view ────────────────────────────────────────────────────────────────

class _BoardView extends ConsumerWidget {
  final List<Task> tasks;
  final List<Task> allTasks;
  final _Filter filter;

  const _BoardView({
    required this.tasks,
    required this.allTasks,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = filter == _Filter.all ? allTasks : tasks;

    final todo = base
        .where((t) =>
            !t.isDone &&
            (t.status == null ||
                t.status == 'open' ||
                t.status == 'todo' ||
                t.status == 'new'))
        .where((t) => !t.isOverdue)
        .toList();
    final inProgress = base
        .where((t) =>
            !t.isDone &&
            (t.status == 'in_progress' || t.status == 'pending') ||
            (!t.isDone && t.isOverdue))
        .toList();
    final done = base.where((t) => t.isDone).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 120),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoardColumn(
              title: 'To Do',
              count: todo.length,
              color: AppColors.blue,
              tasks: todo,
            ),
            const SizedBox(width: 12),
            _BoardColumn(
              title: 'In Progress',
              count: inProgress.length,
              color: AppColors.goldTextSoft,
              tasks: inProgress,
            ),
            const SizedBox(width: 12),
            _BoardColumn(
              title: 'Done',
              count: done.length,
              color: AppColors.green,
              tasks: done,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final List<Task> tasks;

  const _BoardColumn({
    required this.title,
    required this.count,
    required this.color,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    const colWidth = 260.0;
    return SizedBox(
      width: colWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadii.inner),
              border: Border.all(color: color.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: AppText.sans(
                        size: 12,
                        color: color,
                        weight: FontWeight.w700)),
                const Spacer(),
                Text('$count',
                    style: AppText.sans(
                        size: 11,
                        color: color.withValues(alpha: 0.7))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            Container(
              width: colWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                    color: AppColors.hairlineSoft,
                    style: BorderStyle.solid),
              ),
              child: Text('No tasks',
                  textAlign: TextAlign.center,
                  style:
                      AppText.sans(size: 12, color: AppColors.muted)),
            )
          else
            for (final t in tasks) ...[
              _BoardCard(task: t),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final Task task;
  const _BoardCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = task;
    final isOverdue = t.isOverdue;
    final dueDateStr = t.dueDate != null ? formatDate(t.dueDate) : null;
    final linkName = (t.raw['deal_name'] ?? t.raw['client_name']) as String?;
    final assignee = t.raw['assignee'] as String?;

    return AppCard(
      padding: const EdgeInsets.all(13),
      onTap: () {}, // Future: push task detail
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority + title
          if (t.priority != null) ...[
            _PriorityPill(priority: t.priority!),
            const SizedBox(height: 6),
          ],
          Text(
            t.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 13,
              weight: FontWeight.w500,
              color: t.isDone ? AppColors.muted : AppColors.ink,
            ).copyWith(
              decoration: t.isDone
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationColor: AppColors.muted,
            ),
          ),
          if (dueDateStr != null || linkName != null || assignee != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (dueDateStr != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 10,
                          color: isOverdue
                              ? AppColors.redOnDark
                              : AppColors.muted),
                      const SizedBox(width: 3),
                      Text(dueDateStr,
                          style: AppText.sans(
                              size: 10.5,
                              color: isOverdue
                                  ? AppColors.redOnDark
                                  : AppColors.muted)),
                    ],
                  ),
                const Spacer(),
                if (assignee != null)
                  AvatarDot(
                    initials: initialsOf(assignee),
                    color: _avatarColor(assignee),
                    size: 22,
                  ),
              ],
            ),
          ],
          if (linkName != null) ...[
            const SizedBox(height: 4),
            Text(linkName,
                style: AppText.sans(
                    size: 10.5,
                    color: AppColors.goldTextSoft,
                    weight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}
