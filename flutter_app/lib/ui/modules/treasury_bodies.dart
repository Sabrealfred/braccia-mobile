import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final _cashAccountsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('cash_accounts');
});

final _invoicesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('invoices');
});

// ─────────────────────────────────────────────────────────────────────────────
// Seed data helpers
// ─────────────────────────────────────────────────────────────────────────────

List<_AccountSeed> _seedAccounts() => [
      _AccountSeed(
        name: 'Operating Account',
        bank: 'J.P. Morgan',
        currency: 'USD',
        balance: 12480000,
        yield_: 5.12,
        syncedAgo: 'Synced 2m ago',
      ),
      _AccountSeed(
        name: 'Money Market Fund',
        bank: 'Fidelity',
        currency: 'USD',
        balance: 48250000,
        yield_: 5.31,
        syncedAgo: 'Synced 4m ago',
      ),
      _AccountSeed(
        name: 'T-Bill Ladder',
        bank: 'Fidelity',
        currency: 'USD',
        balance: 24100000,
        yield_: 5.18,
        syncedAgo: 'Synced 4m ago',
      ),
      _AccountSeed(
        name: 'Custody Account',
        bank: 'Schwab',
        currency: 'USD',
        balance: 9370000,
        yield_: 4.87,
        syncedAgo: 'Synced 12m ago',
      ),
      _AccountSeed(
        name: 'FX Reserve — EUR',
        bank: 'J.P. Morgan',
        currency: 'EUR',
        balance: 3840000,
        yield_: 3.62,
        syncedAgo: 'Synced 18m ago',
      ),
    ];

List<_InvoiceSeed> _seedInvoices() {
  final now = DateTime.now();
  return [
    _InvoiceSeed(
      client: 'Quantum Capital Partners',
      number: 'INV-2024-0412',
      amount: 185000,
      dueDate: now.subtract(const Duration(days: 8)),
      status: 'overdue',
    ),
    _InvoiceSeed(
      client: 'Atlas Mining Ltd',
      number: 'INV-2024-0411',
      amount: 92500,
      dueDate: now.add(const Duration(days: 14)),
      status: 'outstanding',
    ),
    _InvoiceSeed(
      client: 'Meridian Group',
      number: 'INV-2024-0410',
      amount: 240000,
      dueDate: now.subtract(const Duration(days: 22)),
      status: 'paid',
    ),
    _InvoiceSeed(
      client: 'Innovation Labs',
      number: 'INV-2024-0409',
      amount: 67500,
      dueDate: now.add(const Duration(days: 7)),
      status: 'outstanding',
    ),
    _InvoiceSeed(
      client: 'Hartwell Family Office',
      number: 'INV-2024-0408',
      amount: 330000,
      dueDate: now.subtract(const Duration(days: 45)),
      status: 'paid',
    ),
    _InvoiceSeed(
      client: 'Nexus Private Equity',
      number: 'INV-2024-0407',
      amount: 118750,
      dueDate: now.subtract(const Duration(days: 3)),
      status: 'overdue',
    ),
    _InvoiceSeed(
      client: 'Clearwater Ventures',
      number: 'INV-2024-0406',
      amount: 54200,
      dueDate: now.add(const Duration(days: 30)),
      status: 'outstanding',
    ),
    _InvoiceSeed(
      client: 'Crestwood Management',
      number: 'INV-2024-0405',
      amount: 198000,
      dueDate: now.subtract(const Duration(days: 60)),
      status: 'paid',
    ),
  ];
}

class _AccountSeed {
  final String name;
  final String bank;
  final String currency;
  final double balance;
  final double yield_;
  final String syncedAgo;
  const _AccountSeed({
    required this.name,
    required this.bank,
    required this.currency,
    required this.balance,
    required this.yield_,
    required this.syncedAgo,
  });
}

class _InvoiceSeed {
  final String client;
  final String number;
  final double amount;
  final DateTime dueDate;
  final String status;
  const _InvoiceSeed({
    required this.client,
    required this.number,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CashBody
// ─────────────────────────────────────────────────────────────────────────────

class CashBody extends ConsumerWidget {
  const CashBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_cashAccountsProvider);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildContent(context, []),
      data: (rows) => _buildContent(context, rows),
    );
  }

  Widget _buildContent(
      BuildContext context, List<Map<String, dynamic>> rows) {
    final seeds = rows.isEmpty ? _seedAccounts() : <_AccountSeed>[];
    final accounts = rows.isEmpty
        ? seeds
        : rows.map((r) {
            return _AccountSeed(
              name: (r['name'] ?? r['account_name'] ?? 'Account').toString(),
              bank: (r['bank'] ?? r['institution'] ?? 'Bank').toString(),
              currency: (r['currency'] ?? 'USD').toString(),
              balance:
                  double.tryParse((r['balance'] ?? 0).toString()) ?? 0,
              yield_:
                  double.tryParse((r['yield'] ?? r['yield_pct'] ?? 0).toString()) ??
                      0,
              syncedAgo:
                  'Synced ${timeAgo(r['updated_at'] as String?)}',
            );
          }).toList();

    final totalCash =
        accounts.fold<double>(0, (s, a) => s + a.balance);
    final weightedYield = accounts.isEmpty
        ? 0.0
        : accounts.fold<double>(
                0, (s, a) => s + a.yield_ * a.balance) /
            totalCash;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── Hero row: Total Cash + Yield ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: DarkCard(
                    gradient: AppColors.darkCardGradient,
                    radius: AppRadii.cardLarge,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL CASH',
                            style: AppText.eyebrow(AppColors.mutedOnDark)),
                        const SizedBox(height: 6),
                        Text(
                          formatCompactCurrency(totalCash),
                          style: AppText.serif(
                              size: 28, color: AppColors.goldOnDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                size: 12, color: AppColors.greenOnDark),
                            const SizedBox(width: 4),
                            Text('Across ${accounts.length} accounts',
                                style: AppText.sans(
                                    size: 11,
                                    color: AppColors.mutedOnDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AppCard(
                    radius: AppRadii.cardLarge,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('AVG YIELD',
                            style:
                                AppText.eyebrow(AppColors.mutedLight)),
                        const SizedBox(height: 6),
                        Text(
                          '${weightedYield.toStringAsFixed(2)}%',
                          style: AppText.serif(
                              size: 24, color: AppColors.goldText),
                        ),
                        const SizedBox(height: 4),
                        Text('Weighted avg',
                            style: AppText.sans(
                                size: 10.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Section header ─────────────────────────────────────────────
            SectionHead(
              'Accounts',
              serif: true,
              trailing: Text(
                'All currencies',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
            ),

            // ── Account list ───────────────────────────────────────────────
            AppCard(
              noPadding: true,
              radius: AppRadii.card,
              child: Column(
                children: [
                  for (int i = 0; i < accounts.length; i++)
                    _AccountRow(
                      account: accounts[i],
                      isLast: i == accounts.length - 1,
                    ),
                ],
              ),
            ),
          ],
        ),

        // ── FAB ─────────────────────────────────────────────────────────────
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(
            onTap: () {},
            icon: Icons.add,
          ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final _AccountSeed account;
  final bool isLast;
  const _AccountRow({required this.account, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final currencySymbol = account.currency == 'EUR' ? '€' : r'$';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          // Bank glyph tile
          GlyphTile(
            icon: Icons.account_balance,
            color: AppColors.goldText,
            bg: AppColors.gold500.withValues(alpha: 0.10),
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 13),

          // Name + bank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  account.bank,
                  style: AppText.sans(size: 11.5, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.greenOnDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      account.syncedAgo,
                      style:
                          AppText.sans(size: 10.5, color: AppColors.muted),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.hairlineSoft,
                        borderRadius:
                            BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        account.currency,
                        style: AppText.sans(
                            size: 9.5,
                            color: AppColors.mutedLight,
                            weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Balance + yield
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${_formatBalance(account.balance)}',
                style:
                    AppText.serif(size: 15, color: AppColors.goldText),
              ),
              const SizedBox(height: 3),
              Text(
                '${account.yield_.toStringAsFixed(2)}% yield',
                style: AppText.sans(size: 11, color: AppColors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBalance(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BillingBody
// ─────────────────────────────────────────────────────────────────────────────

class BillingBody extends ConsumerStatefulWidget {
  const BillingBody({super.key});

  @override
  ConsumerState<BillingBody> createState() => _BillingBodyState();
}

class _BillingBodyState extends ConsumerState<BillingBody> {
  String _filter = 'All';

  static const _filters = ['All', 'Outstanding', 'Paid', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_invoicesProvider);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => _buildContent([]),
      data: (rows) => _buildContent(rows),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> rows) {
    final invoices = rows.isEmpty
        ? _seedInvoices()
        : rows.map((r) {
            final dueDateRaw = r['due_date'] as String?;
            final dueDate = dueDateRaw != null
                ? (DateTime.tryParse(dueDateRaw) ?? DateTime.now())
                : DateTime.now();
            final status =
                (r['status'] ?? 'outstanding').toString().toLowerCase();
            return _InvoiceSeed(
              client:
                  (r['client_name'] ?? r['client'] ?? 'Client').toString(),
              number:
                  (r['invoice_number'] ?? r['number'] ?? 'INV-???').toString(),
              amount:
                  double.tryParse((r['amount'] ?? 0).toString()) ?? 0,
              dueDate: dueDate,
              status: status,
            );
          }).toList();

    // KPI aggregates
    final outstanding = invoices
        .where((i) => i.status == 'outstanding')
        .fold<double>(0, (s, i) => s + i.amount);
    final paid = invoices
        .where((i) => i.status == 'paid')
        .fold<double>(0, (s, i) => s + i.amount);
    final overdue = invoices
        .where((i) => i.status == 'overdue')
        .fold<double>(0, (s, i) => s + i.amount);

    // Filtered list
    final filtered = invoices.where((i) {
      if (_filter == 'All') return true;
      return i.status == _filter.toLowerCase();
    }).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // ── KPI row ────────────────────────────────────────────────────
            Row(
              children: [
                _KpiTile(
                  label: 'OUTSTANDING',
                  amount: outstanding,
                  color: AppColors.goldText,
                ),
                const SizedBox(width: 8),
                _KpiTile(
                  label: 'PAID MTD',
                  amount: paid,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                _KpiTile(
                  label: 'OVERDUE',
                  amount: overdue,
                  color: AppColors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Filter chips ───────────────────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final active = f == _filter;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: active
                            ? AppColors.goldGradient
                            : null,
                        color: active ? null : AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: active
                              ? Colors.transparent
                              : AppColors.hairline,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.gold500
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        f,
                        style: AppText.sans(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: active
                              ? AppColors.goldInk
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Invoice list ───────────────────────────────────────────────
            SectionHead(
              'Invoices',
              serif: true,
              trailing: Text(
                '${filtered.length} ${_filter == 'All' ? 'total' : _filter.toLowerCase()}',
                style: AppText.sans(size: 12, color: AppColors.muted),
              ),
            ),

            if (filtered.isEmpty)
              const EmptyStateView(
                  message: 'No invoices match this filter.',
                  icon: Icons.receipt_long_outlined)
            else
              AppCard(
                noPadding: true,
                radius: AppRadii.card,
                child: Column(
                  children: [
                    for (int i = 0; i < filtered.length; i++)
                      _InvoiceRow(
                        invoice: filtered[i],
                        isLast: i == filtered.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        ),

        // ── FAB ───────────────────────────────────────────────────────────
        Positioned(
          right: 20,
          bottom: 28,
          child: GoldFab(
            onTap: () {},
            icon: Icons.add,
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _KpiTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        radius: AppRadii.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.eyebrow(AppColors.mutedLight)),
            const SizedBox(height: 5),
            Text(
              formatCompactCurrency(amount),
              style: AppText.serif(size: 17, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final _InvoiceSeed invoice;
  final bool isLast;
  const _InvoiceRow({required this.invoice, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = invoice.status == 'overdue' ||
        (invoice.status != 'paid' && invoice.dueDate.isBefore(now));
    final dueDateStr =
        '${_monthAbbr(invoice.dueDate.month)} ${invoice.dueDate.day}, ${invoice.dueDate.year}';

    Color pillFg;
    Color pillBg;
    String pillLabel;
    switch (invoice.status) {
      case 'paid':
        pillFg = AppColors.green;
        pillBg = AppColors.green.withValues(alpha: 0.12);
        pillLabel = 'Paid';
      case 'overdue':
        pillFg = AppColors.red;
        pillBg = AppColors.red.withValues(alpha: 0.12);
        pillLabel = 'Overdue';
      default:
        pillFg = AppColors.goldTextSoft;
        pillBg = AppColors.gold500.withValues(alpha: 0.14);
        pillLabel = 'Outstanding';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          GlyphTile(
            icon: Icons.receipt_long_outlined,
            color: pillFg,
            bg: pillBg,
            size: 40,
            radius: 12,
          ),
          const SizedBox(width: 13),

          // Client + invoice number + due date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.client,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.sans(size: 13.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.number,
                  style:
                      AppText.sans(size: 11.5, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 10,
                      color: isOverdue
                          ? AppColors.red
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due $dueDateStr',
                      style: AppText.sans(
                        size: 10.5,
                        color: isOverdue
                            ? AppColors.red
                            : AppColors.muted,
                        weight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Amount + status pill
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCurrency(invoice.amount),
                style:
                    AppText.serif(size: 15, color: AppColors.goldText),
              ),
              const SizedBox(height: 5),
              StatusPill(
                label: pillLabel,
                color: pillFg,
                bg: pillBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthAbbr(int month) {
    const abbrs = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return abbrs[month - 1];
  }
}
