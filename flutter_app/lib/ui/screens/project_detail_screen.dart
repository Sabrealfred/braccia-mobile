import 'package:flutter/material.dart';
import '_stub.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  Widget build(BuildContext context) =>
      const StubScaffold(title: 'Project', icon: Icons.view_kanban);
}
