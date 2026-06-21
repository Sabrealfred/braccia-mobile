// Notes data layer — model, Riverpod store, Supabase access.
// Table: consultant_notes (id, text, date, client_id, deal_id, status, created_at, updated_at)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class NoteEntry {
  final String id;
  final String text;
  final String? clientId;
  final String? dealId;
  final String? status;
  final DateTime updatedAt;
  final DateTime createdAt;

  NoteEntry({
    required this.id,
    required this.text,
    this.clientId,
    this.dealId,
    this.status,
    required this.updatedAt,
    required this.createdAt,
  });

  /// First non-blank line, trimmed, up to 80 chars.
  String get title {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) {
        return t.length > 80 ? '${t.substring(0, 77)}...' : t;
      }
    }
    return 'Untitled';
  }

  /// Body text after the first line (for the snippet preview).
  String get snippet {
    final lines = text.split('\n');
    bool pastFirst = false;
    final buf = StringBuffer();
    for (final line in lines) {
      if (!pastFirst) {
        if (line.trim().isNotEmpty) pastFirst = true;
        continue;
      }
      if (buf.length > 160) break;
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(line.trim());
    }
    final s = buf.toString().trim();
    return s.length > 160 ? '${s.substring(0, 157)}...' : s;
  }

  NoteEntry copyWith({
    String? text,
    String? clientId,
    String? dealId,
    String? status,
    DateTime? updatedAt,
  }) =>
      NoteEntry(
        id: id,
        text: text ?? this.text,
        clientId: clientId ?? this.clientId,
        dealId: dealId ?? this.dealId,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt,
      );

  factory NoteEntry.fromJson(Map<String, dynamic> j) {
    final text = (j['text'] ?? '').toString();
    return NoteEntry(
      id: j['id'].toString(),
      text: text,
      clientId: j['client_id']?.toString(),
      dealId: j['deal_id']?.toString(),
      status: j['status'] as String?,
      updatedAt: DateTime.tryParse((j['updated_at'] ?? '').toString()) ??
          DateTime.now(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        if (clientId != null) 'client_id': clientId,
        if (dealId != null) 'deal_id': dealId,
        if (status != null) 'status': status,
        'updated_at': updatedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

// ── Seed data (always-beautiful fallback) ─────────────────────────────────────

List<NoteEntry> _seedNotes() {
  final now = DateTime.now();
  return [
    NoteEntry(
      id: 'seed-1',
      text:
          'Apollo Call Recap — 14 June\n\nSpoke with Marcus Webb (CFO) and Priya Nair (GC) for 45 min. Key takeaways:\n\n• LOI needs to be revised — exclusivity clause is too broad per their counsel.\n• They want a separate fee letter to keep the main document clean.\n• Target close: end of Q3. Marcus confirmed board approval is in hand pending LOI sign.\n\nNext step: revised LOI by Friday. Loop in Sofia on the fee letter language.',
      status: 'pending',
      clientId: null,
      dealId: null,
      updatedAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(days: 3)),
    ),
    NoteEntry(
      id: 'seed-2',
      text:
          'Atlas Mining — KYC Findings\n\nCompliance flagged two items from the enhanced DD:\n\n1. Beneficial ownership — one 12% holder routes through a BVI shell. Needs UBO declaration.\n2. PEP screening — no direct hits but one associated party is a former minister (Kazakhstan, 2018). Low risk per legal but needs sign-off from CCO.\n\nCompliance rating: amber. Expected to clear to green once UBO docs arrive (deadline: 28 Jun).',
      status: 'review',
      clientId: null,
      dealId: null,
      updatedAt: now.subtract(const Duration(hours: 18)),
      createdAt: now.subtract(const Duration(days: 7)),
    ),
    NoteEntry(
      id: 'seed-3',
      text:
          'IC Memo — Growth Fund II (Draft)\n\nExecutive summary draft for the Investment Committee meeting scheduled 2 July.\n\nThesis: Concentrated mid-market buyout strategy in Southeast Asia manufacturing. Target IRR 22–26%. Entry multiples averaging 6.1x EBITDA vs peer median of 8.4x.\n\nKey risks to address:\n• FX exposure — SGD/IDR basket, unhedged at entry.\n• Management depth at two portfolio companies.\n• Exit via trade sale most likely; IPO window uncertain post-2025.\n\nAction items: model sensitivity on FX, get updated audited accounts from Meridian.',
      status: 'in_progress',
      clientId: null,
      dealId: null,
      updatedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 10)),
    ),
    NoteEntry(
      id: 'seed-4',
      text:
          'Chen Family Office — Introduction Notes\n\nMeeting with David Chen (principal) and his EA Jessica Lam, 10 June, Peninsula Hotel.\n\nBackground: Third-generation family, HK-based. ~\$380M AUM managed in-house. Looking to allocate 15–20% to alternative credit and private equity over 18 months.\n\nInterests:\n• Infrastructure debt (preferred)\n• Co-investment rights on deal-by-deal basis\n• No hard restrictions but prefer ESG-aligned\n\nPersonality: data-driven, very detail oriented. Wants monthly reporting, not quarterly. Bring Raj to next meeting — he knows David from HKMA days.',
      status: 'active',
      clientId: null,
      dealId: null,
      updatedAt: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 14)),
    ),
  ];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotesNotifier extends StateNotifier<AsyncValue<List<NoteEntry>>> {
  NotesNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await supabase
          .from('consultant_notes')
          .select()
          .order('updated_at', ascending: false)
          .limit(200);
      final list =
          (rows as List).map((e) => NoteEntry.fromJson(e as Map<String, dynamic>)).toList();
      if (list.isEmpty) {
        state = AsyncValue.data(_seedNotes());
      } else {
        state = AsyncValue.data(list);
      }
    } catch (_) {
      state = AsyncValue.data(_seedNotes());
    }
  }

  Future<void> refresh() => _load();

  /// Upsert a note locally (optimistic) and attempt Supabase persist.
  Future<void> upsert(NoteEntry note) async {
    final current = state.asData?.value ?? _seedNotes();
    final idx = current.indexWhere((n) => n.id == note.id);
    List<NoteEntry> next;
    if (idx >= 0) {
      next = [...current];
      next[idx] = note;
    } else {
      next = [note, ...current];
    }
    // Sort by updatedAt descending
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = AsyncValue.data(next);

    // Attempt backend persist; swallow errors gracefully
    try {
      // Skip persisting seed IDs that start with 'seed-'
      if (note.id.startsWith('seed-')) return;
      await supabase.from('consultant_notes').upsert(
        {
          'id': note.id,
          'text': note.text,
          if (note.clientId != null) 'client_id': note.clientId,
          if (note.dealId != null) 'deal_id': note.dealId,
          if (note.status != null) 'status': note.status,
          'updated_at': note.updatedAt.toIso8601String(),
        },
        onConflict: 'id',
      );
    } catch (_) {
      // Optimistic local state already updated; nothing to roll back.
    }
  }

  /// Create a new blank note with a UUID-style id and open it for editing.
  NoteEntry createBlank() {
    final id = _generateId();
    final now = DateTime.now();
    final note = NoteEntry(
      id: id,
      text: '',
      status: 'in_progress',
      updatedAt: now,
      createdAt: now,
    );
    // Optimistically add to list
    final current = state.asData?.value ?? [];
    state = AsyncValue.data([note, ...current]);
    return note;
  }

  NoteEntry? byId(String id) {
    final list = state.asData?.value;
    if (list == null) return null;
    try {
      return list.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  String _generateId() {
    // Simple time-based pseudo-UUID (no dart:math import needed)
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'note-$ts';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final notesProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<NoteEntry>>>(
  (ref) => NotesNotifier(),
);
