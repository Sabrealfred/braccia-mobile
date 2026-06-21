import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/models.dart';

/// Thin data-access layer over the shared Supabase project. Mirrors the queries
/// the web staff portal performs (tables: clients, deals, tasks, user_profiles,
/// consultant_notes, …) so the mobile app is a second client over one backend.
class Repository {
  // ── Profile ───────────────────────────────────────────────
  Future<UserProfile?> fetchProfile(String userId, {String? email}) async {
    try {
      final data = await supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) return UserProfile.fromJson(data);
    } catch (_) {/* fall through to a minimal profile */}
    if (email != null) {
      return UserProfile(id: userId, email: email);
    }
    return null;
  }

  // ── Dashboard aggregates ──────────────────────────────────
  Future<int> countClients() async {
    try {
      return await supabase.from('clients').count(CountOption.exact);
    } catch (_) {
      final rows = await supabase.from('clients').select('id');
      return (rows as List).length;
    }
  }

  Future<int> countLeadsOpen() async {
    try {
      final rows =
          await supabase.from('clients').select('id').eq('status', 'prospect');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<({int activeCount, double pipelineValue})> dealsStats() async {
    final rows = await supabase.from('deals').select().eq('is_active', true);
    final deals = (rows as List).map((e) => Deal.fromJson(e)).toList();
    final total = deals.fold<double>(0, (s, d) => s + (d.dealValue ?? 0));
    return (activeCount: deals.length, pipelineValue: total);
  }

  // ── Deals ─────────────────────────────────────────────────
  Future<List<Deal>> fetchDeals({int limit = 200}) async {
    final rows = await supabase
        .from('deals')
        .select()
        .order('updated_at', ascending: false)
        .limit(limit);
    return (rows as List).map((e) => Deal.fromJson(e)).toList();
  }

  Future<Deal?> fetchDeal(String id) async {
    final row =
        await supabase.from('deals').select().eq('id', id).maybeSingle();
    return row == null ? null : Deal.fromJson(row);
  }

  Future<void> advanceDealStage(String id, String nextStage) async {
    await supabase.from('deals').update({'stage': nextStage}).eq('id', id);
  }

  // ── Clients ───────────────────────────────────────────────
  Future<List<Client>> fetchClients({int limit = 300}) async {
    final rows = await supabase
        .from('clients')
        .select()
        .order('updated_at', ascending: false)
        .limit(limit);
    return (rows as List).map((e) => Client.fromJson(e)).toList();
  }

  Future<Client?> fetchClient(String id) async {
    final row =
        await supabase.from('clients').select().eq('id', id).maybeSingle();
    return row == null ? null : Client.fromJson(row);
  }

  // ── Tasks ─────────────────────────────────────────────────
  Future<List<Task>> fetchTasks({int limit = 200, bool openOnly = false}) async {
    var q = supabase.from('tasks').select();
    if (openOnly) q = q.isFilter('completion_date', null);
    final rows = await q.order('due_date', ascending: true).limit(limit);
    return (rows as List).map((e) => Task.fromJson(e)).toList();
  }

  Future<void> setTaskDone(String id, bool done) async {
    await supabase.from('tasks').update({
      'completion_date': done ? DateTime.now().toIso8601String() : null,
      'status': done ? 'completed' : 'open',
    }).eq('id', id);
  }

  Future<void> insertTask(Map<String, dynamic> values) async {
    await supabase.from('tasks').insert(values);
  }

  // ── Generic (adaptive module screens) ─────────────────────
  /// Best-effort fetch of an arbitrary table for the module screens.
  /// Returns raw rows; the caller maps them. Never throws — returns [] on error
  /// (e.g. table not present / RLS), so every module opens something real.
  Future<List<Map<String, dynamic>>> fetchTable(
    String table, {
    int limit = 100,
    String orderBy = 'updated_at',
  }) async {
    try {
      final rows =
          await supabase.from(table).select().order(orderBy, ascending: false).limit(limit);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      try {
        final rows = await supabase.from(table).select().limit(limit);
        return (rows as List).cast<Map<String, dynamic>>();
      } catch (_) {
        return const [];
      }
    }
  }
}

final repository = Repository();
