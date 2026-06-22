// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';

// ── Data models ──────────────────────────────────────────────────────────────

enum ConversationType { channel, dm }

class ChatMessage {
  final String id;
  final String channelId;
  final String authorId;
  final String authorName;
  final String? authorInitials;
  final Color authorColor;
  final String body;
  final DateTime sentAt;
  final List<MessageReaction> reactions;
  final bool isOptimistic;

  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.authorId,
    required this.authorName,
    this.authorInitials,
    this.authorColor = const Color(0xFF5B7FA5),
    required this.body,
    required this.sentAt,
    this.reactions = const [],
    this.isOptimistic = false,
  });

  ChatMessage copyWith({
    String? id,
    bool? isOptimistic,
    List<MessageReaction>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      channelId: channelId,
      authorId: authorId,
      authorName: authorName,
      authorInitials: authorInitials,
      authorColor: authorColor,
      body: body,
      sentAt: sentAt,
      reactions: reactions ?? this.reactions,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}

class MessageReaction {
  final String emoji;
  final int count;
  const MessageReaction({required this.emoji, required this.count});
}

class ChatChannel {
  final String id;
  final ConversationType type;
  final String displayName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline; // DMs only
  final String? memberCount;

  const ChatChannel({
    required this.id,
    required this.type,
    required this.displayName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.memberCount,
  });
}

// ── Avatar color palette ──────────────────────────────────────────────────────

const _avatarColors = [
  Color(0xFF3D6A90),
  Color(0xFF7A5F7D),
  Color(0xFF2E7D65),
  Color(0xFFC0473D),
  Color(0xFF5B7FA5),
  Color(0xFF9A7320),
  Color(0xFF4A6741),
  Color(0xFF7A4F3E),
];

Color avatarColorFor(String name) {
  final idx = name.codeUnits.fold(0, (a, b) => a + b) % _avatarColors.length;
  return _avatarColors[idx];
}

// ── Seeded data ───────────────────────────────────────────────────────────────

final _now = DateTime.now();
DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
    _now.subtract(Duration(days: days, hours: hours, minutes: minutes));

final List<ChatChannel> seedChannels = [
  ChatChannel(
    id: 'deal-apollo',
    type: ConversationType.channel,
    displayName: 'deal-apollo',
    lastMessage: 'Sofia: LOI draft attached — please review before EOD',
    lastMessageAt: _ago(minutes: 8),
    unreadCount: 3,
    memberCount: '6',
  ),
  ChatChannel(
    id: 'compliance',
    type: ConversationType.channel,
    displayName: 'compliance',
    lastMessage: 'KYC cleared for Quantum Capital — all docs on file',
    lastMessageAt: _ago(minutes: 42),
    unreadCount: 9,
    memberCount: '4',
  ),
  ChatChannel(
    id: 'general',
    type: ConversationType.channel,
    displayName: 'general',
    lastMessage: 'Raj: Q3 sourcing list is ready — link in thread',
    lastMessageAt: _ago(hours: 3),
    unreadCount: 0,
    memberCount: '12',
  ),
  ChatChannel(
    id: 'deals',
    type: ConversationType.channel,
    displayName: 'deals',
    lastMessage: 'New term sheet from Meridian — \$42M Series B',
    lastMessageAt: _ago(hours: 5),
    unreadCount: 0,
    memberCount: '8',
  ),
  ChatChannel(
    id: 'sourcing',
    type: ConversationType.channel,
    displayName: 'sourcing',
    lastMessage: 'Alex: Added 3 new leads from the LP event',
    lastMessageAt: _ago(days: 1),
    unreadCount: 0,
    memberCount: '7',
  ),
];

final List<ChatChannel> seedDMs = [
  ChatChannel(
    id: 'dm-sofia',
    type: ConversationType.dm,
    displayName: 'Sofia Pereira',
    lastMessage: 'You: thanks, sending the deck now',
    lastMessageAt: _ago(hours: 1),
    unreadCount: 0,
    isOnline: true,
  ),
  ChatChannel(
    id: 'dm-raj',
    type: ConversationType.dm,
    displayName: 'Raj Patel',
    lastMessage: "I'll loop in the compliance team on this",
    lastMessageAt: _ago(hours: 4),
    unreadCount: 2,
    isOnline: false,
  ),
  ChatChannel(
    id: 'dm-alex',
    type: ConversationType.dm,
    displayName: 'Alex Marsh',
    lastMessage: 'Can we sync tomorrow morning?',
    lastMessageAt: _ago(days: 1, hours: 2),
    unreadCount: 0,
    isOnline: true,
  ),
];

// ── Seed messages per channel ─────────────────────────────────────────────────

List<ChatMessage> _seedMessagesForChannel(String channelId) {
  switch (channelId) {
    case 'deal-apollo':
      return [
        ChatMessage(
          id: 'da-1',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'Morning everyone — just got off a call with Apollo\'s legal team. They want to move quickly on this.',
          sentAt: _ago(hours: 5, minutes: 12),
        ),
        ChatMessage(
          id: 'da-2',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: 'That\'s great news. What\'s their target close date?',
          sentAt: _ago(hours: 4, minutes: 58),
          reactions: [
            const MessageReaction(emoji: '👍', count: 2),
          ],
        ),
        ChatMessage(
          id: 'da-3',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'They\'re pushing for end of Q3. I think we can make that work if DD wraps up by the 15th.',
          sentAt: _ago(hours: 4, minutes: 51),
        ),
        ChatMessage(
          id: 'da-4',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'I\'ll coordinate with the legal team on the DD timeline. Should have an update by Thursday.',
          sentAt: _ago(hours: 2, minutes: 30),
          reactions: [
            const MessageReaction(emoji: '🙌', count: 3),
          ],
        ),
        ChatMessage(
          id: 'da-5',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'LOI draft attached — please review before EOD. I\'ve highlighted the key terms in section 4.',
          sentAt: _ago(minutes: 8),
          reactions: [
            const MessageReaction(emoji: '👀', count: 4),
            const MessageReaction(emoji: '✅', count: 1),
          ],
        ),
      ];

    case 'compliance':
      return [
        ChatMessage(
          id: 'co-1',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'KYC docs for Quantum Capital are now fully on file. Enhanced due diligence complete.',
          sentAt: _ago(hours: 3, minutes: 20),
          reactions: [
            const MessageReaction(emoji: '✅', count: 5),
          ],
        ),
        ChatMessage(
          id: 'co-2',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: 'Cleared. Good to proceed with onboarding. AML screening came back clean.',
          sentAt: _ago(hours: 2, minutes: 45),
        ),
        ChatMessage(
          id: 'co-3',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'Perfect. I\'ll notify the client relationship team to move forward.',
          sentAt: _ago(minutes: 42),
        ),
      ];

    case 'general':
      return [
        ChatMessage(
          id: 'ge-1',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: 'Q3 sourcing list is ready 🎯 I\'ve added 12 new targets from the LP event last week. Link in the doc.',
          sentAt: _ago(hours: 3, minutes: 15),
          reactions: [
            const MessageReaction(emoji: '🔥', count: 6),
            const MessageReaction(emoji: '👍', count: 3),
          ],
        ),
        ChatMessage(
          id: 'ge-2',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Impressive list. Two of those are already warm — Apex Ventures and Northgate PE.',
          sentAt: _ago(hours: 2, minutes: 50),
        ),
        ChatMessage(
          id: 'ge-3',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'I\'ll reach out to Apex this week. We had a good conversation at the London conference.',
          sentAt: _ago(hours: 2, minutes: 44),
          reactions: [
            const MessageReaction(emoji: '💪', count: 2),
          ],
        ),
      ];

    case 'deals':
      return [
        ChatMessage(
          id: 'de-1',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Meridian Group sent over a new term sheet — \$42M Series B at a 4.2x valuation cap. Strong terms.',
          sentAt: _ago(hours: 5),
          reactions: [
            const MessageReaction(emoji: '🤑', count: 4),
          ],
        ),
        ChatMessage(
          id: 'de-2',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: 'Solid. Do they have pro-rata rights on follow-ons? That\'s usually a sticking point.',
          sentAt: _ago(hours: 4, minutes: 45),
        ),
        ChatMessage(
          id: 'de-3',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Yes, they want 20% pro-rata with a 45-day notice window. Comparable to market.',
          sentAt: _ago(hours: 4, minutes: 30),
          reactions: [
            const MessageReaction(emoji: '👍', count: 2),
            const MessageReaction(emoji: '🤔', count: 1),
          ],
        ),
      ];

    case 'sourcing':
      return [
        ChatMessage(
          id: 'so-1',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Just added 3 new leads from the Fintech Summit last night. All pre-revenue but strong teams.',
          sentAt: _ago(days: 1, hours: 2),
          reactions: [
            const MessageReaction(emoji: '👏', count: 3),
          ],
        ),
        ChatMessage(
          id: 'so-2',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'Great catch on Luminary AI — their seed deck looks impressive. Worth a follow-up call.',
          sentAt: _ago(days: 1, hours: 1),
        ),
      ];

    case 'dm-sofia':
      return [
        ChatMessage(
          id: 'ds-1',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'Hey! Can you send me the Apollo deck? Need it for the partner meeting at 3pm.',
          sentAt: _ago(hours: 2, minutes: 30),
        ),
        ChatMessage(
          id: 'ds-2',
          channelId: channelId,
          authorId: 'me',
          authorName: 'You',
          authorInitials: 'YO',
          authorColor: AppColors.gold500,
          body: 'Of course, give me 5 minutes to update the latest figures first.',
          sentAt: _ago(hours: 2, minutes: 22),
        ),
        ChatMessage(
          id: 'ds-3',
          channelId: channelId,
          authorId: 'sofia',
          authorName: 'Sofia Pereira',
          authorInitials: 'SP',
          authorColor: avatarColorFor('Sofia Pereira'),
          body: 'Perfect, no rush 👍',
          sentAt: _ago(hours: 2, minutes: 20),
          reactions: [
            const MessageReaction(emoji: '❤️', count: 1),
          ],
        ),
        ChatMessage(
          id: 'ds-4',
          channelId: channelId,
          authorId: 'me',
          authorName: 'You',
          authorInitials: 'YO',
          authorColor: AppColors.gold500,
          body: 'thanks, sending the deck now',
          sentAt: _ago(hours: 1),
        ),
      ];

    case 'dm-raj':
      return [
        ChatMessage(
          id: 'dr-1',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: 'Quick question on the Northgate deal — are we leading or co-investing?',
          sentAt: _ago(hours: 5),
        ),
        ChatMessage(
          id: 'dr-2',
          channelId: channelId,
          authorId: 'me',
          authorName: 'You',
          authorInitials: 'YO',
          authorColor: AppColors.gold500,
          body: 'Co-investing alongside Harbor Capital. They\'re leading at \$35M, we\'re coming in at \$15M.',
          sentAt: _ago(hours: 4, minutes: 50),
        ),
        ChatMessage(
          id: 'dr-3',
          channelId: channelId,
          authorId: 'raj',
          authorName: 'Raj Patel',
          authorInitials: 'RP',
          authorColor: avatarColorFor('Raj Patel'),
          body: "I'll loop in the compliance team on this — they'll want sight of Harbor's LP documents too.",
          sentAt: _ago(hours: 4),
        ),
      ];

    case 'dm-alex':
      return [
        ChatMessage(
          id: 'da-dm-1',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Are you free for a quick catch-up on the sourcing pipeline?',
          sentAt: _ago(days: 1, hours: 3),
        ),
        ChatMessage(
          id: 'da-dm-2',
          channelId: channelId,
          authorId: 'me',
          authorName: 'You',
          authorInitials: 'YO',
          authorColor: AppColors.gold500,
          body: 'Sure, tomorrow works. Morning or afternoon?',
          sentAt: _ago(days: 1, hours: 2, minutes: 45),
        ),
        ChatMessage(
          id: 'da-dm-3',
          channelId: channelId,
          authorId: 'alex',
          authorName: 'Alex Marsh',
          authorInitials: 'AM',
          authorColor: avatarColorFor('Alex Marsh'),
          body: 'Can we sync tomorrow morning?',
          sentAt: _ago(days: 1, hours: 2),
        ),
      ];

    default:
      return [];
  }
}

// ── Channel info lookup ───────────────────────────────────────────────────────

ChatChannel? channelById(String id) {
  for (final c in [...seedChannels, ...seedDMs]) {
    if (c.id == id) return c;
  }
  return null;
}

// ── Riverpod: per-channel message list (in-memory store) ─────────────────────

class ChannelMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChannelMessagesNotifier(this.channelId) : super(_seedMessagesForChannel(channelId));

  final String channelId;

  void sendMessage({
    required String body,
    required String authorId,
    required String authorName,
    required String authorInitials,
    required Color authorColor,
  }) {
    final optimisticId = 'opt-${DateTime.now().millisecondsSinceEpoch}';
    final msg = ChatMessage(
      id: optimisticId,
      channelId: channelId,
      authorId: authorId,
      authorName: authorName,
      authorInitials: authorInitials,
      authorColor: authorColor,
      body: body,
      sentAt: DateTime.now(),
      isOptimistic: true,
    );
    state = [...state, msg];

    // Attempt to persist to Supabase; ignore failure.
    _persist(msg, optimisticId);
  }

  Future<void> _persist(ChatMessage msg, String optimisticId) async {
    try {
      final row = await supabase.from('messages').insert({
        'channel_id': msg.channelId,
        'author_id': msg.authorId,
        'author_name': msg.authorName,
        'body': msg.body,
        'sent_at': msg.sentAt.toIso8601String(),
      }).select().maybeSingle();
      if (row != null) {
        final realId = row['id']?.toString() ?? optimisticId;
        state = state.map((m) {
          if (m.id == optimisticId) return m.copyWith(id: realId, isOptimistic: false);
          return m;
        }).toList();
      }
    } catch (_) {
      // Degrade gracefully — message stays in-memory.
    }
  }
}

final channelMessagesProvider = StateNotifierProvider.family<
    ChannelMessagesNotifier, List<ChatMessage>, String>(
  (ref, channelId) => ChannelMessagesNotifier(channelId),
);

// ── Riverpod: channel list (combines seed + optional Supabase) ────────────────

class ChannelListNotifier extends StateNotifier<List<ChatChannel>> {
  ChannelListNotifier() : super([...seedChannels]);

  void _mergeFromSupabase(List<Map<String, dynamic>> rows) {
    final existing = {for (final c in state) c.id: c};
    final merged = rows.map((r) {
      final id = r['id']?.toString() ?? '';
      return existing[id] ??
          ChatChannel(
            id: id,
            type: ConversationType.channel,
            displayName: (r['name'] ?? id).toString(),
            lastMessage: r['last_message'] as String?,
            memberCount: r['member_count']?.toString(),
          );
    }).toList();
    // Keep DMs separate, merge channels.
    state = merged;
  }

  Future<void> loadFromSupabase() async {
    try {
      final rows = await supabase
          .from('channels')
          .select()
          .order('updated_at', ascending: false)
          .limit(50);
      if ((rows as List).isNotEmpty) {
        _mergeFromSupabase(rows.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      // Fall back to seed data.
    }
  }
}

final channelListProvider =
    StateNotifierProvider<ChannelListNotifier, List<ChatChannel>>(
  (ref) => ChannelListNotifier(),
);
