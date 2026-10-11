import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_observation.dart';
import '../../../core/geometry/calibration.dart';
import '../../../core/geometry/measurement.dart';
import '../../../core/geometry/stability_tracker.dart';
import '../../configuration/providers/configuration_provider.dart';

export '../../configuration/providers/configuration_provider.dart'
    show calibrationConfigProvider;

class ScannerState {
  const ScannerState({
    this.latest,
    this.confirmed,
    this.measurement,
    this.progress = 0,
    this.issue,
    this.trackingResult,
  });
  final ScanObservation? latest;
  final ScanObservation? confirmed;
  final MeasurementResult? measurement;
  final double progress;
  final String? issue;
  final MeasurementResult? trackingResult;
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);

class ScannerNotifier extends Notifier<ScannerState> {
  final _stability = StabilityTracker();
  late CalibrationConfig _config;
  @override
  ScannerState build() {
    _config = ref.watch(calibrationConfigProvider);
    _stability.reset();
    return const ScannerState();
  }

  void observe(ScanObservation observation) {
    final attempt = measure(observation, _config);
    var progress = state.progress;
    var captured = state.measurement;
    if (captured == null) {
      if (attempt.result == null) {
        _stability.reset();
        progress = 0;
      } else {
        progress = _stability.add(attempt.result!);
        if (progress >= 1) captured = attempt.result;
      }
    }
    state = ScannerState(
      latest: observation,
      confirmed: observation.isComplete ? observation : state.confirmed,
      measurement: captured,
      progress: progress,
      issue: captured == null ? attempt.issue : null,
      trackingResult: attempt.result,
    );
  }

  void expire() {
    _stability.reset();
    state = ScannerState(
      confirmed: state.confirmed,
      measurement: state.measurement,
      progress: state.measurement == null ? 0 : 1,
    );
  }

  void reset() {
    _stability.reset();
    state = const ScannerState();
  }
}
