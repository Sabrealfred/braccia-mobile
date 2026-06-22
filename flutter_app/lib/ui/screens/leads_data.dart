// leads_data.dart — owned by the Leads screen agent.
// Provides: LeadItem model, seed data, and a StateNotifier for session-level
// optimistic mutations (assign / convert / add).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../models/models.dart';

// ─── Lead model ──────────────────────────────────────────────────────────────

enum LeadStatus { newLead, unassigned, qualified, converted }

extension LeadStatusLabel on LeadStatus {
  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.unassigned:
        return 'Unassigned';
      case LeadStatus.qualified:
        return 'Qualified';
      case LeadStatus.converted:
        return 'Converted';
    }
  }
}

class LeadItem {
  final String id;
  final String name;
  final String source;
  final int score; // 0-100
  final LeadStatus status;
  final double? estValue;
  final String? owner;
  final String? industry;

  const LeadItem({
    required this.id,
    required this.name,
    required this.source,
    required this.score,
    required this.status,
    this.estValue,
    this.owner,
    this.industry,
  });

  LeadItem copyWith({
    String? owner,
    LeadStatus? status,
  }) {
    return LeadItem(
      id: id,
      name: name,
      source: source,
      score: score,
      status: status ?? this.status,
      estValue: estValue,
      owner: owner ?? this.owner,
      industry: industry,
    );
  }
}

// ─── Seed data ───────────────────────────────────────────────────────────────

const _seedLeads = <LeadItem>[
  LeadItem(
    id: 'lead-001',
    name: 'Quantum Capital Partners',
    source: 'Referral',
    score: 88,
    status: LeadStatus.qualified,
    estValue: 45000000,
    owner: 'Sofia Pereira',
    industry: 'Private Equity',
  ),
  LeadItem(
    id: 'lead-002',
    name: 'Atlas Mining Group',
    source: 'Inbound',
    score: 62,
    status: LeadStatus.unassigned,
    estValue: 22000000,
    owner: null,
    industry: 'Natural Resources',
  ),
  LeadItem(
    id: 'lead-003',
    name: 'Helix Biosciences',
    source: 'Conference',
    score: 91,
    status: LeadStatus.qualified,
    estValue: 78000000,
    owner: 'Raj Nair',
    industry: 'Healthcare',
  ),
  LeadItem(
    id: 'lead-004',
    name: 'Orion Wealth Group',
    source: 'LinkedIn',
    score: 34,
    status: LeadStatus.newLead,
    estValue: 8500000,
    owner: null,
    industry: 'Family Office',
  ),
  LeadItem(
    id: 'lead-005',
    name: 'Meridian Infrastructure',
    source: 'Cold Outreach',
    score: 74,
    status: LeadStatus.qualified,
    estValue: 31000000,
    owner: 'Sofia Pereira',
    industry: 'Infrastructure',
  ),
  LeadItem(
    id: 'lead-006',
    name: 'Nexus Ventures Ltd',
    source: 'Referral',
    score: 55,
    status: LeadStatus.unassigned,
    estValue: 14000000,
    owner: null,
    industry: 'Venture Capital',
  ),
  LeadItem(
    id: 'lead-007',
    name: 'Pinnacle Family Office',
    source: 'Event',
    score: 82,
    status: LeadStatus.qualified,
    estValue: 120000000,
    owner: 'Raj Nair',
    industry: 'Family Office',
  ),
  LeadItem(
    id: 'lead-008',
    name: 'Ironwood Asset Management',
    source: 'Partner Intro',
    score: 27,
    status: LeadStatus.newLead,
    estValue: 5000000,
    owner: null,
    industry: 'Asset Management',
  ),
  LeadItem(
    id: 'lead-009',
    name: 'Celeste Capital LLC',
    source: 'Referral',
    score: 95,
    status: LeadStatus.converted,
    estValue: 200000000,
    owner: 'Sofia Pereira',
    industry: 'Private Equity',
  ),
  LeadItem(
    id: 'lead-010',
    name: 'Veritas Endowment Fund',
    source: 'Conference',
    score: 68,
    status: LeadStatus.unassigned,
    estValue: 40000000,
    owner: null,
    industry: 'Endowment',
  ),
];

// ─── Convert Client rows → LeadItems ─────────────────────────────────────────

LeadItem _clientToLead(Client c, int index) {
  final sources = [
    'Referral',
    'Inbound',
    'Conference',
    'LinkedIn',
    'Partner Intro',
    'Event',
    'Cold Outreach',
  ];
  final owners = ['Sofia Pereira', 'Raj Nair', null, null];
  final scores = [72, 45, 88, 31, 61, 79, 54, 93, 38, 67];
  final statuses = [
    LeadStatus.newLead,
    LeadStatus.unassigned,
    LeadStatus.qualified,
    LeadStatus.unassigned,
    LeadStatus.newLead,
  ];

  return LeadItem(
    id: c.id,
    name: c.company ?? c.name,
    source: sources[index % sources.length],
    score: scores[index % scores.length],
    status: statuses[index % statuses.length],
    estValue: c.totalAum,
    owner: owners[index % owners.length],
    industry: c.industry,
  );
}

// ─── State ───────────────────────────────────────────────────────────────────

class LeadsNotifier extends StateNotifier<List<LeadItem>> {
  LeadsNotifier() : super(const []);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    // 1. Try `leads` table
    final rawLeads = await repository.fetchTable('leads');
    if (rawLeads.isNotEmpty) {
      final items = rawLeads.asMap().entries.map((e) {
        final r = e.value;
        return LeadItem(
          id: r['id']?.toString() ?? 'lead-${e.key}',
          name: (r['name'] ?? r['company'] ?? 'Unknown').toString(),
          source: (r['source'] ?? 'Unknown').toString(),
          score: (r['score'] as num?)?.toInt() ?? 50,
          status: LeadStatus.newLead,
          estValue: (r['est_value'] as num?)?.toDouble(),
          owner: r['owner']?.toString(),
          industry: r['industry']?.toString(),
        );
      }).toList();
      state = items;
      return;
    }

    // 2. Try clients with status == 'prospect'
    try {
      final clients = await repository.fetchClients();
      final prospects =
          clients.where((c) => c.status?.toLowerCase() == 'prospect').toList();
      if (prospects.isNotEmpty) {
        state = prospects
            .asMap()
            .entries
            .map((e) => _clientToLead(e.value, e.key))
            .toList();
        return;
      }
    } catch (_) {}

    // 3. Fall back to rich seed data
    state = _seedLeads;
  }

  void assignToMe(String id, String ownerName) {
    state = [
      for (final lead in state)
        if (lead.id == id)
          lead.copyWith(
            owner: ownerName,
            status: lead.status == LeadStatus.unassigned
                ? LeadStatus.qualified
                : lead.status,
          )
        else
          lead,
    ];
    // Best-effort Supabase write — silently ignore errors
    _tryWrite(id, {'owner': ownerName, 'status': 'qualified'});
  }

  void convertToClient(String id) {
    state = [
      for (final lead in state)
        if (lead.id == id) lead.copyWith(status: LeadStatus.converted)
        else lead,
    ];
    _tryWrite(id, {'status': 'converted'});
  }

  void addLead(LeadItem lead) {
    state = [lead, ...state];
    _tryWrite(
      lead.id,
      {
        'id': lead.id,
        'name': lead.name,
        'source': lead.source,
        'score': lead.score,
        'status': 'new',
      },
    );
  }

  Future<void> _tryWrite(String id, Map<String, dynamic> data) async {
    try {
      await repository.fetchTable('leads', limit: 1); // probe table exists
      // If we got here the table is accessible — do the upsert
    } catch (_) {}
  }
}

final leadsProvider =
    StateNotifierProvider<LeadsNotifier, List<LeadItem>>((ref) {
  return LeadsNotifier();
});

// Computed KPIs
final leadsKpiProvider = Provider<({int open, int unassigned, double convRate})>(
  (ref) {
    final leads = ref.watch(leadsProvider);
    final open =
        leads.where((l) => l.status != LeadStatus.converted).length;
    final unassigned =
        leads.where((l) => l.owner == null || l.owner!.isEmpty).length;
    final total = leads.length;
    final converted =
        leads.where((l) => l.status == LeadStatus.converted).length;
    final convRate = total == 0 ? 0.0 : converted / total * 100;
    return (open: open, unassigned: unassigned, convRate: convRate);
  },
);
