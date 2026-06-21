import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../data/repository.dart';
import '../models/models.dart';

final repositoryProvider = Provider<Repository>((ref) => repository);

/// Streams Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Current session (null = signed out).
final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return supabase.auth.currentSession;
});

/// Current user profile (from user_profiles), or a minimal fallback.
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(sessionProvider);
  final user = session?.user;
  if (user == null) return null;
  return ref.read(repositoryProvider).fetchProfile(user.id, email: user.email);
});

// ── Dashboard ───────────────────────────────────────────────
final clientCountProvider = FutureProvider<int>((ref) async {
  return ref.read(repositoryProvider).countClients();
});

final openLeadsProvider = FutureProvider<int>((ref) async {
  return ref.read(repositoryProvider).countLeadsOpen();
});

final dealsStatsProvider =
    FutureProvider<({int activeCount, double pipelineValue})>((ref) async {
  return ref.read(repositoryProvider).dealsStats();
});

// ── Deals ───────────────────────────────────────────────────
final dealsProvider = FutureProvider<List<Deal>>((ref) async {
  return ref.read(repositoryProvider).fetchDeals();
});

final dealProvider =
    FutureProvider.family<Deal?, String>((ref, id) async {
  return ref.read(repositoryProvider).fetchDeal(id);
});

/// Deals grouped by stage, in pipeline order.
final pipelineByStageProvider =
    FutureProvider<Map<String, List<Deal>>>((ref) async {
  final deals = await ref.watch(dealsProvider.future);
  final active = deals.where((d) => d.isActive).toList();
  final map = <String, List<Deal>>{};
  for (final d in active) {
    map.putIfAbsent(d.stage, () => []).add(d);
  }
  return map;
});

// ── Clients ─────────────────────────────────────────────────
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  return ref.read(repositoryProvider).fetchClients();
});

final clientProvider =
    FutureProvider.family<Client?, String>((ref, id) async {
  return ref.read(repositoryProvider).fetchClient(id);
});

// ── Tasks ───────────────────────────────────────────────────
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.read(repositoryProvider).fetchTasks();
});

final upcomingTasksProvider = FutureProvider<List<Task>>((ref) async {
  final tasks = await ref.read(repositoryProvider).fetchTasks(openOnly: true);
  return tasks.take(6).toList();
});

// ── Generic table (module screens) ──────────────────────────
final tableProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, table) async {
  return ref.read(repositoryProvider).fetchTable(table);
});
