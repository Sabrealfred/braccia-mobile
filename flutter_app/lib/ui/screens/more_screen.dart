import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/modules.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';

/// "All Apps" hub — a searchable grid of every module, grouped.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(AppModule m) {
    if (m.id == 'ai') {
      context.go('/ai'); // AI is a root tab
    } else if (m.bespoke) {
      context.push('/${m.id}');
    } else {
      context.push('/module/${m.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    return Container(
      color: AppColors.ivory,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DarkHeader(
            title: 'All Apps',
            bottom: DarkSearchField(
              hint: 'Search modules & records',
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in ModuleGroup.values)
                  ..._buildGroup(group, q),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroup(ModuleGroup group, String q) {
    final mods = modulesIn(group)
        .where((m) => q.isEmpty || m.label.toLowerCase().contains(q))
        .toList();
    if (mods.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(groupLabel(group).toUpperCase(),
            style: AppText.eyebrow(AppColors.mutedLight)),
      ),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: [for (final m in mods) _ModuleTile(module: m, onTap: () => _open(m))],
      ),
      const SizedBox(height: 22),
    ];
  }
}

class _ModuleTile extends StatelessWidget {
  final AppModule module;
  final VoidCallback onTap;
  const _ModuleTile({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final special = module.special;
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: special
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFFDF4E2)],
                      )
                    : null,
                color: special ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.tile),
                border: Border.all(
                    color: special
                        ? const Color(0xFFECDCB6)
                        : AppColors.hairline),
                boxShadow: [
                  BoxShadow(
                    color: special
                        ? AppColors.gold500.withValues(alpha: 0.5)
                        : const Color(0x1A000000),
                    blurRadius: special ? 18 : 16,
                    offset: const Offset(0, 8),
                    spreadRadius: special ? -10 : -12,
                  ),
                ],
              ),
              child: special
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    )
                  : Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: module.tint,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(module.icon,
                          size: 19, color: module.glyphColor),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            module.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 10,
              weight: special ? FontWeight.w700 : FontWeight.w500,
              color: special ? const Color(0xFF8A6508) : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
