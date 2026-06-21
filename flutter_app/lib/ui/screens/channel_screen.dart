import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'chat_data.dart';

class ChannelScreen extends ConsumerStatefulWidget {
  final String channelId;
  const ChannelScreen({super.key, required this.channelId});

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    _textController.clear();

    ref.read(channelMessagesProvider(widget.channelId).notifier).sendMessage(
          body: body,
          authorId: 'me',
          authorName: 'You',
          authorInitials: 'YO',
          authorColor: AppColors.gold500,
        );

    setState(() => _sending = false);
    // Scroll after state update.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(channelMessagesProvider(widget.channelId));
    final channel = channelById(widget.channelId);
    final isChannel = channel?.type == ConversationType.channel;
    final title = isChannel
        ? '#${channel?.displayName ?? widget.channelId}'
        : (channel?.displayName ?? widget.channelId);
    final memberLabel = channel?.memberCount != null
        ? '${channel!.memberCount} members'
        : null;

    // Group messages by day and sender.
    final grouped = _groupMessages(messages);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ChannelHeader(
            title: title,
            subtitle: memberLabel,
            isChannel: isChannel,
            onBack: () => context.pop(),
          ),

          // ── Message thread ───────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? const EmptyStateView(
                    message: 'No messages yet.\nSend one below!',
                    icon: Icons.chat_bubble_outline,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    itemCount: grouped.length,
                    itemBuilder: (ctx, i) {
                      final item = grouped[i];
                      if (item is _DaySeparator) {
                        return _DaySeparatorWidget(label: item.label);
                      } else if (item is _MessageGroup) {
                        return _MessageGroupWidget(group: item);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),

          // ── Composer ─────────────────────────────────────────────────────
          _Composer(
            controller: _textController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  // Group consecutive messages by day + consecutive sender.
  List<Object> _groupMessages(List<ChatMessage> messages) {
    final result = <Object>[];
    DateTime? lastDay;
    String? lastAuthor;
    _MessageGroup? currentGroup;

    void flushGroup() {
      if (currentGroup != null) {
        result.add(currentGroup!);
        currentGroup = null;
      }
    }

    for (final msg in messages) {
      final day = DateTime(msg.sentAt.year, msg.sentAt.month, msg.sentAt.day);
      if (lastDay == null || day != lastDay) {
        flushGroup();
        lastDay = day;
        lastAuthor = null;
        result.add(_DaySeparator(label: _dayLabel(day)));
      }
      if (msg.authorId != lastAuthor) {
        flushGroup();
        lastAuthor = msg.authorId;
        currentGroup = _MessageGroup(
          authorId: msg.authorId,
          authorName: msg.authorName,
          authorInitials: msg.authorInitials ?? _initialsOf(msg.authorName),
          authorColor: msg.authorColor,
          messages: [],
        );
      }
      currentGroup!.messages.add(msg);
    }
    flushGroup();
    return result;
  }
}

// ── Data structures for grouped display ──────────────────────────────────────

class _DaySeparator {
  final String label;
  const _DaySeparator({required this.label});
}

class _MessageGroup {
  final String authorId;
  final String authorName;
  final String authorInitials;
  final Color authorColor;
  final List<ChatMessage> messages;

  _MessageGroup({
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.messages,
  });
}

// ── Channel header ────────────────────────────────────────────────────────────

class _ChannelHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isChannel;
  final VoidCallback onBack;

  const _ChannelHeader({
    required this.title,
    this.subtitle,
    required this.isChannel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 12;
    return Container(
      width: double.infinity,
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 14),
      child: Row(
        children: [
          // Back chevron
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chevron_left,
                    color: AppColors.goldOnDark,
                    size: 22,
                  ),
                  Text(
                    'Back',
                    style: AppText.sans(
                        size: 14, color: AppColors.goldOnDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.serif(size: 19, color: AppColors.ivory),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: AppText.sans(
                        size: 12, color: AppColors.mutedOnDark),
                  ),
                ],
              ],
            ),
          ),
          // Search icon
          const Icon(Icons.search, color: AppColors.mutedOnDark, size: 20),
        ],
      ),
    );
  }
}

// ── Day separator ─────────────────────────────────────────────────────────────

class _DaySeparatorWidget extends StatelessWidget {
  final String label;
  const _DaySeparatorWidget({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Divider(
              color: AppColors.hairline,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: AppText.sans(
                size: 11,
                color: AppColors.muted,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.hairline,
              thickness: 1,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

// ── Message group ─────────────────────────────────────────────────────────────

class _MessageGroupWidget extends StatelessWidget {
  final _MessageGroup group;
  const _MessageGroupWidget({required this.group});

  bool get _isMe => group.authorId == 'me';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar (left-aligned, hidden for "me")
          if (!_isMe) ...[
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: group.authorColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                group.authorInitials,
                style: AppText.sans(
                  size: 11,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 44),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + time header
                if (!_isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Text(
                          group.authorName,
                          style: AppText.sans(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _formatMsgTime(group.messages.first.sentAt),
                          style: AppText.sans(
                            size: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Messages in this group
                for (int i = 0; i < group.messages.length; i++)
                  _BubbleTile(
                    message: group.messages[i],
                    isMe: _isMe,
                    showTime: _isMe && i == 0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bubble tile ───────────────────────────────────────────────────────────────

class _BubbleTile extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showTime;
  const _BubbleTile({
    required this.message,
    required this.isMe,
    this.showTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isMe && showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, right: 2),
              child: Text(
                'You · ${_formatMsgTime(message.sentAt)}',
                style: AppText.sans(
                    size: 10.5, color: AppColors.muted),
              ),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.onyx700
                  : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMe ? 16 : 4),
                topRight: Radius.circular(isMe ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              border: isMe
                  ? null
                  : Border.all(color: AppColors.hairline),
              boxShadow: isMe
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              message.body,
              style: AppText.sans(
                size: 14,
                color: isMe ? AppColors.ivory : AppColors.ink,
                height: 1.45,
              ),
            ),
          ),
          // Reactions
          if (message.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: message.reactions
                    .map((r) => _ReactionChip(reaction: r))
                    .toList(),
              ),
            ),
          // Optimistic indicator
          if (message.isOptimistic)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Sending…',
                style: AppText.sans(
                    size: 10, color: AppColors.muted.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reaction chip ─────────────────────────────────────────────────────────────

class _ReactionChip extends StatelessWidget {
  final MessageReaction reaction;
  const _ReactionChip({required this.reaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reaction.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '${reaction.count}',
            style: AppText.sans(
              size: 11.5,
              color: AppColors.mutedLight,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.hairline),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        bottomInset > 0 ? 12 : (bottomPadding + 12).clamp(12, 48),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach icon
          Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 8),
            child: GestureDetector(
              onTap: () {},
              child: Icon(
                Icons.attach_file,
                size: 22,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
            ),
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 42, maxHeight: 130),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.hairline),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppText.sans(size: 14.5, color: AppColors.ink),
                cursorColor: AppColors.gold500,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Message…',
                  hintStyle:
                      AppText.sans(size: 14.5, color: AppColors.mutedLight),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 160),
            child: GestureDetector(
              onTap: _hasText && !widget.sending ? widget.onSend : null,
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _hasText
                      ? AppColors.goldGradient
                      : null,
                  color: _hasText
                      ? null
                      : AppColors.hairline,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color:
                                AppColors.gold500.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: widget.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: _hasText ? AppColors.goldInk : AppColors.muted,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dayLabel(DateTime day) {
  final today = DateTime.now();
  final todayDay =
      DateTime(today.year, today.month, today.day);
  final yesterday = todayDay.subtract(const Duration(days: 1));
  if (day == todayDay) return 'Today';
  if (day == yesterday) return 'Yesterday';
  return DateFormat('MMMM d, yyyy').format(day);
}

String _formatMsgTime(DateTime dt) {
  return DateFormat('h:mm a').format(dt);
}

String _initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  final s = name.trim();
  return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
}
