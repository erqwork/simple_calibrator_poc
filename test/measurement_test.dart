import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_calibrator_poc/core/geometry/calibration.dart';
import 'package:simple_calibrator_poc/core/geometry/measurement.dart';
import 'package:simple_calibrator_poc/core/geometry/stability_tracker.dart';
import 'package:simple_calibrator_poc/features/scanner/models/scan_observation.dart';
import 'package:simple_calibrator_poc/features/scanner/providers/scanner_provider.dart';

ScanObservation sample({int ms = 0, double betaX = 30, double gammaScale = 2}) {
  final centers = {
    'alpha': const Point(0.0, 0.0),
    'beta': Point(betaX, 0.0),
    'gamma': Point(22.0, sqrt(960)),
  };
  final markers = <MarkerDetection>[];
  for (final entry in centers.entries) {
    final separation = entry.key == 'gamma' ? gammaScale : 2.0;
    for (var n = 1; n <= 2; n++) {
      final x = entry.value.x * 2 + (n == 1 ? -20 : 20) * separation;
      final y = entry.value.y * 2;
      markers.add(
        MarkerDetection('${entry.key}:$n', [
          Point(x - 1, y - 1),
          Point(x + 1, y - 1),
          Point(x + 1, y + 1),
          Point(x - 1, y + 1),
        ]),
      );
    }
  }
  return ScanObservation(
    timestamp: DateTime(2026, 10, 11).add(Duration(milliseconds: ms)),
    markers: markers,
  );
}

void main() {
  const config = CalibrationConfig();
  test('default targets are 90/70/72 mm', () {
    expect(MeasurementPair.values.map(config.targetFor), [90, 70, 72]);
  });
  test(
    'invalid corners name the affected group even in an incomplete frame',
    () {
      final scan = ScanObservation(
        timestamp: DateTime.now(),
        markers: [MarkerDetection('alpha:1', [])],
      );
      expect(measure(scan, config).issue, contains('Alpha is obstructed'));
    },
  );
  test(
    'known geometry produces target triangle and explicit config snapshots',
    () {
      const config = CalibrationConfig(
        alphaBetaTargetMm: 30,
        betaGammaTargetMm: 32,
        alphaGammaTargetMm: 38,
      );
      final scan = sample();
      final result = measure(scan, config).result!;
      expect(result.pixelsPerMm, 2);
      for (var i = 0; i < 3; i++) {
        expect(result.distances[i].measuredMm, closeTo([30, 32, 38][i], 1e-9));
        expect(result.distances[i].deviationMm, closeTo(0, 1e-9));
        expect(result.distances[i].withinTolerance, isTrue);
      }
      final changed = config.withTargets(alphaBetaMm: 26, betaGammaMm: 38);
      final other = measure(scan, changed).result!;
      expect(other.distances[0].deviationMm, closeTo(4, 1e-9));
      expect(other.distances[1].deviationMm, closeTo(-6, 1e-9));
      expect(result.config.alphaBetaTargetMm, 30);
      expect(() => result.distances.clear(), throwsUnsupportedError);
      expect(scan.markers.length, 6);
    },
  );
  test('inclusive tolerance boundaries and warning values', () {
    for (final value in [28.0, 30.0, 32.0]) {
      expect(
        PairMeasurement(
          MeasurementPair.alphaBeta,
          value,
          30,
          2,
        ).withinTolerance,
        isTrue,
      );
    }
    for (final value in [27.99, 32.01]) {
      expect(
        PairMeasurement(
          MeasurementPair.alphaBeta,
          value,
          30,
          2,
        ).withinTolerance,
        isFalse,
      );
    }
  });
  test(
    'incomplete, degenerate, nonfinite and inconsistent geometry rejected',
    () {
      final scan = sample();
      expect(
        measure(
          ScanObservation(
            timestamp: scan.timestamp,
            markers: scan.markers.take(5),
          ),
          config,
        ).result,
        isNull,
      );
      for (final corners in [
        List.filled(4, const Point(0.0, 0.0)),
        List.filled(4, const Point(double.nan, 0.0)),
      ]) {
        final bad = ScanObservation(
          timestamp: scan.timestamp,
          markers: [
            MarkerDetection('alpha:1', corners),
            ...scan.markers.skip(1),
          ],
        );
        expect(measure(bad, config).result, isNull);
      }
      expect(measure(sample(gammaScale: 3), config).result, isNull);
      expect(
        measure(scan, const CalibrationConfig(markerSeparationMm: 0)).result,
        isNull,
      );
      expect(
        measure(
          scan,
          const CalibrationConfig(markerSeparationMm: 80),
        ).result!.distances[0].measuredMm,
        60,
      );
    },
  );
  test(
    'stability requires full window and resets on gaps or cumulative drift',
    () {
      final tracker = StabilityTracker();
      for (var ms = 0; ms <= 1500; ms += 250) {
        final progress = tracker.add(measure(sample(ms: ms), config).result!);
        expect(progress, closeTo(ms / 1500, 1e-9));
      }
      expect(tracker.add(measure(sample(ms: 2101), config).result!), 0);
      tracker.reset();
      tracker.add(measure(sample(), config).result!);
      tracker.add(measure(sample(ms: 250, betaX: 30.6), config).result!);
      expect(
        tracker.add(measure(sample(ms: 500, betaX: 31.2), config).result!),
        0,
      );
    },
  );
  test('automatic capture freezes a warning result and resets on incomplete frames', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(scannerProvider.notifier);
    notifier.observe(sample());
    notifier.observe(sample(ms: 250));
    notifier.observe(
      ScanObservation(timestamp: sample(ms: 500).timestamp, markers: []),
    );
    expect(container.read(scannerProvider).progress, 0);
    for (var ms = 750; ms <= 2250; ms += 250) {
      notifier.observe(sample(ms: ms, betaX: 35));
    }
    final captured = container.read(scannerProvider).measurement!;
    expect(captured.distances.first.withinTolerance, isFalse);
    notifier.observe(sample(ms: 2500));
    expect(container.read(scannerProvider).measurement, same(captured));
    notifier.reset();
    expect(container.read(scannerProvider).measurement, isNull);
  });
}
