import 'package:flutter/material.dart';
import '_stub.dart';

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) =>
      const StubScaffold(title: 'Client', icon: Icons.account_circle);
}
