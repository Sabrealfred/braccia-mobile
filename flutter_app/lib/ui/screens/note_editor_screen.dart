import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import 'notes_data.dart';

/// Notion-feel note editor — minimal chrome, large serif title, growing body,
/// metadata row, debounced autosave to Supabase (optimistic local fallback).
class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _bodyCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  Timer? _debounce;
  bool _isDirty = false;
  bool _saving = false;

  // Local snapshot of the note being edited
  NoteEntry? _local;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final notifier = ref.read(notesProvider.notifier);
    NoteEntry? found = notifier.byId(widget.noteId);
    if (found == null) {
      // Brand-new id not yet in store — treat as blank
      final now = DateTime.now();
      found = NoteEntry(
        id: widget.noteId,
        text: '',
        status: 'in_progress',
        updatedAt: now,
        createdAt: now,
      );
      notifier.upsert(found);
    }
    setState(() {
      _local = found;
      _bodyCtrl.text = found!.text;
    });
    // Cursor to end of text
    _bodyCtrl.selection = TextSelection.collapsed(offset: _bodyCtrl.text.length);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  // Called on every text change; debounced 800 ms.
  void _onTextChanged(String value) {
    setState(() => _isDirty = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => _save(value));
  }

  Future<void> _save(String text) async {
    if (_local == null) return;
    setState(() => _saving = true);
    final updated = _local!.copyWith(
      text: text,
      updatedAt: DateTime.now(),
    );
    _local = updated;
    await ref.read(notesProvider.notifier).upsert(updated);
    if (mounted) setState(() {_saving = false; _isDirty = false;});
  }

  Future<void> _saveAndPop() async {
    _debounce?.cancel();
    if (_isDirty && _local != null) {
      await _save(_bodyCtrl.text);
    }
    if (mounted) context.pop();
  }

  void _cycleStatus() {
    if (_local == null) return;
    const statuses = ['in_progress', 'pending', 'review', 'active', 'archived'];
    final cur = _local!.status ?? 'in_progress';
    final idx = statuses.indexOf(cur);
    final next = statuses[(idx + 1) % statuses.length];
    final updated = _local!.copyWith(status: next, updatedAt: DateTime.now());
    setState(() => _local = updated);
    ref.read(notesProvider.notifier).upsert(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Keep _local in sync with external changes only when we haven't typed
    if (!_isDirty) {
      final external = ref.watch(notesProvider).asData?.value
          .where((n) => n.id == widget.noteId)
          .firstOrNull;
      if (external != null && _local == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _local = external;
              _bodyCtrl.text = external.text;
            });
          }
        });
      }
    }

    final note = _local;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Dark top bar (back + title + save indicator)
          _EditorHeader(
            topPad: topPad,
            saving: _saving,
            isDirty: _isDirty,
            onBack: _saveAndPop,
          ),

          // Metadata row (status chip + updated date)
          if (note != null)
            _MetadataRow(
              note: note,
              onStatusTap: _cycleStatus,
            ),

          // Scrollable editing area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Body — single growing TextField (Notion-style: no title/body split,
                  // first line is the title, rest is body)
                  TextField(
                    controller: _bodyCtrl,
                    focusNode: _bodyFocus,
                    onChanged: _onTextChanged,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.sans(
                      size: 15.5,
                      color: AppColors.ink,
                      height: 1.65,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Start writing…',
                      hintStyle: AppText.sans(
                          size: 15.5,
                          color: AppColors.muted.withValues(alpha: 0.5),
                          height: 1.65),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: AppColors.gold500,
                    cursorWidth: 1.8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Editor header ─────────────────────────────────────────────────────────────

class _EditorHeader extends StatelessWidget {
  final double topPad;
  final bool saving;
  final bool isDirty;
  final VoidCallback onBack;

  const _EditorHeader({
    required this.topPad,
    required this.saving,
    required this.isDirty,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.onyx700,
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
      child: Row(
        children: [
          // Back chevron (saves + pops)
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_left,
                      color: AppColors.goldOnDark, size: 18),
                  Text('Notes',
                      style:
                          AppText.sans(size: 13, color: AppColors.goldOnDark)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Save state indicator
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: saving
                ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.goldOnDark),
                    ),
                  )
                : isDirty
                    ? Text('Unsaved',
                        key: const ValueKey('unsaved'),
                        style: AppText.sans(
                            size: 11, color: AppColors.mutedOnDark))
                    : Row(
                        key: const ValueKey('saved'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 13, color: AppColors.greenOnDark),
                          const SizedBox(width: 4),
                          Text('Saved',
                              style: AppText.sans(
                                  size: 11, color: AppColors.mutedOnDark)),
                        ],
                      ),
          ),

          const SizedBox(width: 12),

          // Menu / more options placeholder
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: const Icon(Icons.more_horiz,
                size: 16, color: AppColors.mutedOnDark),
          ),
        ],
      ),
    );
  }
}

// ── Metadata row ─────────────────────────────────────────────────────────────

class _MetadataRow extends StatelessWidget {
  final NoteEntry note;
  final VoidCallback onStatusTap;

  const _MetadataRow({required this.note, required this.onStatusTap});

  @override
  Widget build(BuildContext context) {
    final status = note.status ?? 'in_progress';
    final dateStr = formatDate(note.updatedAt.toIso8601String());
    final agoStr = timeAgo(note.updatedAt.toIso8601String());

    return Container(
      color: AppColors.onyx700,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            // Status chip (tappable to cycle)
            GestureDetector(
              onTap: onStatusTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusDot(status),
                  const SizedBox(width: 5),
                  Text(
                    _statusLabel(status),
                    style: AppText.sans(
                        size: 11.5,
                        color: _statusColor(status),
                        weight: FontWeight.w600),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.unfold_more_rounded,
                      size: 12, color: _statusColor(status).withValues(alpha: 0.6)),
                ],
              ),
            ),

            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white.withValues(alpha: 0.12),
            ),

            // Date
            const Icon(Icons.schedule_rounded,
                size: 12, color: AppColors.mutedOnDark),
            const SizedBox(width: 4),
            Text(
              '$agoStr · $dateStr',
              style: AppText.sans(size: 11, color: AppColors.mutedOnDark),
            ),

            const Spacer(),

            // Note type icon
            const Icon(Icons.sticky_note_2_outlined,
                size: 13, color: AppColors.mutedOnDark),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(String status) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: _statusColor(status),
          shape: BoxShape.circle,
        ),
      );

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':
      case 'done':
      case 'completed':
        return AppColors.greenOnDark;
      case 'in_progress':
      case 'pending':
        return AppColors.goldOnDark;
      case 'review':
      case 'blocked':
        return AppColors.redOnDark;
      case 'archived':
        return AppColors.mutedOnDark;
      default:
        return AppColors.blueOnDark;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'in_progress':
        return 'In progress';
      case 'active':
        return 'Active';
      case 'done':
      case 'completed':
        return 'Done';
      case 'pending':
        return 'Pending';
      case 'review':
        return 'Review';
      case 'blocked':
        return 'Blocked';
      case 'archived':
        return 'Archived';
      default:
        return s;
    }
  }
}
