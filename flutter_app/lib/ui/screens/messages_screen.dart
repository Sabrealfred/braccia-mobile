import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'chat_data.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Attempt to hydrate from Supabase in background.
    Future.microtask(
      () => ref.read(channelListProvider.notifier).loadFromSupabase(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelListProvider);

    final filteredChannels = _query.isEmpty
        ? channels
        : channels
            .where((c) =>
                c.displayName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final filteredDMs = _query.isEmpty
        ? seedDMs
        : seedDMs
            .where((c) =>
                c.displayName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          Column(
            children: [
              DarkHeader(
                title: 'Messages',
                actions: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.edit_square,
                      color: AppColors.goldOnDark,
                      size: 20,
                    ),
                  ),
                ],
                bottom: DarkSearchField(
                  hint: 'Search messages…',
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                  children: [
                    // ── CHANNELS section ──────────────────────────────────
                    _SectionHeader(label: 'CHANNELS'),
                    if (filteredChannels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: EmptyStateView(
                          message: 'No channels found',
                          icon: Icons.tag,
                        ),
                      )
                    else
                      for (final ch in filteredChannels)
                        _ChannelRow(channel: ch),

                    const SizedBox(height: 8),

                    // ── DIRECT MESSAGES section ────────────────────────
                    _SectionHeader(label: 'DIRECT MESSAGES'),
                    if (filteredDMs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: EmptyStateView(
                          message: 'No direct messages',
                          icon: Icons.person,
                        ),
                      )
                    else
                      for (final dm in filteredDMs) _DmRow(channel: dm),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),

          // Gold FAB
          Positioned(
            right: 20,
            bottom: 100,
            child: GoldFab(
              icon: Icons.edit_outlined,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(label, style: AppText.eyebrow(AppColors.mutedLight)),
    );
  }
}

// ── Channel row ───────────────────────────────────────────────────────────────

class _ChannelRow extends StatelessWidget {
  final ChatChannel channel;
  const _ChannelRow({required this.channel});

  @override
  Widget build(BuildContext context) {
    final hasUnread = channel.unreadCount > 0;

    return Pressable(
      onTap: () => context.push('/messages/${channel.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.gold500.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.inner),
        ),
        child: Row(
          children: [
            // # icon tile
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasUnread
                    ? AppColors.onyx700
                    : AppColors.hairline,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '#',
                style: AppText.serif(
                  size: 18,
                  color: hasUnread
                      ? AppColors.gold300
                      : AppColors.muted,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 14,
                            weight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (channel.lastMessageAt != null)
                        Text(
                          _formatTime(channel.lastMessageAt!),
                          style: AppText.sans(
                            size: 11,
                            color: hasUnread
                                ? AppColors.goldTextSoft
                                : AppColors.muted,
                            weight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 12.5,
                            color: hasUnread
                                ? AppColors.ink
                                : AppColors.muted,
                            weight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        StatusPill(
                          label: channel.unreadCount > 9
                              ? '9+'
                              : '${channel.unreadCount}',
                          color: Colors.white,
                          bg: AppColors.redOnDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── DM row ────────────────────────────────────────────────────────────────────

class _DmRow extends StatelessWidget {
  final ChatChannel channel;
  const _DmRow({required this.channel});

  @override
  Widget build(BuildContext context) {
    final hasUnread = channel.unreadCount > 0;
    final initials = _initialsOf(channel.displayName);
    final color = avatarColorFor(channel.displayName);

    return Pressable(
      onTap: () => context.push('/messages/${channel.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppColors.gold500.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.inner),
        ),
        child: Row(
          children: [
            // Round avatar with presence dot
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initials,
                      style: AppText.sans(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: channel.isOnline
                            ? AppColors.green
                            : AppColors.muted.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.ivory, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 14,
                            weight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (channel.lastMessageAt != null)
                        Text(
                          _formatTime(channel.lastMessageAt!),
                          style: AppText.sans(
                            size: 11,
                            color: hasUnread
                                ? AppColors.goldTextSoft
                                : AppColors.muted,
                            weight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          channel.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 12.5,
                            color: hasUnread
                                ? AppColors.ink
                                : AppColors.muted,
                            weight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        StatusPill(
                          label: channel.unreadCount > 9
                              ? '9+'
                              : '${channel.unreadCount}',
                          color: Colors.white,
                          bg: AppColors.redOnDark,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return DateFormat('EEE').format(dt);
  return DateFormat('MMM d').format(dt);
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  final s = name.trim();
  return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
}
