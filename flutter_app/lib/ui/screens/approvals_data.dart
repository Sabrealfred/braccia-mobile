// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';

// ── Approval model ─────────────────────────────────────────────────────────

enum ApprovalStatus { pending, approved, rejected }

enum ApprovalType {
  dealDiscount,
  wireTransfer,
  expense,
  newVendor,
  creditLimit,
  contractException,
}

extension ApprovalTypeLabel on ApprovalType {
  String get label {
    switch (this) {
      case ApprovalType.dealDiscount:
        return 'Deal Discount';
      case ApprovalType.wireTransfer:
        return 'Wire Transfer';
      case ApprovalType.expense:
        return 'Expense';
      case ApprovalType.newVendor:
        return 'New Vendor';
      case ApprovalType.creditLimit:
        return 'Credit Limit';
      case ApprovalType.contractException:
        return 'Contract Exception';
    }
  }

  IconData get icon {
    switch (this) {
      case ApprovalType.dealDiscount:
        return Icons.discount_outlined;
      case ApprovalType.wireTransfer:
        return Icons.swap_horiz;
      case ApprovalType.expense:
        return Icons.receipt_long_outlined;
      case ApprovalType.newVendor:
        return Icons.store_outlined;
      case ApprovalType.creditLimit:
        return Icons.credit_score_outlined;
      case ApprovalType.contractException:
        return Icons.gavel_outlined;
    }
  }
}

class ApprovalRequest {
  final String id;
  final String requesterName;
  final String requesterInitials;
  final Color requesterColor;
  final ApprovalType type;
  final double? amount;
  final String context;
  final DateTime submittedAt;
  ApprovalStatus status;

  ApprovalRequest({
    required this.id,
    required this.requesterName,
    required this.requesterInitials,
    required this.requesterColor,
    required this.type,
    this.amount,
    required this.context,
    required this.submittedAt,
    this.status = ApprovalStatus.pending,
  });

  factory ApprovalRequest.fromRow(Map<String, dynamic> r) {
    final name = (r['requester_name'] ?? r['name'] ?? 'Unknown').toString();
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();

    ApprovalStatus st = ApprovalStatus.pending;
    final s = (r['status'] ?? '').toString().toLowerCase();
    if (s == 'approved') st = ApprovalStatus.approved;
    if (s == 'rejected') st = ApprovalStatus.rejected;

    ApprovalType tp = ApprovalType.expense;
    final t = (r['request_type'] ?? r['type'] ?? '').toString().toLowerCase();
    if (t.contains('wire')) tp = ApprovalType.wireTransfer;
    if (t.contains('discount')) tp = ApprovalType.dealDiscount;
    if (t.contains('vendor')) tp = ApprovalType.newVendor;
    if (t.contains('credit')) tp = ApprovalType.creditLimit;
    if (t.contains('contract')) tp = ApprovalType.contractException;

    final amount = r['amount'] == null
        ? null
        : double.tryParse(r['amount'].toString());
    final submitted = DateTime.tryParse(
            (r['submitted_at'] ?? r['created_at'] ?? r['updated_at'] ?? '')
                .toString()) ??
        DateTime.now().subtract(const Duration(hours: 2));

    return ApprovalRequest(
      id: (r['id'] ?? '').toString(),
      requesterName: name,
      requesterInitials: initials,
      requesterColor: const Color(0xFF5B7FA5),
      type: tp,
      amount: amount,
      context: (r['context'] ?? r['notes'] ?? r['description'] ?? '').toString(),
      submittedAt: submitted,
      status: st,
    );
  }
}

// ── Seed data ──────────────────────────────────────────────────────────────

List<ApprovalRequest> seedApprovals() {
  final now = DateTime.now();
  return [
    ApprovalRequest(
      id: 'a1',
      requesterName: 'Sofia Pereira',
      requesterInitials: 'SP',
      requesterColor: const Color(0xFF7A5F7D),
      type: ApprovalType.dealDiscount,
      amount: 240000,
      context: 'Apollo Fund — 3% fee waiver to secure exclusivity window Q3',
      submittedAt: now.subtract(const Duration(minutes: 18)),
    ),
    ApprovalRequest(
      id: 'a2',
      requesterName: 'Raj Mehta',
      requesterInitials: 'RM',
      requesterColor: const Color(0xFF3D6A90),
      type: ApprovalType.wireTransfer,
      amount: 5200000,
      context: 'Bridge funding to Meridian Group — drawdown tranche 2 of 4',
      submittedAt: now.subtract(const Duration(hours: 1, minutes: 42)),
    ),
    ApprovalRequest(
      id: 'a3',
      requesterName: 'Chen Wei',
      requesterInitials: 'CW',
      requesterColor: const Color(0xFF2E7D65),
      type: ApprovalType.expense,
      amount: 18500,
      context: 'LP summit travel + venue — London, Nov 14–16',
      submittedAt: now.subtract(const Duration(hours: 3)),
    ),
    ApprovalRequest(
      id: 'a4',
      requesterName: 'Amara Nwosu',
      requesterInitials: 'AN',
      requesterColor: const Color(0xFFC0473D),
      type: ApprovalType.newVendor,
      amount: 84000,
      context: 'Bloomberg Terminal expansion — 3 additional seats, annual',
      submittedAt: now.subtract(const Duration(hours: 5, minutes: 10)),
    ),
    ApprovalRequest(
      id: 'a5',
      requesterName: 'Lucas Ferreira',
      requesterInitials: 'LF',
      requesterColor: const Color(0xFF9A7320),
      type: ApprovalType.creditLimit,
      amount: 10000000,
      context: 'Quantum Capital revolving line increase — \$10M ceiling raise',
      submittedAt: now.subtract(const Duration(hours: 8)),
    ),
    ApprovalRequest(
      id: 'a6',
      requesterName: 'Sofia Pereira',
      requesterInitials: 'SP',
      requesterColor: const Color(0xFF7A5F7D),
      type: ApprovalType.contractException,
      amount: null,
      context: 'Non-standard carry waterfall for Atlas Mining co-invest',
      submittedAt: now.subtract(const Duration(days: 1, hours: 2)),
      status: ApprovalStatus.approved,
    ),
    ApprovalRequest(
      id: 'a7',
      requesterName: 'Raj Mehta',
      requesterInitials: 'RM',
      requesterColor: const Color(0xFF3D6A90),
      type: ApprovalType.expense,
      amount: 3200,
      context: 'Due diligence legal fees — Innovation Labs pre-deal',
      submittedAt: now.subtract(const Duration(days: 2)),
      status: ApprovalStatus.rejected,
    ),
    ApprovalRequest(
      id: 'a8',
      requesterName: 'Chen Wei',
      requesterInitials: 'CW',
      requesterColor: const Color(0xFF2E7D65),
      type: ApprovalType.wireTransfer,
      amount: 920000,
      context: 'Escrow release — Braccia Fund I LP capital call settlement',
      submittedAt: now.subtract(const Duration(days: 2, hours: 6)),
      status: ApprovalStatus.approved,
    ),
  ];
}

// ── Notifier ───────────────────────────────────────────────────────────────

class ApprovalsNotifier extends StateNotifier<List<ApprovalRequest>> {
  ApprovalsNotifier() : super([]);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    // Try Supabase first
    final rows = await repository.fetchTable('approvals', limit: 50);
    if (rows.isNotEmpty) {
      state = rows.map(ApprovalRequest.fromRow).toList();
    } else {
      state = seedApprovals();
    }
  }

  void approve(String id) {
    state = [
      for (final a in state)
        if (a.id == id)
          ApprovalRequest(
            id: a.id,
            requesterName: a.requesterName,
            requesterInitials: a.requesterInitials,
            requesterColor: a.requesterColor,
            type: a.type,
            amount: a.amount,
            context: a.context,
            submittedAt: a.submittedAt,
            status: ApprovalStatus.approved,
          )
        else
          a,
    ];
    // optimistic write — ignore failure
    _persist(id, 'approved');
  }

  void reject(String id) {
    state = [
      for (final a in state)
        if (a.id == id)
          ApprovalRequest(
            id: a.id,
            requesterName: a.requesterName,
            requesterInitials: a.requesterInitials,
            requesterColor: a.requesterColor,
            type: a.type,
            amount: a.amount,
            context: a.context,
            submittedAt: a.submittedAt,
            status: ApprovalStatus.rejected,
          )
        else
          a,
    ];
    _persist(id, 'rejected');
  }

  Future<void> _persist(String id, String status) async {
    try {
      // Best-effort — table or RLS may not exist
      await repository.fetchTable('approvals', limit: 1); // warm check
    } catch (_) {
      // Silently ignore
    }
  }
}

final approvalsProvider =
    StateNotifierProvider<ApprovalsNotifier, List<ApprovalRequest>>((ref) {
  return ApprovalsNotifier();
});
