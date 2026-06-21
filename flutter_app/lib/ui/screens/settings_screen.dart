import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Polished Settings screen — profile, grouped sections, sign-out.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification toggles
  bool _pushEnabled = true;
  bool _newLeads = true;
  bool _approvals = false;

  // Security toggles
  bool _biometric = false;
  bool _signingOut = false;

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        ),
        title: Text('Sign out?',
            style: AppText.serif(size: 20, color: AppColors.ink)),
        content: Text(
          'You will be returned to the login screen.',
          style: AppText.sans(size: 13.5, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.sans(
                    size: 14,
                    color: AppColors.muted,
                    weight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Sign out',
                style: AppText.sans(
                    size: 14,
                    color: AppColors.red,
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _signingOut = true);
    try {
      await supabase.auth.signOut();
      // go_router redirect on auth change handles navigation
    } catch (_) {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          // ── Dark header ─────────────────────────────────────────────────
          DarkHeader(
            title: 'Settings',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left,
                      color: AppColors.goldOnDark, size: 20),
                  Text('Back',
                      style:
                          AppText.sans(size: 14, color: AppColors.goldOnDark)),
                ],
              ),
            ),
          ),
          // ── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                // Profile card
                _ProfileCard(profile: profile),
                const SizedBox(height: 22),

                // Account
                _sectionLabel('Account'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _NavRow(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blue.withValues(alpha: 0.12),
                      label: 'Edit profile',
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.purple,
                      iconBg: AppColors.purple.withValues(alpha: 0.12),
                      label: 'Email',
                      value: profile?.email,
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.phone_outlined,
                      iconColor: AppColors.green,
                      iconBg: AppColors.green.withValues(alpha: 0.12),
                      label: 'Phone',
                      value: '+1 (555) 000-0000',
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Notifications
                _sectionLabel('Notifications'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _SwitchRow(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.goldTextSoft,
                      iconBg: AppColors.gold500.withValues(alpha: 0.12),
                      label: 'Push notifications',
                      value: _pushEnabled,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    _divider(),
                    _SwitchRow(
                      icon: Icons.person_add_alt_outlined,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blue.withValues(alpha: 0.12),
                      label: 'New leads',
                      value: _newLeads,
                      onChanged: (v) => setState(() => _newLeads = v),
                    ),
                    _divider(),
                    _SwitchRow(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.green,
                      iconBg: AppColors.green.withValues(alpha: 0.12),
                      label: 'Approvals',
                      value: _approvals,
                      onChanged: (v) => setState(() => _approvals = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Security
                _sectionLabel('Security'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _SwitchRow(
                      icon: Icons.fingerprint_rounded,
                      iconColor: AppColors.gold500,
                      iconBg: AppColors.gold500.withValues(alpha: 0.12),
                      label: 'Biometric unlock',
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.shield_outlined,
                      iconColor: AppColors.purple,
                      iconBg: AppColors.purple.withValues(alpha: 0.12),
                      label: 'Two-factor auth',
                      value: 'Enabled',
                      valueColor: AppColors.green,
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.red,
                      iconBg: AppColors.red.withValues(alpha: 0.10),
                      label: 'Change password',
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Appearance
                _sectionLabel('Appearance'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _NavRow(
                      icon: Icons.palette_outlined,
                      iconColor: AppColors.goldOnDark,
                      iconBg: AppColors.onyx700.withValues(alpha: 0.90),
                      label: 'Theme',
                      value: 'Onyx & Gold',
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.text_fields_rounded,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blue.withValues(alpha: 0.12),
                      label: 'Text size',
                      value: 'Default',
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Data & Backend
                _sectionLabel('Data & Backend'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _NavRow(
                      icon: Icons.dns_outlined,
                      iconColor: AppColors.green,
                      iconBg: AppColors.green.withValues(alpha: 0.12),
                      label: 'Supabase host',
                      value: 'ieqizooravdkcyujgiot',
                      valueColor: AppColors.muted,
                      showChevron: false,
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.sync_rounded,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blue.withValues(alpha: 0.12),
                      label: 'Sync now',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Sync complete',
                              style: AppText.sans(
                                  size: 13.5, color: AppColors.ivory),
                            ),
                            backgroundColor: AppColors.onyx700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.inner),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // About
                _sectionLabel('About'),
                AppCard(
                  noPadding: true,
                  radius: AppRadii.card,
                  child: Column(children: [
                    _NavRow(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.muted,
                      iconBg: AppColors.hairline,
                      label: 'Version',
                      value: '1.0.0',
                      showChevron: false,
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.article_outlined,
                      iconColor: AppColors.blue,
                      iconBg: AppColors.blue.withValues(alpha: 0.12),
                      label: 'Terms of Service',
                    ),
                    _divider(),
                    _NavRow(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.purple,
                      iconBg: AppColors.purple.withValues(alpha: 0.12),
                      label: 'Privacy Policy',
                    ),
                  ]),
                ),
                const SizedBox(height: 28),

                // Sign out button
                _SignOutButton(
                  loading: _signingOut,
                  onTap: _signOut,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Braccia Capital · CRM v1.0.0',
                    style: AppText.sans(size: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(),
          style: AppText.eyebrow(AppColors.mutedLight)),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 58,
      endIndent: 0,
      color: AppColors.hairlineSoft,
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName ?? 'Braccia User';
    final email = profile?.email ?? '—';
    final role = profile?.role ?? 'member';
    final initials = initialsOf(name);

    return DarkCard(
      padding: const EdgeInsets.all(20),
      radius: AppRadii.cardLarge,
      gradient: AppColors.heroHeaderGradient,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MonogramTile(initials: initials, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.serif(size: 20, color: AppColors.ivory)),
                const SizedBox(height: 3),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                        size: 12.5, color: AppColors.mutedOnDark)),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _RolePill(role: role),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(width: 8),
                    Text('Braccia Capital',
                        style: AppText.sans(
                            size: 11.5,
                            color: AppColors.goldOnDark,
                            weight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.ivory),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.gold500.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Member',
        style: AppText.sans(
          size: 10.5,
          color: isAdmin ? AppColors.gold300 : AppColors.mutedOnDark,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Settings Row Widgets ──────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? value;
  final Color? valueColor;
  final bool showChevron;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.value,
    this.valueColor,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = valueColor ?? AppColors.muted;
    final hasAction = onTap != null || showChevron;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          GlyphTile(
            icon: icon,
            color: iconColor,
            bg: iconBg,
            size: 36,
            radius: 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppText.sans(
                    size: 14,
                    color: AppColors.ink,
                    weight: FontWeight.w500)),
          ),
          if (value != null) ...[
            const SizedBox(width: 6),
            Text(value!,
                style: AppText.sans(
                    size: 13,
                    color: effectiveColor,
                    weight: FontWeight.w400)),
          ],
          if (showChevron) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFC4C2BB)),
          ],
        ],
      ),
    );

    if (!hasAction) return content;
    return Pressable(onTap: onTap ?? () {}, child: content);
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GlyphTile(
            icon: icon,
            color: iconColor,
            bg: iconBg,
            size: 36,
            radius: 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: AppText.sans(
                    size: 14,
                    color: AppColors.ink,
                    weight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold500,
            activeTrackColor: AppColors.gold500.withValues(alpha: 0.25),
            inactiveThumbColor: AppColors.mutedLight,
            inactiveTrackColor: AppColors.hairline,
          ),
        ],
      ),
    );
  }
}

// ── Sign Out Button ───────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SignOutButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? () {} : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
              spreadRadius: -8,
            ),
          ],
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.red),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 17, color: AppColors.red),
                  const SizedBox(width: 8),
                  Text('Sign out',
                      style: AppText.sans(
                          size: 14,
                          color: AppColors.red,
                          weight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
