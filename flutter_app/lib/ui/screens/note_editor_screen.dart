import 'package:flutter/material.dart';
import '_stub.dart';

class NoteEditorScreen extends StatelessWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});
  @override
  Widget build(BuildContext context) =>
      const StubScaffold(title: 'Note', icon: Icons.edit_note);
}
