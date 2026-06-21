import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'projects_data.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  // null = All
  ProjectStatus? _filterStatus;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Project> _filtered(List<Project> all) {
    var list = all;
    if (_filterStatus != null) {
      list = list.where((p) => p.status == _filterStatus).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.client?.toLowerCase().contains(q) ?? false) ||
            (p.owner?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final visible = _filtered(projects);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Dark header ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProjectsHeader(
                  searchCtrl: _searchCtrl,
                  onSearch: (v) => setState(() => _query = v),
                  filterStatus: _filterStatus,
                  onFilter: (s) => setState(() => _filterStatus = s),
                  projectCount: projects.length,
                ),
              ),
              // ── Body ─────────────────────────────────────────────────
              if (visible.isEmpty)
                const SliverFillRemaining(
                  child: EmptyStateView(
                    message: 'No projects match your filter.',
                    icon: Icons.view_kanban_outlined,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ProjectCard(
                            project: visible[i],
                            onTap: () =>
                                context.push('/projects/${visible[i].id}'),
                          ),
                        );
                      },
                      childCount: visible.length,
                    ),
                  ),
                ),
            ],
          ),
          // ── FAB ──────────────────────────────────────────────────────
          Positioned(
            right: 20,
            bottom: 104,
            child: GoldFab(onTap: () {}),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ProjectsHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final ProjectStatus? filterStatus;
  final ValueChanged<ProjectStatus?> onFilter;
  final int projectCount;

  const _ProjectsHeader({
    required this.searchCtrl,
    required this.onSearch,
    required this.filterStatus,
    required this.onFilter,
    required this.projectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PROJECTS',
                      style: AppText.eyebrow(AppColors.goldOnDark)),
                  const SizedBox(height: 4),
                  Text('Projects',
                      style: AppText.serif(size: 28, color: AppColors.ivory)),
                ],
              ),
              _statBubble('$projectCount', 'total'),
            ],
          ),
          const SizedBox(height: 16),
          // Search
          DarkSearchField(
            hint: 'Search projects…',
            controller: searchCtrl,
            onChanged: onSearch,
          ),
          const SizedBox(height: 14),
          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  active: filterStatus == null,
                  onTap: () => onFilter(null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  active: filterStatus == ProjectStatus.active,
                  onTap: () => onFilter(ProjectStatus.active),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'On hold',
                  active: filterStatus == ProjectStatus.onHold,
                  onTap: () => onFilter(ProjectStatus.onHold),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Done',
                  active: filterStatus == ProjectStatus.done,
                  onTap: () => onFilter(ProjectStatus.done),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _statBubble(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value,
              style: AppText.serif(size: 20, color: AppColors.gold300)),
          Text(label,
              style: AppText.sans(size: 10, color: AppColors.mutedOnDark)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 12.5,
            weight: FontWeight.w600,
            color: active ? AppColors.goldInk : AppColors.ivory,
          ),
        ),
      ),
    );
  }
}

// ── Project card ─────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = project.progress;
    final pct = (progress * 100).round();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      radius: AppRadii.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — name + status pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: AppText.serif(size: 17, color: AppColors.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              _statusPill(project.status),
            ],
          ),
          const SizedBox(height: 4),
          // Client / owner
          if (project.client != null || project.owner != null)
            Text(
              [project.client, project.owner]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 12, color: AppColors.muted),
            ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: _GoldProgressBar(value: progress),
              ),
              const SizedBox(width: 10),
              Text(
                '$pct%',
                style: AppText.sans(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.goldText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bottom row — members, due date, task count
          Row(
            children: [
              // Avatar stack
              _AvatarStack(members: project.members),
              const Spacer(),
              // Task count
              Text(
                '${project.taskCount} task${project.taskCount == 1 ? '' : 's'} · '
                '${project.doneCount} done',
                style: AppText.sans(size: 11.5, color: AppColors.muted),
              ),
              if (project.dueDate != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 12,
                  color: AppColors.hairline,
                ),
                const SizedBox(width: 10),
                Text(
                  formatDate(project.dueDate),
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(ProjectStatus status) {
    Color c;
    Color bg;
    switch (status) {
      case ProjectStatus.active:
        c = AppColors.green;
        bg = AppColors.green.withValues(alpha: 0.12);
        break;
      case ProjectStatus.onHold:
        c = AppColors.goldTextSoft;
        bg = AppColors.gold500.withValues(alpha: 0.14);
        break;
      case ProjectStatus.done:
        c = AppColors.blue;
        bg = AppColors.blue.withValues(alpha: 0.12);
        break;
    }
    return StatusPill(label: status.label, color: c, bg: bg);
  }
}

class _GoldProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _GoldProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final filled = (total * value.clamp(0.0, 1.0));
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.hairline,
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

class _AvatarStack extends StatelessWidget {
  final List<ProjectMember> members;
  const _AvatarStack({required this.members});

  static const _size = 24.0;
  static const _overlap = 10.0;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;
    final total = shown.length + (extra > 0 ? 1 : 0);
    final width = _size + (total - 1) * (_size - _overlap);

    return SizedBox(
      height: _size,
      width: width,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: AvatarDot(
                initials: shown[i].initials,
                color: shown[i].color,
                size: _size,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.hairlineSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: AppText.sans(
                    size: 8,
                    color: AppColors.muted,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
