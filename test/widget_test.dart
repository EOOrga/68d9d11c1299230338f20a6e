import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trouve_marin_michel/main.dart';

void main() {
  testWidgets('shows the main operations sections', (tester) async {
    await tester.pumpWidget(
      TrouveMarinMichelApp(store: MemoryOperationsStore.seeded()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations command center'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('Task management'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-resources')));
    await tester.pumpAndSettle();
    expect(find.text('Resource allocation'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Supply ordering'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-audit')));
    await tester.pumpAndSettle();
    expect(find.text('Audit logs'), findsOneWidget);
  });

  testWidgets('creates a local task record', (tester) async {
    await tester.pumpWidget(
      TrouveMarinMichelApp(store: MemoryOperationsStore.seeded()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-tasks')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add task'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Prepare delivery audit',
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-owner-field')),
      'Mina',
    );
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare delivery audit'), findsOneWidget);
    expect(find.text('Mina'), findsWidgets);
  });
}
