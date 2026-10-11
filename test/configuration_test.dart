import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_calibrator_poc/app/app.dart';
import 'package:simple_calibrator_poc/core/geometry/calibration.dart';
import 'package:simple_calibrator_poc/features/configuration/providers/configuration_provider.dart';

class MemoryConfigurationStore extends ConfigurationStore {
  CalibrationConfig saved = const CalibrationConfig();
  bool failWrites = false;
  @override
  Future<CalibrationConfig> load() async => saved;
  @override
  Future<void> save(CalibrationConfig config) async {
    if (failWrites) throw StateError('Storage unavailable');
    saved = config;
  }
}

void main() {
  test(
    'new targets are saved before replacing current configuration',
    () async {
      final store = MemoryConfigurationStore();
      final container = ProviderContainer(
        overrides: [configurationStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(calibrationConfigProvider.notifier);
      await notifier.setTargets(
        alphaBetaMm: 100,
        betaGammaMm: 80,
        alphaGammaMm: 90,
      );
      expect((await store.load()).alphaBetaTargetMm, 100);
      expect(container.read(calibrationConfigProvider).allowedDeviationMm, 5);
      store.failWrites = true;
      await expectLater(
        notifier.setTargets(
          alphaBetaMm: 110,
          betaGammaMm: 80,
          alphaGammaMm: 90,
        ),
        throwsStateError,
      );
      expect(container.read(calibrationConfigProvider).alphaBetaTargetMm, 100);
      await expectLater(
        notifier.setTargets(
          alphaBetaMm: double.nan,
          betaGammaMm: 80,
          alphaGammaMm: 90,
        ),
        throwsArgumentError,
      );
    },
  );
  testWidgets('configuration rejects invalid input and updates home targets', (
    tester,
  ) async {
    final store = MemoryConfigurationStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [configurationStoreProvider.overrideWithValue(store)],
        child: const CalibrationApp(),
      ),
    );
    await tester.scrollUntilVisible(find.text('Configuration'), 200);
    await tester.tap(find.text('Configuration'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.ensureVisible(find.text('Save targets'));
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive distance in mm'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.ensureVisible(find.text('Save targets'));
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    expect(find.text('Simple Calibrator'), findsOneWidget);
    expect(store.saved.alphaBetaTargetMm, 100);
    await tester.scrollUntilVisible(find.textContaining('Targets: 100.0'), 200);
    expect(find.textContaining('Targets: 100.0'), findsOneWidget);
  });
}
