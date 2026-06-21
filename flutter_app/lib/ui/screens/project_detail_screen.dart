import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'projects_data.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectByIdProvider(projectId));

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.ivory,
        body: Column(
          children: [
            DarkHeader(
              title: 'Project',
              leading: _backButton(context),
            ),
            const Expanded(
              child: EmptyStateView(
                message: 'Project not found.',
                icon: Icons.view_kanban_outlined,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          _ProjectDetailHeader(project: project, onBack: () => context.pop()),
          Expanded(
            child: _KanbanBoard(project: project, projectId: projectId),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left, color: AppColors.goldOnDark, size: 20),
          Text('Projects',
              style: AppText.sans(size: 14, color: AppColors.goldOnDark)),
        ],
      ),
    );
  }
}

// ── Detail header ────────────────────────────────────────────────────────────

class _ProjectDetailHeader extends StatelessWidget {
  final Project project;
  final VoidCallback onBack;

  const _ProjectDetailHeader({
    required this.project,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (project.progress * 100).round();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left,
                        color: AppColors.goldOnDark, size: 20),
                    Text('Projects',
                        style: AppText.sans(
                            size: 14, color: AppColors.goldOnDark)),
                  ],
                ),
              ),
              Row(
                children: [
                  _iconBtn(Icons.person_add_alt_1_outlined),
                  const SizedBox(width: 10),
                  _iconBtn(Icons.more_horiz),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Project name
          Text(project.name,
              style: AppText.serif(size: 22, color: AppColors.ivory)),
          const SizedBox(height: 3),
          if (project.client != null)
            Text(project.client!,
                style: AppText.sans(
                    size: 12.5, color: AppColors.mutedOnDark)),
          const SizedBox(height: 14),
          // Progress summary bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$pct% complete',
                            style: AppText.sans(
                                size: 11.5,
                                color: AppColors.goldOnDark,
                                weight: FontWeight.w600)),
                        Text(
                          '${project.doneCount}/${project.taskCount} tasks',
                          style: AppText.sans(
                              size: 11.5, color: AppColors.mutedOnDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _DarkProgressBar(value: project.progress),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Members + due date
          Row(
            children: [
              // Avatars (overlapping — Transform.translate avoids negative-inset asserts)
              ...project.members.take(5).toList().asMap().entries.map((e) {
                return Transform.translate(
                  offset: Offset(e.key == 0 ? 0 : -8.0 * e.key, 0),
                  child: AvatarDot(
                    initials: e.value.initials,
                    color: e.value.color,
                    size: 26,
                  ),
                );
              }),
              if (project.members.length > 5)
                Transform.translate(
                  offset: Offset(-8.0 * project.members.take(5).length, 0),
                  child: _extraAvatarBubble(
                      project.members.length - 5, onDark: true),
                ),
              const Spacer(),
              if (project.dueDate != null) ...[
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.mutedOnDark),
                const SizedBox(width: 5),
                Text(formatDate(project.dueDate),
                    style: AppText.sans(
                        size: 12, color: AppColors.mutedOnDark)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Icon(icon, size: 16, color: AppColors.goldOnDark),
    );
  }

  Widget _extraAvatarBubble(int count, {bool onDark = false}) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: onDark ? 0.1 : 0.6),
        shape: BoxShape.circle,
        border: Border.all(
            color: onDark ? AppColors.onyx700 : Colors.white, width: 2),
      ),
      child: Text(
        '+$count',
        style: AppText.sans(
          size: 8.5,
          color: onDark ? AppColors.mutedOnDark : AppColors.muted,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DarkProgressBar extends StatelessWidget {
  final double value;
  const _DarkProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final filled = total * value.clamp(0.0, 1.0);
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              width: filled < 6 ? 6 : filled,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Kanban board ─────────────────────────────────────────────────────────────

class _KanbanBoard extends ConsumerWidget {
  final Project project;
  final String projectId;

  const _KanbanBoard({required this.project, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const columns = KanbanColumn.values;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      itemCount: columns.length,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, i) {
        final col = columns[i];
        final tasks =
            project.tasks.where((t) => t.column == col).toList();
        return _KanbanColumn(
          column: col,
          tasks: tasks,
          onMoveTask: (taskId, newCol) {
            ref
                .read(projectsProvider.notifier)
                .moveTask(projectId, taskId, newCol);
          },
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final KanbanColumn column;
  final List<ProjectTask> tasks;
  final void Function(String taskId, KanbanColumn col) onMoveTask;

  const _KanbanColumn({
    required this.column,
    required this.tasks,
    required this.onMoveTask,
  });

  Color get _accentColor {
    switch (column) {
      case KanbanColumn.todo:
        return AppColors.muted;
      case KanbanColumn.inProgress:
        return AppColors.blue;
      case KanbanColumn.review:
        return AppColors.goldText;
      case KanbanColumn.done:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  column.label,
                  style: AppText.sans(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: AppText.sans(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: _accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Task cards
          Expanded(
            child: tasks.isEmpty
                ? _emptyColumnPlaceholder()
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TaskCard(
                      task: tasks[i],
                      onTap: () =>
                          _showTaskDetail(context, tasks[i], onMoveTask),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyColumnPlaceholder() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.hairlineSoft,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: AppColors.hairline,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          'No tasks',
          style: AppText.sans(size: 12, color: AppColors.muted),
        ),
      ),
    );
  }

  void _showTaskDetail(
    BuildContext context,
    ProjectTask task,
    void Function(String, KanbanColumn) onMoveTask,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskDetailSheet(task: task, onMoveTask: onMoveTask),
    );
  }
}

// ── Task card ────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final ProjectTask task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDone = task.column == KanbanColumn.done;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      radius: AppRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority + due date row
          Row(
            children: [
              _PriorityChip(priority: task.priority),
              const Spacer(),
              if (task.dueDate != null)
                Text(
                  _shortDate(task.dueDate!),
                  style: AppText.sans(
                    size: 10.5,
                    color: _dueDateColor(task.dueDate),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          // Title
          Text(
            task.title,
            style: AppText.sans(
              size: 13.5,
              weight: FontWeight.w600,
              color: isDone
                  ? AppColors.muted
                  : AppColors.ink,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.description != null) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 11.5, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          // Assignee
          if (task.assignee != null)
            Row(
              children: [
                AvatarDot(
                  initials: task.assignee!.initials,
                  color: task.assignee!.color,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  task.assignee!.name.split(' ').first,
                  style: AppText.sans(size: 11, color: AppColors.muted),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final now = DateTime.now();
    final diff = d.difference(now).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return '${diff}d';
    // same year: just "Jun 28"
    if (d.year == now.year) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}';
    }
    return formatDate(iso);
  }

  Color _dueDateColor(String? iso) {
    if (iso == null) return AppColors.muted;
    final d = DateTime.tryParse(iso);
    if (d == null) return AppColors.muted;
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.redOnDark;
    if (diff <= 2) return AppColors.goldTextSoft;
    return AppColors.muted;
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color c;
    Color bg;
    switch (priority) {
      case TaskPriority.urgent:
        c = AppColors.redOnDark;
        bg = AppColors.red.withValues(alpha: 0.12);
        break;
      case TaskPriority.high:
        c = AppColors.goldTextSoft;
        bg = AppColors.gold500.withValues(alpha: 0.14);
        break;
      case TaskPriority.medium:
        c = AppColors.blue;
        bg = AppColors.blue.withValues(alpha: 0.12);
        break;
      case TaskPriority.low:
        c = AppColors.muted;
        bg = AppColors.hairlineSoft;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        priority.label,
        style: AppText.sans(
          size: 9.5,
          weight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}

// ── Task detail bottom sheet ─────────────────────────────────────────────────

class _TaskDetailSheet extends StatelessWidget {
  final ProjectTask task;
  final void Function(String, KanbanColumn) onMoveTask;

  const _TaskDetailSheet({required this.task, required this.onMoveTask});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.cardLarge),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 32,
      ),
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
          const SizedBox(height: 20),
          // Priority + title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PriorityChip(priority: task.priority),
              const Spacer(),
              if (task.dueDate != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(formatDate(task.dueDate),
                        style: AppText.sans(size: 12, color: AppColors.muted)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.title,
              style: AppText.serif(size: 20, color: AppColors.ink)),
          if (task.description != null) ...[
            const SizedBox(height: 8),
            Text(task.description!,
                style: AppText.sans(
                    size: 13.5, color: AppColors.muted, height: 1.5)),
          ],
          const SizedBox(height: 18),
          // Assignee row
          if (task.assignee != null)
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Assignee',
              value: task.assignee!.name,
              avatar: AvatarDot(
                initials: task.assignee!.initials,
                color: task.assignee!.color,
                size: 22,
              ),
            ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: task.column.label,
          ),
          const SizedBox(height: 22),
          // Move to column buttons
          Text('Move to',
              style: AppText.sans(
                  size: 11,
                  color: AppColors.muted,
                  weight: FontWeight.w600,
                  letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final col in KanbanColumn.values)
                if (col != task.column)
                  _MoveChip(
                    label: col.label,
                    onTap: () {
                      onMoveTask(task.id, col);
                      Navigator.of(context).pop();
                    },
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? avatar;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Text(label,
            style: AppText.sans(size: 12.5, color: AppColors.muted)),
        const Spacer(),
        if (avatar != null) ...[avatar!, const SizedBox(width: 6)],
        Text(value,
            style: AppText.sans(
                size: 13, weight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MoveChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Text(label,
            style: AppText.sans(
                size: 12.5,
                weight: FontWeight.w600,
                color: AppColors.ink)),
      ),
    );
  }
}
