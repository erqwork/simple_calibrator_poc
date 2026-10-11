import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_calibrator_poc/core/geometry/calibration.dart';
import 'package:simple_calibrator_poc/core/geometry/measurement.dart';
import 'package:simple_calibrator_poc/features/scanner/models/scan_observation.dart';
import 'package:simple_calibrator_poc/features/history/providers/history_provider.dart';
import 'package:simple_calibrator_poc/shared/widgets/pair_result.dart';

import 'support/memory_history_store.dart';

import 'package:simple_calibrator_poc/features/history/presentation/history_screen.dart';
import 'package:simple_calibrator_poc/features/history/models/measurement_group.dart';

MeasurementResult result(double deviation) {
  const config = CalibrationConfig();
  return MeasurementResult(
    observation: ScanObservation(
      timestamp: DateTime(2026, 10, 11),
      markers: [],
    ),
    config: config,
    pixelsPerMm: 2,
    distances: MeasurementPair.values.map(
      (p) => PairMeasurement(
        p,
        config.targetFor(p) + deviation,
        config.targetFor(p),
        config.allowedDeviationMm,
      ),
    ),
  );
}

void main() {
  testWidgets('history starts at 14 groups and adds another 14 on scroll', (
    tester,
  ) async {
    final store = MemoryHistoryStore();
    await store.save(
      List.generate(
        40,
        (i) => MeasurementGroup(
          id: '$i',
          startedAt: DateTime(2026, 10, 11, 0, i),
          dailyNumber: i + 1,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [historyStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    var list = tester.widget<ListView>(find.byType(ListView));
    expect(
      list.childrenDelegate.estimatedChildCount,
      15,
    ); // 14 groups plus fallback control.
    list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
    await tester.pumpAndSettle();
    list = tester.widget<ListView>(find.byType(ListView));
    expect(list.childrenDelegate.estimatedChildCount, 29);
  });
  test('deletion persists, protects captured groups, and retains entries on failure', () async {
    final store = MemoryHistoryStore();
    final container = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyProvider.notifier);
    final empty = await notifier.beginGroup(at: DateTime(2026, 10, 11, 9));
    final captured = await notifier.beginGroup(at: DateTime(2026, 10, 11, 10));
    await notifier.append(captured, result(0));
    await expectLater(notifier.deleteEmptyGroup(captured), throwsStateError);
    store.failWrites = true;
    await expectLater(notifier.deleteEmptyGroup(empty), throwsStateError);
    expect((await store.load()).length, 2);
    store.failWrites = false;
    await notifier.deleteEmptyGroup(empty);
    expect((await store.load()).single.id, captured);
  });
  for (final direction in [-1.0, 1.0]) {
    testWidgets('empty group can be swiped in direction $direction', (
      tester,
    ) async {
      final store = MemoryHistoryStore();
      final container = ProviderContainer(
        overrides: [historyStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(historyProvider.notifier).beginGroup();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsOneWidget);
      await tester.drag(find.byType(Dismissible), Offset(direction * 600, 0));
      await tester.pumpAndSettle();
      expect(find.byType(Dismissible), findsNothing);
      expect(await store.load(), isEmpty);
    });
  }
  test('history preserves empty visits, ordered captures, daily numbers and snapshots after reload', () async {
    final store = MemoryHistoryStore();
    final container = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyProvider.notifier);
    final empty = await notifier.beginGroup(at: DateTime(2026, 10, 11, 9));
    final group = await notifier.beginGroup(at: DateTime(2026, 10, 11, 10));
    await Future.wait([
      notifier.append(group, result(8)),
      notifier.append(group, result(-7)),
      notifier.append(group, result(5)),
    ]);
    await notifier.beginGroup(at: DateTime(2026, 10, 12));
    final reloaded = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(reloaded.dispose);
    final groups = await reloaded.read(historyProvider.future);
    expect(groups.first.id, empty);
    expect(groups.first.captures, isEmpty);
    expect(groups.map((g) => g.dailyNumber), [1, 2, 1]);
    expect(groups[1].captures.map((c) => c.distances.first.deviationMm), [
      8,
      -7,
      5,
    ]);
    expect(groups[1].adjustmentsToIdeal, 2);
    expect(groups[1].captures.first.config.alphaBetaTargetMm, 90);
    expect(groups[1].captures.first.config.allowedDeviationMm, 5);
    expect(groups.first.adjustmentsToIdeal, isNull);
  });

  test('failed save can be retried without duplicating a capture', () async {
    final store = MemoryHistoryStore();
    final container = ProviderContainer(
      overrides: [historyStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(historyProvider.notifier);
    final id = await notifier.beginGroup();
    store.failWrites = true;
    await expectLater(notifier.append(id, result(0)), throwsStateError);
    expect(
      (await container.read(historyProvider.future)).single.captures,
      isEmpty,
    );
    store.failWrites = false;
    await notifier.append(id, result(0));
    expect(
      (await container.read(historyProvider.future)).single.adjustmentsToIdeal,
      0,
    );
  });

  test('five mm tolerance is inclusive and shortages are blue', () {
    expect(const CalibrationConfig().allowedDeviationMm, 5);
    expect(
      resultColor(const PairMeasurement(MeasurementPair.alphaBeta, 96, 90, 5)),
      Colors.red,
    );
    expect(
      resultColor(const PairMeasurement(MeasurementPair.alphaBeta, 84, 90, 5)),
      Colors.blue,
    );
    expect(
      resultColor(const PairMeasurement(MeasurementPair.alphaBeta, 95, 90, 5)),
      Colors.green,
    );
    expect(
      resultColor(const PairMeasurement(MeasurementPair.alphaBeta, 85, 90, 5)),
      Colors.green,
    );
  });
}
