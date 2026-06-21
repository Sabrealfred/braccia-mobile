import 'package:flutter/material.dart';
import '_stub.dart';

class ChannelScreen extends StatelessWidget {
  final String channelId;
  const ChannelScreen({super.key, required this.channelId});
  @override
  Widget build(BuildContext context) =>
      StubScaffold(title: '#$channelId', icon: Icons.tag);
}
