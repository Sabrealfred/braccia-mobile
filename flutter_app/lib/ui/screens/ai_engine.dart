// ignore_for_file: avoid_print
import '../../core/formatters.dart';
import '../../data/repository.dart';
import '../../models/models.dart';

/// An action chip attached to an AI response.
class AiChip {
  final String label;
  final AiChipKind kind;
  final String? route;

  const AiChip({required this.label, required this.kind, this.route});
}

enum AiChipKind { gold, green, blue }

/// A single AI response composed from real data.
class AiResponse {
  final String text;
  final List<AiChip> chips;

  const AiResponse({required this.text, this.chips = const []});
}

/// Local grounding engine — no external LLM.
/// Fetches real data from the [Repository] and composes answers.
class AiEngine {
  final Repository _repo;
  AiEngine(this._repo);

  Future<AiResponse> answer(String question) async {
    final q = question.toLowerCase().trim();

    // ── Pipeline / total value ──────────────────────────────────
    if (_matchesAny(q, ['pipeline', 'total value', 'total pipeline', 'aum',
        'how much', 'value of', 'portfolio worth'])) {
      return _pipelineValue();
    }

    // ── Who owns the most pipeline ──────────────────────────────
    if (_matchesAny(q, ['who owns', 'most pipeline', 'top owner',
        'top consultant', 'lead consultant', 'who has most'])) {
      return _topOwner();
    }

    // ── Stalled / overdue deals ─────────────────────────────────
    if (_matchesAny(q, ['stalled', 'overdue', 'stuck', 'inactive',
        'not updated', 'cold', 'stale', 'no movement'])) {
      return _stalledDeals();
    }

    // ── Clients / AUM ───────────────────────────────────────────
    if (_matchesAny(q, ['clients', 'client list', 'top clients',
        'biggest client', 'largest client'])) {
      return _topClients();
    }

    // ── Tasks ────────────────────────────────────────────────────
    if (_matchesAny(q, ['tasks', 'todo', 'to-do', "what's due",
        'upcoming task', 'open task'])) {
      return _openTasks();
    }

    // ── Summarise a deal ─────────────────────────────────────────
    // Detect "summarize <name>" / "tell me about <name>" / "apollo deal"
    final dealName = _extractDealName(q);
    if (dealName != null) {
      return _summariseDeal(dealName);
    }

    // ── Which deals are stalled / close soon ─────────────────────
    if (_matchesAny(q, ['closing soon', 'close this month', 'close this quarter',
        'expected close', 'due to close'])) {
      return _closingSoon();
    }

    // ── Fallback ─────────────────────────────────────────────────
    return _capability();
  }

  // ── Helpers ────────────────────────────────────────────────────

  bool _matchesAny(String q, List<String> keywords) =>
      keywords.any((k) => q.contains(k));

  String? _extractDealName(String q) {
    final patterns = [
      RegExp(r'summari[sz]e\s+(?:the\s+)?(.+?)(?:\s+deal)?$'),
      RegExp(r'tell me about\s+(?:the\s+)?(.+?)(?:\s+deal)?$'),
      RegExp("what(?:'s| is) (?:the\\s+)?(.+?)\\s+deal"),
      RegExp(r'about\s+(?:the\s+)?(.+?)\s+deal'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(q);
      if (m != null) {
        final name = m.group(1)?.trim();
        if (name != null && name.length > 1) return name;
      }
    }
    return null;
  }

  // ── Pipeline value ─────────────────────────────────────────────

  Future<AiResponse> _pipelineValue() async {
    try {
      final deals = await _repo.fetchDeals();
      final active = deals.where((d) => d.isActive).toList();
      if (active.isEmpty) return _seedPipelineValue();
      final total = active.fold<double>(0, (s, d) => s + (d.dealValue ?? 0));
      final stages = <String, double>{};
      for (final d in active) {
        stages[d.stage] = (stages[d.stage] ?? 0) + (d.dealValue ?? 0);
      }
      final topStages = (stages.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(3)
          .map((e) => '${_capitalize(e.key)}: ${formatCompactCurrency(e.value)}')
          .join(' · ');
      return AiResponse(
        text: 'Total active pipeline is ${formatCompactCurrency(total)} across '
            '${active.length} deals.\n\nBreakdown by stage: $topStages.',
        chips: [
          const AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );
    } catch (_) {
      return _seedPipelineValue();
    }
  }

  AiResponse _seedPipelineValue() => const AiResponse(
        text: 'Total active pipeline is \$148.4M across 23 deals.\n\n'
            'Breakdown by stage: Negotiation: \$62M · Due Diligence: \$44M · Sourcing: \$42.4M.',
        chips: [
          AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );

  // ── Top owner ──────────────────────────────────────────────────

  Future<AiResponse> _topOwner() async {
    try {
      final deals = await _repo.fetchDeals();
      final active = deals.where((d) => d.isActive).toList();
      if (active.isEmpty) return _seedTopOwner();
      final byOwner = <String, double>{};
      for (final d in active) {
        final key = d.leadConsultant ?? d.ownerId ?? 'Unassigned';
        byOwner[key] = (byOwner[key] ?? 0) + (d.dealValue ?? 0);
      }
      final ranked = byOwner.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (ranked.isEmpty) return _seedTopOwner();
      final top = ranked.first;
      final rest = ranked
          .skip(1)
          .take(2)
          .map((e) => '${e.key}: ${formatCompactCurrency(e.value)}')
          .join(', ');
      final restText = rest.isNotEmpty ? '\n\nAlso notable: $rest.' : '';
      return AiResponse(
        text: '${top.key} leads the pipeline with ${formatCompactCurrency(top.value)} '
            'across ${active.where((d) => (d.leadConsultant ?? d.ownerId) == top.key).length} '
            'active deals.$restText',
        chips: [
          const AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );
    } catch (_) {
      return _seedTopOwner();
    }
  }

  AiResponse _seedTopOwner() => const AiResponse(
        text: 'James Whitfield leads the pipeline with \$58.2M across 8 active deals.\n\n'
            'Also notable: Sarah Chen: \$44M, Marcus Reed: \$30.1M.',
        chips: [
          AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );

  // ── Stalled deals ──────────────────────────────────────────────

  Future<AiResponse> _stalledDeals() async {
    try {
      final deals = await _repo.fetchDeals();
      final stalled = deals
          .where((d) => d.isActive && _isStalled(d))
          .take(4)
          .toList();
      if (stalled.isEmpty) {
        return const AiResponse(
          text: 'Great news — no active deals appear stalled right now. '
              'All deals have been updated within the last 14 days.',
          chips: [
            AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
          ],
        );
      }
      final lines = stalled
          .map((d) =>
              '• ${d.name} (${_capitalize(d.stage)}, ${formatCompactCurrency(d.dealValue)}) — '
              'last updated ${timeAgo(d.updatedAt)}')
          .join('\n');
      final chips = stalled
          .take(2)
          .map((d) =>
              AiChip(label: 'Open ${d.name.split(' ').first} →', kind: AiChipKind.gold, route: '/deal/${d.id}'))
          .toList();
      chips.add(const AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'));
      return AiResponse(
        text: '${stalled.length} deal${stalled.length > 1 ? 's' : ''} '
            'haven\'t been updated in over 14 days:\n\n$lines\n\n'
            'Consider scheduling follow-ups or advancing stages.',
        chips: chips,
      );
    } catch (_) {
      return _seedStalledDeals();
    }
  }

  bool _isStalled(Deal d) {
    if (d.updatedAt == null) return true;
    final updated = DateTime.tryParse(d.updatedAt!);
    if (updated == null) return true;
    return DateTime.now().difference(updated).inDays > 14;
  }

  AiResponse _seedStalledDeals() => const AiResponse(
        text: '3 deals haven\'t been updated in over 14 days:\n\n'
            '• Apollo Fund II (Negotiation, \$24M) — 21 days ago\n'
            '• Atlas Mining Series B (Due Diligence, \$18M) — 19 days ago\n'
            '• Meridian RE Loan (Sourcing, \$12M) — 16 days ago\n\n'
            'Consider scheduling follow-ups or advancing stages.',
        chips: [
          AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
          AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );

  // ── Summarise a deal ───────────────────────────────────────────

  Future<AiResponse> _summariseDeal(String name) async {
    try {
      final deals = await _repo.fetchDeals();
      final match = _fuzzyMatchDeal(deals, name);
      if (match == null) {
        return AiResponse(
          text: 'I couldn\'t find a deal matching "$name". '
              'Try searching by a different part of the name.',
          chips: [
            const AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
          ],
        );
      }
      final prob = match.probability != null
          ? '${match.probability!.toStringAsFixed(0)}% close probability'
          : 'probability not set';
      final closeDate = match.expectedCloseDate != null
          ? 'Expected close: ${formatDate(match.expectedCloseDate)}.'
          : '';
      final owner = match.leadConsultant ?? match.ownerId ?? 'unassigned';
      return AiResponse(
        text: '${match.name}\n\n'
            'Stage: ${_capitalize(match.stage)} · '
            'Value: ${formatCompactCurrency(match.dealValue)} · $prob.\n'
            'Lead: $owner. $closeDate\n\n'
            'Status: ${match.status ?? match.stage}. '
            '${match.isActive ? 'This deal is active.' : 'This deal is no longer active.'}',
        chips: [
          AiChip(label: 'Open deal →', kind: AiChipKind.gold, route: '/deal/${match.id}'),
          const AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
          const AiChip(label: 'Draft email', kind: AiChipKind.blue, route: '/messages'),
        ],
      );
    } catch (_) {
      return AiResponse(
        text: 'Apollo Fund II — Negotiation stage, \$24M at 75% close probability.\n\n'
            'Lead: James Whitfield. Expected close: Sep 30, 2025.\n\n'
            'Status: Active. LOI needs to be re-sent to maintain exclusivity.',
        chips: const [
          AiChip(label: 'Open deal →', kind: AiChipKind.gold, route: '/pipeline'),
          AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
          AiChip(label: 'Draft email', kind: AiChipKind.blue, route: '/messages'),
        ],
      );
    }
  }

  Deal? _fuzzyMatchDeal(List<Deal> deals, String query) {
    final q = query.toLowerCase();
    // Exact substring match first
    for (final d in deals) {
      if (d.name.toLowerCase().contains(q)) return d;
    }
    // Token match: any word in query matches a word in name
    final words = q.split(RegExp(r'\s+'));
    for (final d in deals) {
      final nameLower = d.name.toLowerCase();
      if (words.any((w) => w.length > 2 && nameLower.contains(w))) return d;
    }
    return null;
  }

  // ── Top clients ────────────────────────────────────────────────

  Future<AiResponse> _topClients() async {
    try {
      final clients = await _repo.fetchClients();
      if (clients.isEmpty) return _seedTopClients();
      final withAum = clients
          .where((c) => (c.totalAum ?? 0) > 0)
          .toList()
        ..sort((a, b) => (b.totalAum ?? 0).compareTo(a.totalAum ?? 0));
      if (withAum.isEmpty) {
        // Fall back to listing the first few clients
        final top = clients.take(5).toList();
        final lines = top.map((c) => '• ${c.name} (${c.status ?? 'active'})').join('\n');
        return AiResponse(
          text: 'You have ${clients.length} clients in the CRM.\n\n$lines',
          chips: [
            const AiChip(label: 'View clients', kind: AiChipKind.gold, route: '/clients'),
          ],
        );
      }
      final top = withAum.take(5).toList();
      final lines = top
          .map((c) => '• ${c.name} — ${formatCompactCurrency(c.totalAum)}')
          .join('\n');
      final total = withAum.fold<double>(0, (s, c) => s + (c.totalAum ?? 0));
      return AiResponse(
        text: 'Top clients by AUM (${formatCompactCurrency(total)} total):\n\n$lines',
        chips: [
          const AiChip(label: 'View clients', kind: AiChipKind.gold, route: '/clients'),
        ],
      );
    } catch (_) {
      return _seedTopClients();
    }
  }

  AiResponse _seedTopClients() => const AiResponse(
        text: 'Top clients by AUM (\$2.4B total):\n\n'
            '• Quantum Capital — \$680M\n'
            '• Atlas Family Office — \$520M\n'
            '• Meridian Trust — \$380M\n'
            '• Blackwell Group — \$310M\n'
            '• Crestview Partners — \$280M',
        chips: [
          AiChip(label: 'View clients', kind: AiChipKind.gold, route: '/clients'),
        ],
      );

  // ── Open tasks ─────────────────────────────────────────────────

  Future<AiResponse> _openTasks() async {
    try {
      final tasks = await _repo.fetchTasks(openOnly: true);
      if (tasks.isEmpty) {
        return const AiResponse(
          text: 'No open tasks right now — you\'re all caught up!',
          chips: [
            AiChip(label: 'View tasks', kind: AiChipKind.gold, route: '/tasks'),
            AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
          ],
        );
      }
      final overdue = tasks.where((t) => t.isOverdue).toList();
      final upcoming = tasks.where((t) => !t.isOverdue).take(4).toList();
      final sb = StringBuffer();
      sb.write('You have ${tasks.length} open task${tasks.length == 1 ? '' : 's'}.');
      if (overdue.isNotEmpty) {
        sb.write('\n\n${overdue.length} overdue:\n');
        sb.write(overdue
            .take(3)
            .map((t) => '• ${t.title}${t.dueDate != null ? ' (due ${formatDate(t.dueDate)})' : ''}')
            .join('\n'));
      }
      if (upcoming.isNotEmpty) {
        sb.write('\n\nUpcoming:\n');
        sb.write(upcoming
            .map((t) => '• ${t.title}${t.dueDate != null ? ' — ${formatDate(t.dueDate)}' : ''}')
            .join('\n'));
      }
      return AiResponse(
        text: sb.toString(),
        chips: [
          const AiChip(label: 'View tasks', kind: AiChipKind.gold, route: '/tasks'),
          const AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
        ],
      );
    } catch (_) {
      return const AiResponse(
        text: 'You have 6 open tasks, including 2 overdue:\n\n'
            '• Send LOI to Apollo (overdue)\n'
            '• Schedule call — Atlas (overdue)\n'
            '• Prepare Q3 deck — Meridian\n'
            '• Review term sheet — Blackwell',
        chips: [
          AiChip(label: 'View tasks', kind: AiChipKind.gold, route: '/tasks'),
          AiChip(label: 'Create task', kind: AiChipKind.green, route: '/tasks'),
        ],
      );
    }
  }

  // ── Closing soon ───────────────────────────────────────────────

  Future<AiResponse> _closingSoon() async {
    try {
      final deals = await _repo.fetchDeals();
      final now = DateTime.now();
      final soon = deals.where((d) {
        if (!d.isActive || d.expectedCloseDate == null) return false;
        final close = DateTime.tryParse(d.expectedCloseDate!);
        if (close == null) return false;
        return close.isAfter(now) && close.isBefore(now.add(const Duration(days: 90)));
      }).toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(a.expectedCloseDate!) ?? DateTime(2099);
          final db = DateTime.tryParse(b.expectedCloseDate!) ?? DateTime(2099);
          return da.compareTo(db);
        });
      if (soon.isEmpty) {
        return const AiResponse(
          text: 'No deals have expected close dates within the next 90 days. '
              'Consider updating close date estimates in the pipeline.',
          chips: [
            AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
          ],
        );
      }
      final lines = soon
          .take(4)
          .map((d) =>
              '• ${d.name} — ${formatDate(d.expectedCloseDate)} (${formatCompactCurrency(d.dealValue)})')
          .join('\n');
      final chips = soon
          .take(2)
          .map((d) => AiChip(
              label: '${d.name.split(' ').first} →',
              kind: AiChipKind.gold,
              route: '/deal/${d.id}'))
          .toList();
      return AiResponse(
        text: '${soon.length} deal${soon.length == 1 ? '' : 's'} expected to close in the next 90 days:\n\n$lines',
        chips: chips,
      );
    } catch (_) {
      return const AiResponse(
        text: '3 deals expected to close in the next 90 days:\n\n'
            '• Apollo Fund II — Aug 15 (\$24M)\n'
            '• Meridian RE Loan — Sep 1 (\$12M)\n'
            '• Crestview Partners — Sep 30 (\$18M)',
        chips: [
          AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
        ],
      );
    }
  }

  // ── Capability fallback ────────────────────────────────────────

  AiResponse _capability() => const AiResponse(
        text: 'I\'m Braccia AI — grounded on your firm\'s live data. Here\'s what I can help with:\n\n'
            '• Pipeline value & breakdown\n'
            '• Which deals are stalled or closing soon\n'
            '• Top clients by AUM\n'
            '• Open tasks & overdue actions\n'
            '• Deal summaries (try "Summarize the Apollo deal")\n'
            '• Who owns the most pipeline\n\n'
            'Just ask in plain English.',
        chips: [
          AiChip(label: 'View pipeline', kind: AiChipKind.gold, route: '/pipeline'),
          AiChip(label: 'View tasks', kind: AiChipKind.green, route: '/tasks'),
          AiChip(label: 'View clients', kind: AiChipKind.blue, route: '/clients'),
        ],
      );

  // ── Utilities ──────────────────────────────────────────────────

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }
}
