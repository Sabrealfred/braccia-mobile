import 'package:flutter/material.dart';
import 'theme.dart';

enum ModuleKind { kpi, chat, list, bespoke }

enum ModuleGroup { crm, finance, work, admin }

class AppModule {
  final String id; // route slug
  final String label;
  final IconData icon;
  final ModuleGroup group;
  final ModuleKind kind;
  final String? table; // Supabase table backing the screen, if any
  final bool special; // Credit Stack cream tile
  final bool bespoke; // has a dedicated screen route

  const AppModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.group,
    required this.kind,
    this.table,
    this.special = false,
    this.bespoke = false,
  });

  Color get accent {
    switch (kind) {
      case ModuleKind.chat:
        return const Color(0xFF3A9D7F);
      case ModuleKind.kpi:
        return AppColors.blueOnDark;
      default:
        return AppColors.gold500;
    }
  }

  Color get tint {
    switch (group) {
      case ModuleGroup.crm:
        return AppColors.gold500.withValues(alpha: 0.16);
      case ModuleGroup.finance:
        return AppColors.blueOnDark.withValues(alpha: 0.16);
      case ModuleGroup.work:
        return const Color(0xFF3A9D7F).withValues(alpha: 0.16);
      case ModuleGroup.admin:
        return AppColors.purpleOnDark.withValues(alpha: 0.18);
    }
  }

  Color get glyphColor {
    switch (group) {
      case ModuleGroup.crm:
        return AppColors.goldText;
      case ModuleGroup.finance:
        return AppColors.blue;
      case ModuleGroup.work:
        return AppColors.green;
      case ModuleGroup.admin:
        return AppColors.purple;
    }
  }
}

/// The full module catalog powering the "All Apps" hub and the adaptive
/// module screens. KPI/Chat/List kinds map to the three baseline templates;
/// `bespoke: true` modules have richer dedicated screens.
const List<AppModule> kModules = [
  // CRM & Sales
  AppModule(id: 'leads', label: 'Leads', icon: Icons.person_add_alt_1, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'clients', bespoke: true),
  AppModule(id: 'crm', label: 'CRM', icon: Icons.dashboard_customize, group: ModuleGroup.crm, kind: ModuleKind.kpi, table: 'clients'),
  AppModule(id: 'contacts', label: 'Contacts', icon: Icons.contacts, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'clients'),
  AppModule(id: 'companies', label: 'Companies', icon: Icons.business, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'clients'),
  AppModule(id: 'entities', label: 'Entities', icon: Icons.account_tree, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'clients'),
  AppModule(id: 'portfolios', label: 'Portfolios', icon: Icons.pie_chart, group: ModuleGroup.crm, kind: ModuleKind.kpi, table: 'portfolios'),
  AppModule(id: 'staff', label: 'Staff', icon: Icons.badge, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'user_profiles'),
  AppModule(id: 'approvals', label: 'Approvals', icon: Icons.fact_check, group: ModuleGroup.crm, kind: ModuleKind.list, table: 'approvals', bespoke: true),

  // Finance & BI
  AppModule(id: 'bi', label: 'BI', icon: Icons.insights, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'deals'),
  AppModule(id: 'funds', label: 'Funds', icon: Icons.savings, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'funds'),
  AppModule(id: 'cash', label: 'Cash', icon: Icons.account_balance_wallet, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'cash_accounts'),
  AppModule(id: 'billing', label: 'Billing', icon: Icons.receipt_long, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'invoices'),
  AppModule(id: 'wealth', label: 'Wealth', icon: Icons.public, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'clients'),
  AppModule(id: 'alts', label: 'Alts', icon: Icons.show_chart, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'alternatives'),
  AppModule(id: 'recon', label: 'Recon', icon: Icons.rule, group: ModuleGroup.finance, kind: ModuleKind.list, table: 'reconciliations'),
  AppModule(id: 'custodians', label: 'Custodians', icon: Icons.account_balance, group: ModuleGroup.finance, kind: ModuleKind.kpi, table: 'custodians'),

  // Work · Docs · AI
  AppModule(id: 'messages', label: 'Messages', icon: Icons.forum, group: ModuleGroup.work, kind: ModuleKind.chat, table: 'messages', bespoke: true),
  AppModule(id: 'tasks', label: 'Tasks', icon: Icons.checklist, group: ModuleGroup.work, kind: ModuleKind.list, table: 'tasks', bespoke: true),
  AppModule(id: 'notes', label: 'Notes', icon: Icons.sticky_note_2, group: ModuleGroup.work, kind: ModuleKind.list, table: 'consultant_notes', bespoke: true),
  AppModule(id: 'docs', label: 'Docs', icon: Icons.description, group: ModuleGroup.work, kind: ModuleKind.list, table: 'documents'),
  AppModule(id: 'docs-ai', label: 'Docs AI', icon: Icons.auto_awesome, group: ModuleGroup.work, kind: ModuleKind.list, table: 'documents'),
  AppModule(id: 'projects', label: 'Projects', icon: Icons.view_kanban, group: ModuleGroup.work, kind: ModuleKind.list, table: 'projects', bespoke: true),
  AppModule(id: 'workflows', label: 'Workflows', icon: Icons.account_tree_outlined, group: ModuleGroup.work, kind: ModuleKind.list, table: 'workflows'),
  AppModule(id: 'marketing', label: 'Marketing', icon: Icons.campaign, group: ModuleGroup.work, kind: ModuleKind.list, table: 'campaigns'),

  // Braccia & Admin
  AppModule(id: 'credit-stack', label: 'Credit ★', icon: Icons.workspace_premium, group: ModuleGroup.admin, kind: ModuleKind.list, table: 'credit_programs', special: true, bespoke: true),
  AppModule(id: 'productions', label: 'Productions', icon: Icons.movie, group: ModuleGroup.admin, kind: ModuleKind.list, table: 'productions'),
  AppModule(id: 'imports', label: 'Imports', icon: Icons.upload_file, group: ModuleGroup.admin, kind: ModuleKind.list, table: 'imports'),
  AppModule(id: 'settings', label: 'Settings', icon: Icons.settings, group: ModuleGroup.admin, kind: ModuleKind.list, bespoke: true),
];

AppModule? moduleById(String id) {
  for (final m in kModules) {
    if (m.id == id) return m;
  }
  return null;
}

List<AppModule> modulesIn(ModuleGroup g) =>
    kModules.where((m) => m.group == g).toList();

String groupLabel(ModuleGroup g) {
  switch (g) {
    case ModuleGroup.crm:
      return 'CRM & Sales';
    case ModuleGroup.finance:
      return 'Finance & BI';
    case ModuleGroup.work:
      return 'Work · Docs · AI';
    case ModuleGroup.admin:
      return 'Braccia & Admin';
  }
}
