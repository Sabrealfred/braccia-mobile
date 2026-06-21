// tasks_data.dart — Local optimistic state for TasksScreen.
// Owned exclusively by the tasks feature agent.
// Provides:
//   • A seeded demo task list (used when Supabase returns empty).
//   • Session-scoped optimistic overrides (toggles + newly-added tasks).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/repository.dart';

// ── Demo seed data ────────────────────────────────────────────────────────────

final _now = DateTime.now();

DateTime _daysAgo(int d) => _now.subtract(Duration(days: d));
DateTime _daysFrom(int d) => _now.add(Duration(days: d));

String _iso(DateTime d) => d.toIso8601String().substring(0, 10);

final List<Task> demoTasks = [
  // Overdue
  Task(
    id: 'demo-1',
    title: 'Send revised LOI — Apollo',
    status: 'open',
    priority: 'high',
    dueDate: _iso(_daysAgo(3)),
    dealId: 'deal-apollo',
    raw: {'assignee': 'Sofia P.', 'deal_name': 'Apollo · \$24M'},
  ),
  Task(
    id: 'demo-2',
    title: 'Review KYC documents — Atlas Mining',
    status: 'open',
    priority: 'high',
    dueDate: _iso(_daysAgo(1)),
    clientId: 'client-atlas',
    raw: {'assignee': 'Raj M.', 'client_name': 'Atlas Mining Ltd'},
  ),
  Task(
    id: 'demo-3',
    title: 'Follow up on term sheet — Meridian Group',
    status: 'open',
    priority: 'medium',
    dueDate: _iso(_daysAgo(5)),
    dealId: 'deal-meridian',
    raw: {'assignee': 'Sofia P.', 'deal_name': 'Meridian · \$18M'},
  ),
  // Today
  Task(
    id: 'demo-4',
    title: 'Prep IC memo — Quantum Capital',
    status: 'open',
    priority: 'high',
    dueDate: _iso(_now),
    dealId: 'deal-quantum',
    raw: {'assignee': 'You', 'deal_name': 'Quantum · \$45M'},
  ),
  Task(
    id: 'demo-5',
    title: 'Schedule call — Chen Family Office',
    status: 'open',
    priority: 'medium',
    dueDate: _iso(_now),
    clientId: 'client-chen',
    raw: {'assignee': 'Raj M.', 'client_name': 'Chen Family Office'},
  ),
  Task(
    id: 'demo-6',
    title: 'Update pipeline deck with Q3 figures',
    status: 'open',
    priority: 'low',
    dueDate: _iso(_now),
    raw: {'assignee': 'You'},
  ),
  // Upcoming
  Task(
    id: 'demo-7',
    title: 'Annual review meeting — Innovation Labs',
    status: 'open',
    priority: 'medium',
    dueDate: _iso(_daysFrom(2)),
    clientId: 'client-innov',
    raw: {'assignee': 'Sofia P.', 'client_name': 'Innovation Labs'},
  ),
  Task(
    id: 'demo-8',
    title: 'Draft subscription agreement — Growth Fund II',
    status: 'open',
    priority: 'high',
    dueDate: _iso(_daysFrom(4)),
    dealId: 'deal-growth2',
    raw: {'assignee': 'You', 'deal_name': 'Growth Fund II'},
  ),
  Task(
    id: 'demo-9',
    title: 'Send NDA — new inbound LP',
    status: 'open',
    priority: 'low',
    dueDate: _iso(_daysFrom(7)),
    raw: {'assignee': 'Raj M.'},
  ),
  Task(
    id: 'demo-10',
    title: 'Quarterly LP report — Braccia Fund I',
    status: 'open',
    priority: 'medium',
    dueDate: _iso(_daysFrom(10)),
    raw: {'assignee': 'Sofia P.'},
  ),
  // Completed
  Task(
    id: 'demo-11',
    title: 'Complete onboarding — Quantum Capital',
    status: 'completed',
    priority: 'high',
    dueDate: _iso(_daysAgo(7)),
    completionDate: _iso(_daysAgo(6)),
    clientId: 'client-quantum',
    raw: {'assignee': 'You', 'client_name': 'Quantum Capital'},
  ),
  Task(
    id: 'demo-12',
    title: 'File Q2 compliance reports',
    status: 'completed',
    priority: 'high',
    dueDate: _iso(_daysAgo(14)),
    completionDate: _iso(_daysAgo(13)),
    raw: {'assignee': 'Raj M.'},
  ),
  Task(
    id: 'demo-13',
    title: 'Board deck — Atlas Series B',
    status: 'completed',
    priority: 'medium',
    dueDate: _iso(_daysAgo(10)),
    completionDate: _iso(_daysAgo(10)),
    dealId: 'deal-atlas-b',
    raw: {'assignee': 'Sofia P.', 'deal_name': 'Atlas Series B'},
  ),
];

// ── Optimistic override state ─────────────────────────────────────────────────

/// Holds session-scoped overrides so toggles and new tasks survive provider
/// invalidation within the same session.
class TasksOverrideNotifier extends StateNotifier<_TasksOverride> {
  TasksOverrideNotifier() : super(const _TasksOverride());

  /// Mark / unmark a task done (optimistic). Attempt Supabase write too.
  Future<void> toggleDone(String id, bool done) async {
    state = state.withToggle(id, done);
    try {
      await repository.setTaskDone(id, done);
    } catch (_) {
      // Graceful degradation — local state already updated.
    }
  }

  /// Optimistically prepend a newly created task.
  void addTask(Task t) {
    state = state.withAdded(t);
  }

  /// Attempt to write to Supabase; adds optimistically regardless.
  Future<void> insertAndAdd(Map<String, dynamic> values, Task optimistic) async {
    addTask(optimistic);
    try {
      await repository.insertTask(values);
    } catch (_) {
      // Graceful degradation.
    }
  }
}

class _TasksOverride {
  /// id → isDone override (true/false).
  final Map<String, bool> doneOverrides;

  /// Tasks added this session (prepended to the list).
  final List<Task> addedTasks;

  const _TasksOverride({
    this.doneOverrides = const {},
    this.addedTasks = const [],
  });

  _TasksOverride withToggle(String id, bool done) => _TasksOverride(
        doneOverrides: {...doneOverrides, id: done},
        addedTasks: addedTasks,
      );

  _TasksOverride withAdded(Task t) => _TasksOverride(
        doneOverrides: doneOverrides,
        addedTasks: [t, ...addedTasks],
      );
}

final tasksOverrideProvider =
    StateNotifierProvider<TasksOverrideNotifier, _TasksOverride>(
  (ref) => TasksOverrideNotifier(),
);

// ── Merged task list provider ─────────────────────────────────────────────────

/// Merges Supabase data (or demo seed) with session-local overrides.
final mergedTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final remote = ref.watch(tasksProvider);
  final override = ref.watch(tasksOverrideProvider);

  return remote.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) {
      // On error, fall back to demo data.
      final merged = _applyOverrides(demoTasks, override);
      return AsyncValue.data(merged);
    },
    data: (tasks) {
      final base = tasks.isEmpty ? demoTasks : tasks;
      final merged = _applyOverrides([...override.addedTasks, ...base], override);
      return AsyncValue.data(merged);
    },
  );
});

List<Task> _applyOverrides(List<Task> tasks, _TasksOverride o) {
  if (o.doneOverrides.isEmpty) return tasks;
  return tasks.map((t) {
    final override = o.doneOverrides[t.id];
    if (override == null) return t;
    return Task(
      id: t.id,
      title: t.title,
      status: override ? 'completed' : 'open',
      priority: t.priority,
      dueDate: t.dueDate,
      completionDate: override ? DateTime.now().toIso8601String() : null,
      dealId: t.dealId,
      clientId: t.clientId,
      updatedAt: t.updatedAt,
      raw: t.raw,
    );
  }).toList();
}
