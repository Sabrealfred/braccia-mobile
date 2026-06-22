import 'package:flutter/material.dart';

import 'analytics_bodies.dart';
import 'funds_bodies.dart';
import 'treasury_bodies.dart';
import 'wealth_bodies.dart';
import 'alts_bodies.dart';
import 'risk_bodies.dart';
import 'docs_bodies.dart';
import 'structure_bodies.dart';
import 'records_bodies.dart';
import 'growth_bodies.dart';

/// Maps a module id to a bespoke body widget rendered inside ModuleScreen's
/// frame. Modules not listed here fall back to the adaptive KPI/Chat/List
/// templates. All bodies are backed by the shared Supabase repository.
final Map<String, Widget Function()> kModuleBodies = {
  // Finance & BI
  'bi': () => const BiBody(),
  'reports': () => const ReportsBody(),
  'funds': () => const FundsBody(),
  'fund-formation': () => const FundFormationBody(),
  'cash': () => const CashBody(),
  'billing': () => const BillingBody(),
  'wealth': () => const WealthBody(),
  'attribution': () => const AttributionBody(),
  'alts': () => const AltsBody(),
  'custodians': () => const CustodiansBody(),
  'recon': () => const ReconBody(),
  'compliance': () => const ComplianceBody(),
  'portfolios': () => const PortfoliosBody(),
  // CRM records
  'entities': () => const EntitiesBody(),
  'contacts': () => const ContactsBody(),
  'companies': () => const CompaniesBody(),
  'staff': () => const StaffBody(),
  // Work · Docs
  'docs': () => const DocsBody(),
  'docs-ai': () => const DocsAiBody(),
  'marketing': () => const MarketingBody(),
  'workflows': () => const WorkflowsBody(),
  'productions': () => const ProductionsBody(),
};

Widget? moduleBodyFor(String id) {
  final builder = kModuleBodies[id];
  return builder?.call();
}
