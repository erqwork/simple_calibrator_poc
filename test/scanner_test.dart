import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_calibrator_poc/features/scanner/models/scan_observation.dart';
import 'package:simple_calibrator_poc/features/scanner/providers/scanner_provider.dart';

ScanObservation observation(Iterable<String> ids) => ScanObservation(
  timestamp: DateTime(2026, 10, 11),
  markers: ids.map(
    (id) => MarkerDetection(id, const [
      Point(0.0, 0.0),
      Point(1.0, 0.0),
      Point(1.0, 1.0),
      Point(0.0, 1.0),
    ]),
  ),
);

void main() {
  test('partial frames never accumulate into a complete scan', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(scannerProvider.notifier);
    notifier.observe(observation(['alpha:1', 'alpha:2', 'beta:1']));
    notifier.observe(observation(['beta:2', 'gamma:1', 'gamma:2']));
    expect(container.read(scannerProvider).confirmed, isNull);
    expect(container.read(scannerProvider).latest!.identifiers.length, 3);
    notifier.observe(observation(expectedMarkerIds));
    expect(container.read(scannerProvider).confirmed!.hasAllCorners, isTrue);
    notifier.expire();
    expect(container.read(scannerProvider).latest, isNull);
    expect(container.read(scannerProvider).confirmed, isNotNull);
    notifier.reset();
    expect(container.read(scannerProvider).confirmed, isNull);
  });

  test('duplicates rejected and unrelated payloads ignored', () {
    expect(observation([...expectedMarkerIds, 'alpha:1']).isComplete, isFalse);
    expect(observation([...expectedMarkerIds, 'unrelated']).isComplete, isTrue);
    final scan = ScanObservation(
      timestamp: DateTime.now(),
      markers: expectedMarkerIds.map((id) => MarkerDetection(id, [])),
    );
    expect(scan.isComplete, isTrue);
    expect(scan.hasAllCorners, isFalse);
    expect(() => scan.markers.clear(), throwsUnsupportedError);
  });
}
