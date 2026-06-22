import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Seed data helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SeedContact {
  final String id;
  final String name;
  final String role;
  final String company;
  final Color avatarColor;

  const _SeedContact({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.avatarColor,
  });
}

const _seedContacts = <_SeedContact>[
  _SeedContact(
    id: 'seed-c1',
    name: 'Marcus Chen',
    role: 'Principal',
    company: 'Chen Family Office',
    avatarColor: Color(0xFF3D6A90),
  ),
  _SeedContact(
    id: 'seed-c2',
    name: 'Sofia Pereira',
    role: 'Managing Director',
    company: 'Braccia Capital',
    avatarColor: Color(0xFF7A5F7D),
  ),
  _SeedContact(
    id: 'seed-c3',
    name: 'Raj Khanna',
    role: 'Partner',
    company: 'Meridian Group',
    avatarColor: Color(0xFF2E7D65),
  ),
  _SeedContact(
    id: 'seed-c4',
    name: 'Amara Osei',
    role: 'CFO',
    company: 'Atlas Mining Ltd',
    avatarColor: Color(0xFFC79A3E),
  ),
  _SeedContact(
    id: 'seed-c5',
    name: 'Lena Hartmann',
    role: 'General Partner',
    company: 'Innovation Labs',
    avatarColor: Color(0xFFC0473D),
  ),
  _SeedContact(
    id: 'seed-c6',
    name: 'David Nakamura',
    role: 'Investor Relations',
    company: 'Quantum Capital',
    avatarColor: Color(0xFF4D7EA8),
  ),
  _SeedContact(
    id: 'seed-c7',
    name: 'Chiara Russo',
    role: 'Associate',
    company: 'Braccia Capital',
    avatarColor: Color(0xFF7A5F7D),
  ),
  _SeedContact(
    id: 'seed-c8',
    name: 'Omar Al-Rashid',
    role: 'Director',
    company: 'Gulf Sovereign Partners',
    avatarColor: Color(0xFF3D6A90),
  ),
];

class _SeedCompany {
  final String id;
  final String name;
  final String sector;
  final int contactCount;
  final int dealCount;
  final double aum;

  const _SeedCompany({
    required this.id,
    required this.name,
    required this.sector,
    required this.contactCount,
    required this.dealCount,
    required this.aum,
  });
}

const _seedCompanies = <_SeedCompany>[
  _SeedCompany(
    id: 'seed-co1',
    name: 'Quantum Capital',
    sector: 'Private Equity',
    contactCount: 5,
    dealCount: 3,
    aum: 480e6,
  ),
  _SeedCompany(
    id: 'seed-co2',
    name: 'Innovation Labs',
    sector: 'Tech',
    contactCount: 3,
    dealCount: 1,
    aum: 120e6,
  ),
  _SeedCompany(
    id: 'seed-co3',
    name: 'Meridian Group',
    sector: 'Real Estate',
    contactCount: 7,
    dealCount: 2,
    aum: 295e6,
  ),
  _SeedCompany(
    id: 'seed-co4',
    name: 'Atlas Mining Ltd',
    sector: 'Commodities',
    contactCount: 4,
    dealCount: 1,
    aum: 88e6,
  ),
  _SeedCompany(
    id: 'seed-co5',
    name: 'Chen Family Office',
    sector: 'Family Office',
    contactCount: 2,
    dealCount: 1,
    aum: 640e6,
  ),
  _SeedCompany(
    id: 'seed-co6',
    name: 'Gulf Sovereign Partners',
    sector: 'Sovereign Wealth',
    contactCount: 6,
    dealCount: 4,
    aum: 1200e6,
  ),
];

class _SeedStaff {
  final String name;
  final String role;
  final String department;

  const _SeedStaff({
    required this.name,
    required this.role,
    required this.department,
  });
}

const _seedStaff = <_SeedStaff>[
  _SeedStaff(
    name: 'Alessandro Braccia',
    role: 'Managing Partner',
    department: 'Leadership',
  ),
  _SeedStaff(
    name: 'Sofia Pereira',
    role: 'Managing Director',
    department: 'Investment',
  ),
  _SeedStaff(
    name: 'James Whitfield',
    role: 'Senior Partner',
    department: 'Investment',
  ),
  _SeedStaff(
    name: 'Priya Nair',
    role: 'Vice President',
    department: 'Operations',
  ),
  _SeedStaff(
    name: 'Chiara Russo',
    role: 'Associate',
    department: 'Investment',
  ),
  _SeedStaff(
    name: 'Thomas Bauer',
    role: 'Analyst',
    department: 'Research',
  ),
  _SeedStaff(
    name: 'Yuki Tanaka',
    role: 'Compliance Officer',
    department: 'Legal & Compliance',
  ),
  _SeedStaff(
    name: 'Nina Okafor',
    role: 'Head of IR',
    department: 'Investor Relations',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Avatar colors — cycles through brand palette
// ─────────────────────────────────────────────────────────────────────────────

const _avatarPalette = <Color>[
  Color(0xFF3D6A90),
  Color(0xFF7A5F7D),
  Color(0xFF2E7D65),
  Color(0xFFC79A3E),
  Color(0xFF4D7EA8),
  Color(0xFFC0473D),
];

Color _paletteColor(int index) => _avatarPalette[index % _avatarPalette.length];

// ─────────────────────────────────────────────────────────────────────────────
// Shared: light search field (ivory background)
// ─────────────────────────────────────────────────────────────────────────────

class _LightSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _LightSearchField({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Color(0xFFB0AFA7)),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.sans(size: 13),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    AppText.sans(size: 13, color: const Color(0xFFB0AFA7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: divider row inside AppCard
// ─────────────────────────────────────────────────────────────────────────────

const _kRowDivider = Border(
  bottom: BorderSide(color: AppColors.hairlineSoft),
);

// ─────────────────────────────────────────────────────────────────────────────
// ContactsBody
// ─────────────────────────────────────────────────────────────────────────────

class ContactsBody extends ConsumerStatefulWidget {
  const ContactsBody({super.key});

  @override
  ConsumerState<ContactsBody> createState() => _ContactsBodyState();
}

class _ContactsBodyState extends ConsumerState<ContactsBody> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clientsProvider);

    return Stack(
      children: [
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => _buildList(context, []),
          data: (clients) {
            // Filter to individuals; fall back to seeds if empty.
            final individuals = clients
                .where((c) =>
                    c.clientType == 'individual' ||
                    c.clientType == null ||
                    c.clientType!.isEmpty)
                .toList();
            return _buildList(context, individuals);
          },
        ),
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(onTap: () {}),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Client> clients) {
    // Build display rows: real data first, then seeds if needed.
    final List<_ContactRow> rows;
    if (clients.isNotEmpty) {
      rows = clients.map((c) {
        final idx = clients.indexOf(c);
        return _ContactRow(
          id: c.id,
          name: c.name,
          role: c.raw['role'] as String? ?? 'Contact',
          company: c.company ?? '—',
          avatarColor: _paletteColor(idx),
        );
      }).toList();
    } else {
      rows = _seedContacts
          .map((s) => _ContactRow(
                id: s.id,
                name: s.name,
                role: s.role,
                company: s.company,
                avatarColor: s.avatarColor,
              ))
          .toList();
    }

    // Apply search filter.
    final filtered = _q.isEmpty
        ? rows
        : rows
            .where((r) =>
                r.name.toLowerCase().contains(_q.toLowerCase()) ||
                r.company.toLowerCase().contains(_q.toLowerCase()) ||
                r.role.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        _LightSearchField(
          hint: 'Search contacts…',
          controller: _ctrl,
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 14),
        SectionHead(
          'All Contacts',
          trailing: Text(
            '${filtered.length}',
            style: AppText.sans(size: 12.5, color: AppColors.muted),
          ),
        ),
        if (filtered.isEmpty)
          const EmptyStateView(
              message: 'No contacts match your search.',
              icon: Icons.person_search_outlined)
        else
          AppCard(
            noPadding: true,
            radius: AppRadii.card,
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++)
                  _contactTile(
                    context,
                    filtered[i],
                    isLast: i == filtered.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contactTile(BuildContext context, _ContactRow row,
      {required bool isLast}) {
    return Pressable(
      onTap: () => context.push('/client/${row.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : _kRowDivider,
        ),
        child: Row(
          children: [
            AvatarDot(
              initials: initialsOf(row.name),
              color: row.avatarColor,
              size: 42,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${row.role} · ${row.company}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.mutedLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow {
  final String id;
  final String name;
  final String role;
  final String company;
  final Color avatarColor;

  const _ContactRow({
    required this.id,
    required this.name,
    required this.role,
    required this.company,
    required this.avatarColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CompaniesBody
// ─────────────────────────────────────────────────────────────────────────────

class CompaniesBody extends ConsumerStatefulWidget {
  const CompaniesBody({super.key});

  @override
  ConsumerState<CompaniesBody> createState() => _CompaniesBodyState();
}

class _CompaniesBodyState extends ConsumerState<CompaniesBody> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clientsProvider);

    return Stack(
      children: [
        async.when(
          loading: () => const LoadingState(),
          error: (e, _) => _buildList(context, []),
          data: (clients) {
            final entities = clients
                .where((c) =>
                    c.clientType == 'entity' || c.clientType == 'company')
                .toList();
            return _buildList(context, entities);
          },
        ),
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(onTap: () {}),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Client> clients) {
    final List<_CompanyRow> rows;
    if (clients.isNotEmpty) {
      rows = clients.map((c) {
        final idx = clients.indexOf(c);
        return _CompanyRow(
          id: c.id,
          name: c.name,
          sector: c.industry ?? 'Financial Services',
          contactCount: 0,
          dealCount: 0,
          aum: c.totalAum,
          color: _paletteColor(idx),
        );
      }).toList();
    } else {
      rows = _seedCompanies
          .map((s) => _CompanyRow(
                id: s.id,
                name: s.name,
                sector: s.sector,
                contactCount: s.contactCount,
                dealCount: s.dealCount,
                aum: s.aum,
                color: _paletteColor(_seedCompanies.indexOf(s)),
              ))
          .toList();
    }

    final filtered = _q.isEmpty
        ? rows
        : rows
            .where((r) =>
                r.name.toLowerCase().contains(_q.toLowerCase()) ||
                r.sector.toLowerCase().contains(_q.toLowerCase()))
            .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        _LightSearchField(
          hint: 'Search companies…',
          controller: _ctrl,
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 14),
        SectionHead(
          'Companies',
          trailing: Text(
            '${filtered.length}',
            style: AppText.sans(size: 12.5, color: AppColors.muted),
          ),
        ),
        if (filtered.isEmpty)
          const EmptyStateView(
              message: 'No companies match your search.',
              icon: Icons.business_outlined)
        else
          AppCard(
            noPadding: true,
            radius: AppRadii.card,
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++)
                  _companyTile(
                    context,
                    filtered[i],
                    isLast: i == filtered.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _companyTile(BuildContext context, _CompanyRow row,
      {required bool isLast}) {
    final subtitle = _buildSubtitle(row);
    return Pressable(
      onTap: () => context.push('/client/${row.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : _kRowDivider,
        ),
        child: Row(
          children: [
            MonogramTile(initials: initialsOf(row.name), size: 44),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (row.aum != null)
              Text(
                formatCompactCurrency(row.aum),
                style: AppText.serif(size: 14, color: AppColors.goldText),
              ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle(_CompanyRow row) {
    final parts = <String>[row.sector];
    if (row.contactCount > 0) {
      parts.add('${row.contactCount} contact${row.contactCount != 1 ? 's' : ''}');
    }
    if (row.dealCount > 0) {
      parts.add('${row.dealCount} deal${row.dealCount != 1 ? 's' : ''}');
    }
    return parts.join(' · ');
  }
}

class _CompanyRow {
  final String id;
  final String name;
  final String sector;
  final int contactCount;
  final int dealCount;
  final double? aum;
  final Color color;

  const _CompanyRow({
    required this.id,
    required this.name,
    required this.sector,
    required this.contactCount,
    required this.dealCount,
    required this.aum,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// StaffBody
// ─────────────────────────────────────────────────────────────────────────────

/// Local provider for user_profiles fetched via the generic fetchTable method.
final _staffTableProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('user_profiles', orderBy: 'full_name');
});

class StaffBody extends ConsumerWidget {
  const StaffBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_staffTableProvider);
    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildList([]),
      data: (rows) => _buildList(rows),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> rows) {
    final List<_StaffRow> members;
    if (rows.isNotEmpty) {
      members = rows.map((r) {
        final idx = rows.indexOf(r);
        final fullName = (r['full_name'] ??
                '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'
                    .trim())
            .toString()
            .trim();
        final name =
            fullName.isNotEmpty ? fullName : (r['email'] ?? 'Team Member').toString();
        return _StaffRow(
          name: name,
          role: (r['role'] ?? 'Staff').toString(),
          department: (r['department'] ?? '').toString(),
          color: _paletteColor(idx),
        );
      }).toList();
    } else {
      members = _seedStaff
          .map((s) => _StaffRow(
                name: s.name,
                role: s.role,
                department: s.department,
                color: _paletteColor(_seedStaff.indexOf(s)),
              ))
          .toList();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${members.length} Members',
                style: AppText.sans(
                    size: 12, color: AppColors.muted, weight: FontWeight.w500),
              ),
              StatusPill(
                label: 'Active',
                color: AppColors.green,
                bg: AppColors.green.withValues(alpha: 0.12),
              ),
            ],
          ),
        ),
        AppCard(
          noPadding: true,
          radius: AppRadii.card,
          child: Column(
            children: [
              for (int i = 0; i < members.length; i++)
                _staffTile(members[i], isLast: i == members.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _staffTile(_StaffRow member, {required bool isLast}) {
    final subtitle = member.department.isNotEmpty
        ? '${member.role} · ${member.department}'
        : member.role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : _kRowDivider,
      ),
      child: Row(
        children: [
          AvatarDot(
            initials: initialsOf(member.name),
            color: member.color,
            size: 42,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            label: 'Active',
            color: AppColors.green,
            bg: AppColors.green.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _StaffRow {
  final String name;
  final String role;
  final String department;
  final Color color;

  const _StaffRow({
    required this.name,
    required this.role,
    required this.department,
    required this.color,
  });
}
