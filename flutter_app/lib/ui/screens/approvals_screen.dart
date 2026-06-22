import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'approvals_data.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  // 0 = Pending, 1 = Approved, 2 = Rejected
  static const _filters = ['Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(approvalsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(approvalsProvider);
    final pendingCount = all.where((a) => a.status == ApprovalStatus.pending).length;

    ApprovalStatus filterStatus;
    switch (_tab.index) {
      case 1:
        filterStatus = ApprovalStatus.approved;
      case 2:
        filterStatus = ApprovalStatus.rejected;
      default:
        filterStatus = ApprovalStatus.pending;
    }
    final visible = all.where((a) => a.status == filterStatus).toList();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          _ApprovalsHeader(
            pendingCount: pendingCount,
            filterIndex: _tab.index,
            onFilterChanged: (i) => _tab.animateTo(i),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyStateView(
                    message: 'No ${_filters[_tab.index].toLowerCase()} requests',
                    icon: _tab.index == 0
                        ? Icons.check_circle_outline
                        : Icons.inbox_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemCount: visible.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ApprovalCard(
                      item: visible[i],
                      onApprove: () => _handleApprove(visible[i]),
                      onReject: () => _handleReject(visible[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleApprove(ApprovalRequest item) {
    ref.read(approvalsProvider.notifier).approve(item.id);
    _showSnackbar('Approved: ${item.requesterName}', AppColors.greenOnDark,
        AppColors.green);
  }

  void _handleReject(ApprovalRequest item) {
    ref.read(approvalsProvider.notifier).reject(item.id);
    _showSnackbar('Rejected: ${item.requesterName}', AppColors.redOnDark,
        AppColors.red);
  }

  void _showSnackbar(String message, Color textColor, Color barColor) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppText.sans(size: 13.5, color: textColor, weight: FontWeight.w600),
        ),
        backgroundColor: AppColors.onyx700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: barColor.withValues(alpha: 0.4)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Header with filter chips ───────────────────────────────────────────────

class _ApprovalsHeader extends StatelessWidget {
  final int pendingCount;
  final int filterIndex;
  final ValueChanged<int> onFilterChanged;

  const _ApprovalsHeader({
    required this.pendingCount,
    required this.filterIndex,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 14;
    return Container(
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back chevron row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left,
                        color: AppColors.goldOnDark, size: 20),
                    Text('Back',
                        style: AppText.sans(
                            size: 14, color: AppColors.goldOnDark)),
                  ],
                ),
              ),
              // notification dot placeholder
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.goldOnDark,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Title + badge
          Row(
            children: [
              Text('Approvals',
                  style: AppText.serif(size: 24, color: AppColors.ivory)),
              if (pendingCount > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: AppText.sans(
                        size: 11,
                        color: AppColors.goldInk,
                        weight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Pending',
                  active: filterIndex == 0,
                  count: pendingCount,
                  onTap: () => onFilterChanged(0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Approved',
                  active: filterIndex == 1,
                  onTap: () => onFilterChanged(1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Rejected',
                  active: filterIndex == 2,
                  onTap: () => onFilterChanged(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final int? count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.sans(
                size: 13,
                color: active ? AppColors.goldInk : AppColors.mutedOnDark,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.goldInk.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: AppText.sans(
                    size: 10,
                    color: active ? AppColors.goldInk : AppColors.ivory,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Approval card ──────────────────────────────────────────────────────────

class _ApprovalCard extends StatelessWidget {
  final ApprovalRequest item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == ApprovalStatus.pending;

    return AppCard(
      noPadding: true,
      radius: AppRadii.cardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: avatar + name + type + time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AvatarDot(
                      initials: item.requesterInitials,
                      color: item.requesterColor,
                      size: 38,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.requesterName,
                                  style: AppText.sans(
                                      size: 14, weight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeAgo(item.submittedAt.toIso8601String()),
                                style: AppText.sans(
                                    size: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(item.type.icon,
                                  size: 13,
                                  color: AppColors.goldTextSoft),
                              const SizedBox(width: 4),
                              Text(
                                item.type.label,
                                style: AppText.sans(
                                    size: 12,
                                    color: AppColors.goldTextSoft,
                                    weight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                // Amount in gold serif
                if (item.amount != null) ...[
                  Text(
                    formatCompactCurrency(item.amount),
                    style: AppText.serif(
                        size: 28, color: AppColors.goldText),
                  ),
                  const SizedBox(height: 6),
                ],
                // Context line
                Text(
                  item.context,
                  style: AppText.sans(
                      size: 13,
                      color: AppColors.muted,
                      height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Status indicator (non-pending)
                if (!isPending)
                  _StatusBadge(status: item.status),
              ],
            ),
          ),
          // Action buttons — only for pending
          if (isPending) ...[
            Container(
              height: 1,
              color: AppColors.hairlineSoft,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Reject',
                      color: AppColors.red,
                      bg: AppColors.red.withValues(alpha: 0.08),
                      icon: Icons.close,
                      onTap: onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Approve',
                      color: AppColors.green,
                      bg: AppColors.green.withValues(alpha: 0.1),
                      icon: Icons.check,
                      onTap: onApprove,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApprovalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == ApprovalStatus.approved;
    final color = isApproved ? AppColors.green : AppColors.red;
    final bg = color.withValues(alpha: 0.1);
    final label = isApproved ? 'Approved' : 'Rejected';
    final icon = isApproved ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: AppText.sans(
                  size: 11.5, color: color, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppText.sans(
                    size: 13.5, color: color, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
