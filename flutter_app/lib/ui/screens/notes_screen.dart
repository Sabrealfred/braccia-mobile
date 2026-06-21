import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';
import 'notes_data.dart';

/// Notion-grade notes list — masonry-ish 2-col grid with live search.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          DarkHeader(
            title: 'Notes',
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
            actions: [
              GestureDetector(
                onTap: () => ref.read(notesProvider.notifier).refresh(),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.goldOnDark),
                ),
              ),
            ],
            bottom: DarkSearchField(
              hint: 'Search notes…',
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: notesAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorStateView(
                error: e,
                onRetry: () => ref.read(notesProvider.notifier).refresh(),
              ),
              data: (notes) {
                final filtered = _query.isEmpty
                    ? notes
                    : notes
                        .where((n) =>
                            n.text.toLowerCase().contains(_query) ||
                            (n.status ?? '').toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return _query.isEmpty
                      ? const EmptyStateView(
                          message:
                              'No notes yet.\nTap + to create your first note.',
                          icon: Icons.sticky_note_2_outlined,
                        )
                      : const EmptyStateView(
                          message: 'No notes match your search.',
                          icon: Icons.search_off,
                        );
                }

                return RefreshIndicator(
                  color: AppColors.gold500,
                  onRefresh: () => ref.read(notesProvider.notifier).refresh(),
                  child: _MasonryNoteGrid(notes: filtered),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GoldFab(
          onTap: () {
            final note = ref.read(notesProvider.notifier).createBlank();
            context.push('/notes/${note.id}');
          },
        ),
      ),
    );
  }
}

// ── Masonry-ish 2-col grid ────────────────────────────────────────────────────

class _MasonryNoteGrid extends StatelessWidget {
  final List<NoteEntry> notes;
  const _MasonryNoteGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    final left = <NoteEntry>[];
    final right = <NoteEntry>[];
    for (int i = 0; i < notes.length; i++) {
      if (i.isEven) {
        left.add(notes[i]);
      } else {
        right.add(notes[i]);
      }
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: left
                    .map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NoteCard(note: n),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: right
                    .map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NoteCard(note: n),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Individual note card ──────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final NoteEntry note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final snippet = note.snippet;
    final status = note.status;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/notes/${note.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (serif, first line)
          Text(
            note.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.serif(size: 15, color: AppColors.ink, height: 1.25),
          ),

          // Snippet (body text, shown only when present)
          if (snippet.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              snippet,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 12, color: AppColors.muted, height: 1.5),
            ),
          ],

          const SizedBox(height: 10),

          // Footer: time-ago + status pill
          Row(
            children: [
              Text(
                timeAgo(note.updatedAt.toIso8601String()),
                style: AppText.sans(size: 10.5, color: AppColors.mutedLight),
              ),
              const Spacer(),
              if (status != null && status.isNotEmpty)
                _StatusBubble(status: status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  final String status;
  const _StatusBubble({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (status.toLowerCase()) {
      case 'active':
      case 'done':
      case 'completed':
        bg = AppColors.green.withValues(alpha: 0.12);
        fg = AppColors.green;
      case 'in_progress':
      case 'pending':
        bg = AppColors.gold500.withValues(alpha: 0.14);
        fg = AppColors.goldTextSoft;
      case 'review':
      case 'blocked':
        bg = AppColors.red.withValues(alpha: 0.12);
        fg = AppColors.red;
      case 'archived':
        bg = AppColors.hairlineSoft;
        fg = AppColors.muted;
      default:
        bg = AppColors.blue.withValues(alpha: 0.12);
        fg = AppColors.blue;
    }

    final String label;
    switch (status.toLowerCase()) {
      case 'in_progress':
        label = 'In progress';
      case 'active':
        label = 'Active';
      case 'done':
      case 'completed':
        label = 'Done';
      case 'pending':
        label = 'Pending';
      case 'review':
        label = 'Review';
      case 'blocked':
        label = 'Blocked';
      case 'archived':
        label = 'Archived';
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppText.sans(
            size: 9.5, color: fg, weight: FontWeight.w600, height: 1.2),
      ),
    );
  }
}
