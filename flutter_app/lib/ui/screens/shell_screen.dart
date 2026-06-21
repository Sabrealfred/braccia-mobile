import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

/// Bottom tab bar: Home · Pipeline · ✦ Braccia AI (center FAB) · Clients · More.
/// Uses go_router's StatefulNavigationShell so each tab keeps its own stack.
class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _go(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i = navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: navigationShell,
      bottomNavigationBar: _BottomBar(currentIndex: i, onTap: _go),
      extendBody: true,
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ivory.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: Color(0x0F000000)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(14, 9, 14, 10 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'Pipeline',
            icon: Icons.account_tree_rounded,
            active: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _CenterFab(active: currentIndex == 2, onTap: () => onTap(2)),
          _NavItem(
            label: 'Clients',
            icon: Icons.people_alt_rounded,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            label: 'More',
            icon: Icons.grid_view_rounded,
            active: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            active
                ? ShaderMask(
                    shaderCallback: (r) =>
                        AppColors.goldGradient.createShader(r),
                    child: Icon(icon, size: 23, color: Colors.white),
                  )
                : Icon(icon, size: 23, color: const Color(0xFFC4C2BB)),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.sans(
                size: 9.5,
                weight: FontWeight.w600,
                color: active ? AppColors.goldText : const Color(0xFFA7A59D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _CenterFab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ivory, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold500.withValues(alpha: 0.6),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: const Text('✦',
                  style: TextStyle(fontSize: 21, color: AppColors.goldInk)),
            ),
          ),
        ),
      ),
    );
  }
}
