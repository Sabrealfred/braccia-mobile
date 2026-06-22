import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Shared "Onyx & Gold" widget kit. Feature screens compose these so the whole
/// app stays visually consistent with the prototype.

/// White card with hairline border + soft shadow (the standard light card).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final bool noPadding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.radius = AppRadii.card,
    this.noPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 22,
            offset: Offset(0, 8),
            spreadRadius: -16,
          ),
        ],
      ),
      padding: noPadding ? EdgeInsets.zero : padding,
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap!, child: card);
  }
}

/// Dark gradient card (hero / AI insight).
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient gradient;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.cardLarge,
    this.onTap,
    this.gradient = AppColors.darkCardGradient,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 40,
            offset: Offset(0, 18),
            spreadRadius: -22,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap!, child: card);
  }
}

/// Scale-on-press feedback wrapper (transform: scale(.98) in the prototype).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const Pressable({super.key, required this.child, required this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: widget.child,
      ),
    );
  }
}

/// Status pill (active / prospect / flag / pending / done / review …).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  /// Maps a status string to the prototype's color scheme.
  factory StatusPill.forStatus(String? status) {
    final s = (status ?? '').toLowerCase();
    Color c = AppColors.muted;
    Color b = AppColors.hairlineSoft;
    if (['active', 'done', 'completed', 'won', 'closed_won', 'approved', 'cleared']
        .contains(s)) {
      c = AppColors.green;
      b = AppColors.green.withValues(alpha: 0.12);
    } else if (['prospect', 'pending', 'raising', 'in_progress', 'negotiation']
        .contains(s)) {
      c = AppColors.goldTextSoft;
      b = AppColors.gold500.withValues(alpha: 0.16);
    } else if (['flag', 'review', 'overdue', 'lost', 'closed_lost', 'rejected',
        'inactive', 'archived', 'blocked']
        .contains(s)) {
      c = AppColors.red;
      b = AppColors.red.withValues(alpha: 0.12);
    } else if (['dd', 'due_diligence', 'info', 'new'].contains(s)) {
      c = AppColors.blue;
      b = AppColors.blue.withValues(alpha: 0.12);
    }
    return StatusPill(label: status ?? '—', color: c, bg: b);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppText.sans(
            size: 10.5, color: color, weight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}

/// Full-width gold gradient button.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? () {} : (onTap ?? () {}),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -10,
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: AppColors.goldInk),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: AppText.sans(
                          size: 14,
                          color: AppColors.goldInk,
                          weight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

/// Square tinted glyph tile (used in list rows, focus cards, hub tiles).
class GlyphTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final double radius;
  const GlyphTile({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    this.size = 42,
    this.radius = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.42, color: color),
    );
  }
}

/// Dark monogram tile with gold initials (client rows).
class MonogramTile extends StatelessWidget {
  final String initials;
  final double size;
  const MonogramTile({super.key, required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.heroHeaderGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(initials,
          style: AppText.serif(size: size * 0.32, color: AppColors.gold300)),
    );
  }
}

/// Tiny circular avatar (owner stacks).
class AvatarDot extends StatelessWidget {
  final String? initials;
  final Color color;
  final double size;
  const AvatarDot({
    super.key,
    this.initials,
    this.color = const Color(0xFF5B7FA5),
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: initials == null
          ? null
          : Text(initials!,
              style: AppText.sans(
                  size: size * 0.4,
                  color: Colors.white,
                  weight: FontWeight.w600)),
    );
  }
}

/// Floating "+" action button (gold).
class GoldFab extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const GoldFab({super.key, required this.onTap, this.icon = Icons.add});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withValues(alpha: 0.6),
              blurRadius: 26,
              offset: const Offset(0, 12),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.goldInk, size: 26),
      ),
    );
  }
}

/// Simple bar sparkline (last [highlightCount] bars in gold).
class BarSparkline extends StatelessWidget {
  final List<double> values; // 0..1
  final int highlightCount;
  final double height;
  final Color baseColor;
  const BarSparkline({
    super.key,
    required this.values,
    this.highlightCount = 3,
    this.height = 46,
    this.baseColor = const Color(0x1AFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final n = values.length;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < n; i++) ...[
            Expanded(
              child: Container(
                height: (values[i].clamp(0.05, 1.0)) * height,
                decoration: BoxDecoration(
                  gradient: i >= n - highlightCount
                      ? AppColors.goldGradientVertical
                      : null,
                  color: i >= n - highlightCount ? null : baseColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i != n - 1) const SizedBox(width: 5),
          ],
        ],
      ),
    );
  }
}

/// Uppercase eyebrow + optional trailing widget.
class SectionHead extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool serif;
  final Color color;
  const SectionHead(
    this.title, {
    super.key,
    this.trailing,
    this.serif = true,
    this.color = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style: serif
                  ? AppText.serif(size: 18, color: color)
                  : AppText.eyebrow(AppColors.mutedLight)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Dark screen header used across module / list / detail screens.
class DarkHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? bottom;
  final Color? accent;
  final double bottomPadding;

  const DarkHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.bottom,
    this.accent,
    this.bottomPadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 14;
    return Container(
      width: double.infinity,
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(20, topPad, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null || actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leading ?? const SizedBox.shrink(),
                  Row(children: actions),
                ],
              ),
            ),
          Row(
            children: [
              if (accent != null) ...[
                Container(
                  width: 9,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(title,
                    style: AppText.serif(size: 24, color: AppColors.ivory)),
              ),
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 14),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Dark search field placeholder used in headers.
class DarkSearchField extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  const DarkSearchField({
    super.key,
    required this.hint,
    this.onTap,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 17, color: Color(0xFF86878D)),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: AppText.sans(size: 14, color: AppColors.ivory),
                cursorColor: AppColors.gold300,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle:
                      AppText.sans(size: 13, color: const Color(0xFF86878D)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadii.input),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 17, color: Color(0xFF86878D)),
            const SizedBox(width: 9),
            Text(hint,
                style: AppText.sans(size: 13, color: const Color(0xFF86878D))),
          ],
        ),
      ),
    );
  }
}

/// Generic async states.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColors.gold500)),
        ),
      );
}

class ErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  const ErrorStateView({super.key, required this.error, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.muted, size: 36),
            const SizedBox(height: 12),
            Text('Could not load data',
                style: AppText.sans(
                    size: 14, weight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('$error',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 12, color: AppColors.muted)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyStateView(
      {super.key, required this.message, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.muted.withValues(alpha: 0.6), size: 34),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 13.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
