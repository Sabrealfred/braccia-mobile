import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';
import 'ai_engine.dart';

// ── Chat models ─────────────────────────────────────────────────

enum _Sender { user, ai }

class _ChatMessage {
  final _Sender sender;
  final String text;
  final List<AiChip> chips;
  final DateTime at;

  _ChatMessage({
    required this.sender,
    required this.text,
    this.chips = const [],
    DateTime? at,
  }) : at = at ?? DateTime.now();
}

// ── Suggested questions ─────────────────────────────────────────

const _suggestions = [
  'Who owns the most pipeline?',
  'Summarize the Apollo deal',
  'Which deals are stalled?',
  'Total pipeline value?',
];

// ── Screen ──────────────────────────────────────────────────────

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen>
    with TickerProviderStateMixin {
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  late final AiEngine _engine;

  // Typing indicator animation
  late final AnimationController _dotAnim;

  @override
  void initState() {
    super.initState();
    _engine = AiEngine(repository);
    _dotAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _dotAnim.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;
    _controller.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(_ChatMessage(sender: _Sender.user, text: q));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate natural typing delay (600–900ms)
    await Future.delayed(
      Duration(milliseconds: 600 + math.Random().nextInt(300)),
    );

    final response = await _engine.answer(q);

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        sender: _Sender.ai,
        text: response.text,
        chips: response.chips,
      ));
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.aiBackdrop,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(),
              Expanded(
                child: _messages.isEmpty
                    ? _EmptyState(onSuggestion: _send)
                    : _ChatList(
                        messages: _messages,
                        isTyping: _isTyping,
                        dotAnim: _dotAnim,
                        scrollController: _scrollController,
                        onChipTap: (chip) {
                          if (chip.route != null) {
                            context.push(chip.route!);
                          }
                        },
                      ),
              ),
              _InputBar(
                controller: _controller,
                bottomPad: bottom,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          // Gold ✦ tile
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold500.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text('✦',
                style: TextStyle(fontSize: 16, color: AppColors.goldInk)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Braccia AI',
                    style: AppText.serif(
                        size: 20, color: AppColors.ivory, height: 1.1)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.greenOnDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Connected · grounded on your data',
                        style: AppText.sans(
                            size: 11.5,
                            color: AppColors.greenOnDark,
                            weight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / suggestion state ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyState({required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero greeting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppRadii.cardLarge),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How can I help?',
                    style: AppText.serif(
                        size: 26, color: AppColors.ivory, height: 1.1)),
                const SizedBox(height: 8),
                Text(
                  'Ask me anything about your pipeline, clients, deals, '
                  'or tasks — I\'m grounded on live Braccia data.',
                  style: AppText.sans(
                      size: 13.5,
                      color: AppColors.mutedOnDark,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('SUGGESTED',
              style: AppText.eyebrow(AppColors.mutedOnDark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _suggestions)
                Pressable(
                  onTap: () => onSuggestion(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✦',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.gold300
                                    .withValues(alpha: 0.7))),
                        const SizedBox(width: 7),
                        Text(s,
                            style: AppText.sans(
                                size: 13,
                                color: AppColors.ivory,
                                weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat list ────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  final List<_ChatMessage> messages;
  final bool isTyping;
  final AnimationController dotAnim;
  final ScrollController scrollController;
  final void Function(AiChip) onChipTap;

  const _ChatList({
    required this.messages,
    required this.isTyping,
    required this.dotAnim,
    required this.scrollController,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isTyping ? 1 : 0);
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        if (i == messages.length) {
          // Typing indicator
          return _TypingIndicator(anim: dotAnim);
        }
        final msg = messages[i];
        return msg.sender == _Sender.user
            ? _UserBubble(text: msg.text)
            : _AiBubble(
                text: msg.text,
                chips: msg.chips,
                onChipTap: onChipTap,
              );
      },
    );
  }
}

// ── User bubble ───────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 60),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Text(
                text,
                style: AppText.sans(
                    size: 14,
                    color: AppColors.goldInk,
                    weight: FontWeight.w500,
                    height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI bubble ─────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final String text;
  final List<AiChip> chips;
  final void Function(AiChip) onChipTap;

  const _AiBubble({
    required this.text,
    required this.chips,
    required this.onChipTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2, right: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text('✦',
                style: TextStyle(fontSize: 12, color: AppColors.goldInk)),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    text,
                    style: AppText.sans(
                        size: 13.5,
                        color: AppColors.ivory,
                        height: 1.55),
                  ),
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .map((c) => _ActionChip(
                              chip: c,
                              onTap: () => onChipTap(c),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ── Action chip ───────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final AiChip chip;
  final VoidCallback onTap;
  const _ActionChip({required this.chip, required this.onTap});

  Color get _fg {
    switch (chip.kind) {
      case AiChipKind.gold:
        return AppColors.goldInk;
      case AiChipKind.green:
        return AppColors.greenOnDark;
      case AiChipKind.blue:
        return AppColors.blueOnDark;
    }
  }

  Gradient? get _gradient {
    if (chip.kind == AiChipKind.gold) return AppColors.goldGradient;
    return null;
  }

  Color? get _bgColor {
    switch (chip.kind) {
      case AiChipKind.gold:
        return null;
      case AiChipKind.green:
        return AppColors.green.withValues(alpha: 0.18);
      case AiChipKind.blue:
        return AppColors.blue.withValues(alpha: 0.18);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          gradient: _gradient,
          color: _bgColor,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: chip.kind != AiChipKind.gold
              ? Border.all(
                  color: _fg.withValues(alpha: 0.25))
              : null,
          boxShadow: chip.kind == AiChipKind.gold
              ? [
                  BoxShadow(
                    color:
                        AppColors.gold500.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Text(chip.label,
            style: AppText.sans(
                size: 12,
                color: _fg,
                weight: FontWeight.w600)),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final Animation<double> anim;
  const _TypingIndicator({required this.anim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text('✦',
                style: TextStyle(fontSize: 12, color: AppColors.goldInk)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: AnimatedBuilder(
              animation: anim,
              builder: (context2, child2) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    // Stagger each dot by 0.33
                    final phase = (anim.value + i / 3.0) % 1.0;
                    // Bounce: up during first half, down during second
                    final offset = phase < 0.5
                        ? -4.0 * math.sin(phase * math.pi)
                        : 0.0;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < 2 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.mutedOnDark
                                .withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final double bottomPad;
  final void Function(String) onSend;

  const _InputBar({
    required this.controller,
    required this.bottomPad,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, math.max(bottomPad, 16)),
      decoration: BoxDecoration(
        color: AppColors.onyx800.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius:
                    BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: controller,
                style: AppText.sans(
                    size: 14, color: AppColors.ivory),
                cursorColor: AppColors.gold300,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 13),
                  hintText: 'Ask anything…',
                  hintStyle: AppText.sans(
                      size: 14,
                      color: AppColors.mutedOnDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.5),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: AppColors.goldInk, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
