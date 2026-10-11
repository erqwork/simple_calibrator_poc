// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simple_calibrator_poc/app/app.dart';
import 'package:simple_calibrator_poc/features/history/providers/history_provider.dart';

import 'support/memory_history_store.dart';

void main() {
  testWidgets('Scanner initially waits for user to start camera', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStoreProvider.overrideWithValue(MemoryHistoryStore()),
        ],
        child: const CalibrationApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Simple Calibrator'), findsOneWidget);
    await tester.tap(find.text('Scanner'));
    await tester.pumpAndSettle();
    expect(find.text('0/6 markers in latest detection'), findsOneWidget);
    expect(find.byTooltip('Start camera'), findsOneWidget);
  });
  testWidgets('scanner visits without starting camera create no history', (
    tester,
  ) async {
    final store = MemoryHistoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [historyStoreProvider.overrideWithValue(store)],
        child: const CalibrationApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect((await store.load()), isEmpty);
    await tester.tap(find.text('Scanner'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.text('No scanner visits yet.'), findsOneWidget);
    await tester.tap(find.byTooltip('New measurement group'));
    await tester.pumpAndSettle();
    expect(await store.load(), isEmpty);
    await tester.tap(find.byTooltip('Start camera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect((await store.load()).length, 1);
    expect((await store.load()).single.captures, isEmpty);
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.text('No successful measurements'), findsOneWidget);
  });
}
