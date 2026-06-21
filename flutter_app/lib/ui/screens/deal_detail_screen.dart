import 'package:flutter/material.dart';
import '_stub.dart';

class DealDetailScreen extends StatelessWidget {
  final String dealId;
  const DealDetailScreen({super.key, required this.dealId});
  @override
  Widget build(BuildContext context) =>
      const StubScaffold(title: 'Deal', icon: Icons.handshake);
}
