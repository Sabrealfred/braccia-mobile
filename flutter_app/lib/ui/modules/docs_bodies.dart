import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../widgets/app_widgets.dart';

// ---------------------------------------------------------------------------
// Local providers
// ---------------------------------------------------------------------------

final _docsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return repository.fetchTable('documents', orderBy: 'updated_at');
});

// ---------------------------------------------------------------------------
// Seed data
// ---------------------------------------------------------------------------

const _seedDocs = [
  _DocSeed(
    title: 'Apollo Engagement Letter',
    type: 'PDF',
    size: '248 KB',
    status: 'signed',
    ago: '2d ago',
    category: 'Contracts',
  ),
  _DocSeed(
    title: 'Atlas KYC Pack',
    type: 'PDF',
    size: '1.4 MB',
    status: 'draft',
    ago: '5d ago',
    category: 'Memos',
  ),
  _DocSeed(
    title: 'Q3 Board Pack',
    type: 'XLSX',
    size: '3.2 MB',
    status: 'draft',
    ago: '1w ago',
    category: 'Memos',
  ),
  _DocSeed(
    title: 'Meridian NDA — 2024',
    type: 'PDF',
    size: '88 KB',
    status: 'signed',
    ago: '2w ago',
    category: 'Contracts',
  ),
  _DocSeed(
    title: 'Fund II LP Agreement',
    type: 'DOC',
    size: '512 KB',
    status: 'signed',
    ago: '1mo ago',
    category: 'Contracts',
  ),
  _DocSeed(
    title: 'Q2 Investor Letter',
    type: 'PDF',
    size: '780 KB',
    status: 'signed',
    ago: '3mo ago',
    category: 'Memos',
  ),
];

class _DocSeed {
  final String title;
  final String type;
  final String size;
  final String status;
  final String ago;
  final String category;

  const _DocSeed({
    required this.title,
    required this.type,
    required this.size,
    required this.status,
    required this.ago,
    required this.category,
  });
}

// ---------------------------------------------------------------------------
// DocsBody — Document library
// ---------------------------------------------------------------------------

class DocsBody extends ConsumerStatefulWidget {
  const DocsBody({super.key});

  @override
  ConsumerState<DocsBody> createState() => _DocsBodyState();
}

class _DocsBodyState extends ConsumerState<DocsBody> {
  String _filter = 'All';
  String _q = '';

  static const _filters = ['All', 'Contracts', 'Memos', 'Signed'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_docsProvider);

    return Stack(
      children: [
        async.when(
          loading: () => const Center(child: LoadingState()),
          error: (err, _) => _buildContent([]),
          data: (rows) => _buildContent(rows),
        ),
        Positioned(
          right: 20,
          bottom: 110,
          child: GoldFab(
            icon: Icons.upload_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                _snack('Upload document — coming soon'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> rows) {
    // Merge live rows with seed — seed is shown if rows is empty.
    final List<_DocItem> items = rows.isNotEmpty
        ? rows.map(_fromRow).toList()
        : _seedDocs.map(_fromSeed).toList();

    final filtered = items.where((d) {
      if (_filter == 'Signed' && d.status != 'signed') return false;
      if (_filter != 'All' && _filter != 'Signed' &&
          !d.category.toLowerCase().contains(_filter.toLowerCase())) {
        return false;
      }
      if (_q.isNotEmpty &&
          !d.title.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // Search
        _SearchBar(
          hint: 'Search documents…',
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 12),

        // Filter chips
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (context, i) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = _filter == _filters[i];
              return _FilterChip(
                label: _filters[i],
                active: active,
                onTap: () => setState(() => _filter = _filters[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        SectionHead('Library', serif: true),

        if (filtered.isEmpty)
          const EmptyStateView(
            message: 'No documents match your filter.',
            icon: Icons.folder_off_outlined,
          )
        else
          AppCard(
            noPadding: true,
            radius: AppRadii.card,
            child: Column(
              children: [
                for (int i = 0; i < filtered.length; i++)
                  _DocRow(
                    doc: filtered[i],
                    last: i == filtered.length - 1,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      _snack('Opening ${filtered[i].title}…'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DocsAiBody — Documents AI / Doc Wizard
// ---------------------------------------------------------------------------

class DocsAiBody extends ConsumerWidget {
  const DocsAiBody({super.key});

  static const _templates = [
    'Term Sheet',
    'Engagement Letter',
    'NDA',
    'LOI',
  ];

  static const _extractedFields = [
    ('Counterparty', 'Apollo Global Management'),
    ('Amount', '\$85,000,000'),
    ('Effective date', 'Sep 1, 2024'),
    ('Term', '24 months'),
  ];

  static const _recentActions = [
    _AiAction(label: 'Summarize KYC', doc: 'Atlas KYC Pack', ago: '12m ago'),
    _AiAction(label: 'Draft LOI email', doc: 'Meridian NDA', ago: '3h ago'),
    _AiAction(
        label: 'Extract terms',
        doc: 'Apollo Engagement Letter',
        ago: 'yesterday'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            // Hero drop zone
            _DropZoneCard(
              onScan: () => ScaffoldMessenger.of(context).showSnackBar(
                _snack('Document scanner opening…'),
              ),
            ),
            const SizedBox(height: 20),

            // Template picker
            SectionHead('Pick a template', serif: true),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TemplateChip(
                  label: _templates[i],
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    _snack('Starting ${_templates[i]} template…'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Extracted fields demo card
            SectionHead('Extracted fields', serif: true),
            AppCard(
              radius: AppRadii.card,
              padding: const EdgeInsets.all(0),
              noPadding: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        GlyphTile(
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.goldText,
                          bg: AppColors.gold500.withValues(alpha: 0.12),
                          size: 34,
                          radius: 10,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apollo Engagement Letter',
                                style: AppText.sans(
                                    size: 13.5, weight: FontWeight.w600),
                              ),
                              Text(
                                'AI parsed · 2d ago',
                                style: AppText.sans(
                                    size: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          label: 'Parsed',
                          color: AppColors.green,
                          bg: AppColors.green.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1, thickness: 1, color: AppColors.hairlineSoft),
                  for (int i = 0; i < _extractedFields.length; i++)
                    _FieldRow(
                      label: _extractedFields[i].$1,
                      value: _extractedFields[i].$2,
                      last: i == _extractedFields.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recent AI actions
            SectionHead('Recent AI actions', serif: true),
            AppCard(
              noPadding: true,
              radius: AppRadii.card,
              child: Column(
                children: [
                  for (int i = 0; i < _recentActions.length; i++)
                    _AiActionRow(
                      action: _recentActions[i],
                      last: i == _recentActions.length - 1,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        _snack('${_recentActions[i].label} — viewing…'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        // FAB — scan / upload
        Positioned(
          right: 20,
          bottom: 110,
          child: GoldFab(
            icon: Icons.document_scanner_rounded,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              _snack('Document scanner opening…'),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers — DocsBody
// ---------------------------------------------------------------------------

class _DocItem {
  final String title;
  final String type;
  final String size;
  final String status;
  final String ago;
  final String category;

  const _DocItem({
    required this.title,
    required this.type,
    required this.size,
    required this.status,
    required this.ago,
    required this.category,
  });
}

_DocItem _fromSeed(_DocSeed s) => _DocItem(
      title: s.title,
      type: s.type,
      size: s.size,
      status: s.status,
      ago: s.ago,
      category: s.category,
    );

_DocItem _fromRow(Map<String, dynamic> r) {
  final name = (r['name'] ?? r['title'] ?? r['file_name'] ?? 'Document').toString();
  final type = (r['file_type'] ?? r['type'] ?? 'PDF').toString().toUpperCase();
  final size = (r['size'] ?? r['file_size'] ?? '—').toString();
  final status = (r['status'] ?? 'draft').toString();
  final cat = (r['category'] ?? 'Memos').toString();
  final ago = timeAgo(r['updated_at'] as String? ?? r['created_at'] as String?);
  return _DocItem(
    title: name,
    type: type,
    size: size,
    status: status,
    ago: ago.isEmpty ? '—' : ago,
    category: cat,
  );
}

IconData _iconForType(String type) {
  switch (type.toUpperCase()) {
    case 'XLSX':
    case 'XLS':
    case 'CSV':
      return Icons.table_chart_outlined;
    case 'DOC':
    case 'DOCX':
      return Icons.description_outlined;
    default:
      return Icons.picture_as_pdf_outlined;
  }
}

Color _colorForType(String type) {
  switch (type.toUpperCase()) {
    case 'XLSX':
    case 'XLS':
    case 'CSV':
      return AppColors.green;
    case 'DOC':
    case 'DOCX':
      return AppColors.blue;
    default:
      return AppColors.red;
  }
}

Color _bgForType(String type) {
  switch (type.toUpperCase()) {
    case 'XLSX':
    case 'XLS':
    case 'CSV':
      return AppColors.green.withValues(alpha: 0.10);
    case 'DOC':
    case 'DOCX':
      return AppColors.blue.withValues(alpha: 0.10);
    default:
      return AppColors.red.withValues(alpha: 0.10);
  }
}

class _DocRow extends StatelessWidget {
  final _DocItem doc;
  final bool last;
  final VoidCallback? onTap;

  const _DocRow({required this.doc, required this.last, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.hairlineSoft)),
        ),
        child: Row(
          children: [
            GlyphTile(
              icon: _iconForType(doc.type),
              color: _colorForType(doc.type),
              bg: _bgForType(doc.type),
              size: 40,
              radius: 12,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.sans(size: 13.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.type} · ${doc.ago}  ·  ${doc.size}',
                    style: AppText.sans(size: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StatusPill.forStatus(doc.status),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: active ? AppColors.goldGradient : null,
          color: active ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: active
                ? Colors.transparent
                : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 12.5,
            weight: FontWeight.w600,
            color: active ? AppColors.goldInk : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers — DocsAiBody
// ---------------------------------------------------------------------------

class _AiAction {
  final String label;
  final String doc;
  final String ago;

  const _AiAction({required this.label, required this.doc, required this.ago});
}

class _DropZoneCard extends StatelessWidget {
  final VoidCallback onScan;

  const _DropZoneCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        border: Border.all(
          color: AppColors.gold500.withValues(alpha: 0.35),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold500.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.cardLarge),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.gold500.withValues(alpha: 0.30),
            radius: AppRadii.cardLarge,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold500.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.goldInk,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Drop or scan a document',
                  style: AppText.serif(size: 20, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan / upload · send for signature',
                  style: AppText.sans(size: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                GoldButton(
                  label: 'Scan or Upload',
                  icon: Icons.upload_rounded,
                  onTap: onScan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed border using canvas — no external deps.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);
    const dashLen = 6.0;
    const gapLen = 5.0;

    final pathMetrics = path.computeMetrics().toList();
    for (final metric in pathMetrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TemplateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.onyx700,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: AppText.sans(
            size: 12.5,
            weight: FontWeight.w600,
            color: AppColors.goldOnDark,
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _FieldRow({required this.label, required this.value, required this.last});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppText.sans(size: 12, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppText.sans(size: 13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiActionRow extends StatelessWidget {
  final _AiAction action;
  final bool last;
  final VoidCallback onTap;

  const _AiActionRow({
    required this.action,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.hairlineSoft)),
        ),
        child: Row(
          children: [
            GlyphTile(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.goldText,
              bg: AppColors.gold500.withValues(alpha: 0.10),
              size: 40,
              radius: 12,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: AppText.sans(size: 13.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.doc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(size: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Text(
              action.ago,
              style: AppText.sans(size: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared utility
// ---------------------------------------------------------------------------

SnackBar _snack(String msg) => SnackBar(
      content: Text(msg, style: AppText.sans(size: 13, color: Colors.white)),
      backgroundColor: AppColors.onyx700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.inner)),
      duration: const Duration(seconds: 2),
    );
