import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../widgets/app_widgets.dart';

/// Temporary scaffold used by screens still being built out by the agent team.
/// Provides a consistent Onyx & Gold frame so the route is never blank.
class StubScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String note;
  final Color accent;
  const StubScaffold({
    super.key,
    required this.title,
    this.icon = Icons.construction,
    this.note = 'Building this experience…',
    this.accent = AppColors.gold500,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          DarkHeader(
            title: title,
            accent: accent,
            leading: GestureDetector(
              onTap: () => context.canPop() ? context.pop() : context.go('/more'),
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
          Expanded(child: EmptyStateView(message: note, icon: icon)),
        ],
      ),
    );
  }
}
