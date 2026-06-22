import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braccia_mobile/core/modules.dart';
import 'package:braccia_mobile/core/theme.dart';
import 'package:braccia_mobile/models/models.dart';
import 'package:braccia_mobile/providers/providers.dart';
import 'package:braccia_mobile/ui/screens/home_screen.dart';
import 'package:braccia_mobile/ui/widgets/app_widgets.dart';

void main() {
  testWidgets('widget kit renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              const AppCard(child: Text('Card')),
              GoldButton(label: 'Go', onTap: () {}),
              StatusPill.forStatus('active'),
              const BarSparkline(values: [0.2, 0.5, 0.8]),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('Home renders with mocked data (no layout asserts)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            (ref) async => UserProfile(
                id: '1', email: 'alex@braccia.com', fullName: 'Alex Marsh'),
          ),
          dealsStatsProvider.overrideWith(
            (ref) async => (activeCount: 17, pipelineValue: 121300000.0),
          ),
          openLeadsProvider.overrideWith((ref) async => 34),
          dealsProvider.overrideWith((ref) async => <Deal>[]),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    // Let the FutureProviders resolve.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Alex Marsh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('module catalog is well-formed', () {
    expect(kModules, isNotEmpty);
    expect(moduleById('leads'), isNotNull);
    expect(moduleById('does-not-exist'), isNull);
    // every group has at least one module
    for (final g in ModuleGroup.values) {
      expect(modulesIn(g), isNotEmpty, reason: 'group $g should have modules');
    }
  });
}
