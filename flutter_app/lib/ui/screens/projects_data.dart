// Projects data layer — models, seed data, and Riverpod store.
// Owned by the projects feature agent. Do NOT edit from other screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';

// ── Domain models ────────────────────────────────────────────────────────────

enum ProjectStatus { active, onHold, done }

extension ProjectStatusX on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On hold';
      case ProjectStatus.done:
        return 'Done';
    }
  }

  String get key {
    switch (this) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.onHold:
        return 'on_hold';
      case ProjectStatus.done:
        return 'done';
    }
  }

  static ProjectStatus fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'done':
      case 'completed':
        return ProjectStatus.done;
      case 'on_hold':
      case 'onhold':
      case 'on hold':
        return ProjectStatus.onHold;
      default:
        return ProjectStatus.active;
    }
  }
}

class ProjectMember {
  final String id;
  final String name;
  final Color color;

  const ProjectMember({
    required this.id,
    required this.name,
    required this.color,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  static TaskPriority fromString(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'urgent':
      case 'critical':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

enum KanbanColumn { todo, inProgress, review, done }

extension KanbanColumnX on KanbanColumn {
  String get label {
    switch (this) {
      case KanbanColumn.todo:
        return 'To do';
      case KanbanColumn.inProgress:
        return 'In progress';
      case KanbanColumn.review:
        return 'Review';
      case KanbanColumn.done:
        return 'Done';
    }
  }

  static KanbanColumn fromString(String? s) {
    switch ((s ?? '').toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'in_progress':
      case 'inprogress':
      case 'doing':
        return KanbanColumn.inProgress;
      case 'review':
      case 'in_review':
        return KanbanColumn.review;
      case 'done':
      case 'completed':
        return KanbanColumn.done;
      default:
        return KanbanColumn.todo;
    }
  }
}

class ProjectTask {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final KanbanColumn column;
  final ProjectMember? assignee;
  final String? dueDate;

  const ProjectTask({
    required this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.column = KanbanColumn.todo,
    this.assignee,
    this.dueDate,
  });

  ProjectTask copyWith({KanbanColumn? column}) {
    return ProjectTask(
      id: id,
      title: title,
      description: description,
      priority: priority,
      column: column ?? this.column,
      assignee: assignee,
      dueDate: dueDate,
    );
  }
}

class Project {
  final String id;
  final String name;
  final String? client;
  final String? owner;
  final ProjectStatus status;
  final List<ProjectMember> members;
  final List<ProjectTask> tasks;
  final String? dueDate;
  final String? description;

  const Project({
    required this.id,
    required this.name,
    this.client,
    this.owner,
    this.status = ProjectStatus.active,
    this.members = const [],
    this.tasks = const [],
    this.dueDate,
    this.description,
  });

  int get taskCount => tasks.length;
  int get doneCount => tasks.where((t) => t.column == KanbanColumn.done).length;
  double get progress => taskCount == 0 ? 0 : doneCount / taskCount;

  Project copyWith({List<ProjectTask>? tasks}) {
    return Project(
      id: id,
      name: name,
      client: client,
      owner: owner,
      status: status,
      members: members,
      tasks: tasks ?? this.tasks,
      dueDate: dueDate,
      description: description,
    );
  }
}

// ── Seed data ────────────────────────────────────────────────────────────────

final _memberSofia = ProjectMember(
  id: 'm1',
  name: 'Sofia Pereira',
  color: const Color(0xFF5B7FA5),
);
final _memberRaj = ProjectMember(
  id: 'm2',
  name: 'Raj Mehta',
  color: const Color(0xFF7A5F7D),
);
final _memberElla = ProjectMember(
  id: 'm3',
  name: 'Ella Chen',
  color: const Color(0xFF2E7D65),
);
final _memberLuca = ProjectMember(
  id: 'm4',
  name: 'Luca Rossi',
  color: const Color(0xFFC79A3E),
);
final _memberKira = ProjectMember(
  id: 'm5',
  name: 'Kira Novak',
  color: const Color(0xFFC0473D),
);

List<Project> _buildSeedProjects() {
  return [
    Project(
      id: 'proj-1',
      name: 'Apollo Acquisition',
      client: 'Apollo Capital Partners',
      owner: 'Sofia Pereira',
      status: ProjectStatus.active,
      members: [_memberSofia, _memberRaj, _memberElla],
      dueDate: '2026-08-15',
      description: 'Full acquisition workstream for Apollo Capital Partners.',
      tasks: [
        ProjectTask(
          id: 't1-1',
          title: 'Send revised LOI to Apollo',
          priority: TaskPriority.urgent,
          column: KanbanColumn.todo,
          assignee: _memberSofia,
          dueDate: '2026-06-25',
        ),
        ProjectTask(
          id: 't1-2',
          title: 'Update deal valuation model',
          priority: TaskPriority.high,
          column: KanbanColumn.inProgress,
          assignee: _memberRaj,
          dueDate: '2026-06-28',
        ),
        ProjectTask(
          id: 't1-3',
          title: 'Legal review of term sheet',
          priority: TaskPriority.high,
          column: KanbanColumn.review,
          assignee: _memberElla,
          dueDate: '2026-07-02',
        ),
        ProjectTask(
          id: 't1-4',
          title: 'Schedule management presentation',
          priority: TaskPriority.medium,
          column: KanbanColumn.todo,
          assignee: _memberSofia,
          dueDate: '2026-07-05',
        ),
        ProjectTask(
          id: 't1-5',
          title: 'Initial due diligence checklist',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberRaj,
        ),
        ProjectTask(
          id: 't1-6',
          title: 'NDA signed & filed',
          priority: TaskPriority.medium,
          column: KanbanColumn.done,
          assignee: _memberElla,
        ),
        ProjectTask(
          id: 't1-7',
          title: 'Kick-off call with Apollo team',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberSofia,
        ),
      ],
    ),
    Project(
      id: 'proj-2',
      name: 'Atlas KYC Remediation',
      client: 'Atlas Mining Ltd',
      owner: 'Raj Mehta',
      status: ProjectStatus.active,
      members: [_memberRaj, _memberKira],
      dueDate: '2026-07-30',
      description: 'KYC remediation programme across Atlas entity network.',
      tasks: [
        ProjectTask(
          id: 't2-1',
          title: 'Collect updated beneficial owner docs',
          priority: TaskPriority.urgent,
          column: KanbanColumn.inProgress,
          assignee: _memberKira,
          dueDate: '2026-06-27',
        ),
        ProjectTask(
          id: 't2-2',
          title: 'Re-screen entities against PEP list',
          priority: TaskPriority.high,
          column: KanbanColumn.inProgress,
          assignee: _memberRaj,
          dueDate: '2026-06-30',
        ),
        ProjectTask(
          id: 't2-3',
          title: 'File updated compliance report',
          priority: TaskPriority.high,
          column: KanbanColumn.todo,
          assignee: _memberRaj,
          dueDate: '2026-07-10',
        ),
        ProjectTask(
          id: 't2-4',
          title: 'Sign-off from compliance committee',
          priority: TaskPriority.medium,
          column: KanbanColumn.todo,
          assignee: _memberKira,
        ),
        ProjectTask(
          id: 't2-5',
          title: 'Initial entity mapping completed',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberRaj,
        ),
        ProjectTask(
          id: 't2-6',
          title: 'Engagement letter signed',
          priority: TaskPriority.medium,
          column: KanbanColumn.done,
          assignee: _memberKira,
        ),
      ],
    ),
    Project(
      id: 'proj-3',
      name: 'Q3 Fund II Raise',
      client: 'Braccia Capital (Internal)',
      owner: 'Ella Chen',
      status: ProjectStatus.active,
      members: [_memberElla, _memberLuca, _memberSofia, _memberRaj],
      dueDate: '2026-09-30',
      description: 'Series B fundraise targeting \$200M close by Q3.',
      tasks: [
        ProjectTask(
          id: 't3-1',
          title: 'Prepare investor deck v3',
          priority: TaskPriority.high,
          column: KanbanColumn.inProgress,
          assignee: _memberElla,
          dueDate: '2026-07-01',
        ),
        ProjectTask(
          id: 't3-2',
          title: 'LP roadshow — New York',
          priority: TaskPriority.high,
          column: KanbanColumn.todo,
          assignee: _memberLuca,
          dueDate: '2026-07-15',
        ),
        ProjectTask(
          id: 't3-3',
          title: 'LP roadshow — London',
          priority: TaskPriority.medium,
          column: KanbanColumn.todo,
          assignee: _memberSofia,
          dueDate: '2026-08-05',
        ),
        ProjectTask(
          id: 't3-4',
          title: 'Legal fund docs review',
          priority: TaskPriority.medium,
          column: KanbanColumn.review,
          assignee: _memberRaj,
          dueDate: '2026-07-20',
        ),
        ProjectTask(
          id: 't3-5',
          title: 'First close target anchors secured',
          priority: TaskPriority.urgent,
          column: KanbanColumn.inProgress,
          assignee: _memberElla,
          dueDate: '2026-07-31',
        ),
        ProjectTask(
          id: 't3-6',
          title: 'Fund strategy memo published',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberLuca,
        ),
        ProjectTask(
          id: 't3-7',
          title: 'Target LP list compiled',
          priority: TaskPriority.medium,
          column: KanbanColumn.done,
          assignee: _memberElla,
        ),
        ProjectTask(
          id: 't3-8',
          title: 'GP commitment confirmed',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberSofia,
        ),
        ProjectTask(
          id: 't3-9',
          title: 'Audited accounts prepared',
          priority: TaskPriority.medium,
          column: KanbanColumn.done,
          assignee: _memberRaj,
        ),
      ],
    ),
    Project(
      id: 'proj-4',
      name: 'Wealth Map Rollout',
      client: 'Meridian Group',
      owner: 'Luca Rossi',
      status: ProjectStatus.onHold,
      members: [_memberLuca, _memberKira],
      dueDate: '2026-10-31',
      description: 'Digital wealth mapping deployment across Meridian Group entities.',
      tasks: [
        ProjectTask(
          id: 't4-1',
          title: 'Platform integration spec',
          priority: TaskPriority.medium,
          column: KanbanColumn.todo,
          assignee: _memberLuca,
        ),
        ProjectTask(
          id: 't4-2',
          title: 'Stakeholder sign-off on scope',
          priority: TaskPriority.high,
          column: KanbanColumn.todo,
          assignee: _memberKira,
        ),
        ProjectTask(
          id: 't4-3',
          title: 'UAT environment setup',
          priority: TaskPriority.medium,
          column: KanbanColumn.todo,
          assignee: _memberLuca,
        ),
        ProjectTask(
          id: 't4-4',
          title: 'Discovery workshop completed',
          priority: TaskPriority.low,
          column: KanbanColumn.done,
          assignee: _memberKira,
        ),
      ],
    ),
  ];
}

// ── Supabase mapping ─────────────────────────────────────────────────────────

Project _projectFromRow(Map<String, dynamic> row) {
  final status = ProjectStatusX.fromString(row['status'] as String?);
  return Project(
    id: row['id']?.toString() ?? '',
    name: (row['name'] ?? row['title'] ?? 'Untitled').toString(),
    client: row['client']?.toString() ?? row['client_name']?.toString(),
    owner: row['owner']?.toString() ?? row['owner_name']?.toString(),
    status: status,
    dueDate: row['due_date']?.toString() ?? row['end_date']?.toString(),
    description: row['description']?.toString(),
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ProjectsNotifier extends StateNotifier<List<Project>> {
  ProjectsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    // Try Supabase first
    try {
      final rows = await supabase
          .from('projects')
          .select()
          .order('updated_at', ascending: false)
          .limit(100);
      final fetched = (rows as List).cast<Map<String, dynamic>>();
      if (fetched.isNotEmpty) {
        state = fetched.map(_projectFromRow).toList();
        return;
      }
    } catch (_) {
      // table absent / RLS — fall through
    }
    // Fall back to rich seed data
    state = _buildSeedProjects();
  }

  Future<void> refresh() => _load();

  /// Move a task to a different kanban column (optimistic + best-effort persist).
  void moveTask(String projectId, String taskId, KanbanColumn newCol) {
    state = [
      for (final p in state)
        if (p.id == projectId)
          p.copyWith(
            tasks: [
              for (final t in p.tasks)
                if (t.id == taskId) t.copyWith(column: newCol) else t,
            ],
          )
        else
          p,
    ];
    // Best-effort persist
    _persistTaskColumn(taskId, newCol);
  }

  Future<void> _persistTaskColumn(String taskId, KanbanColumn col) async {
    try {
      await supabase.from('tasks').update({'status': col.label.toLowerCase()}).eq('id', taskId);
    } catch (_) {/* silently degrade */}
  }

  Project? findById(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<Project>>(
  (_) => ProjectsNotifier(),
);

final projectByIdProvider = Provider.family<Project?, String>((ref, id) {
  return ref.watch(projectsProvider).cast<Project?>().firstWhere(
        (p) => p?.id == id,
        orElse: () => null,
      );
});
