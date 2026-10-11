import 'measurement.dart';

/// Tracks a bounded range across the entire uninterrupted capture window.
class StabilityTracker {
  DateTime? _start;
  DateTime? _last;
  final _minimum = <double>[];
  final _maximum = <double>[];

  void reset() {
    _start = _last = null;
    _minimum.clear();
    _maximum.clear();
  }

  double add(MeasurementResult result) {
    final time = result.observation.timestamp;
    final config = result.config;
    if (_last != null &&
        (time.isBefore(_last!) ||
            time.difference(_last!) > config.maximumDetectionGap)) {
      reset();
    }
    final values = result.distances.map((d) => d.measuredMm).toList();
    if (_start != null) {
      for (var i = 0; i < values.length; i++) {
        final low = values[i] < _minimum[i] ? values[i] : _minimum[i];
        final high = values[i] > _maximum[i] ? values[i] : _maximum[i];
        if (high - low > config.stabilityRangeMm + 1e-9) {
          reset();
          break;
        }
      }
    }
    if (_start == null) {
      _start = time;
      _minimum.addAll(values);
      _maximum.addAll(values);
    } else {
      for (var i = 0; i < values.length; i++) {
        if (values[i] < _minimum[i]) _minimum[i] = values[i];
        if (values[i] > _maximum[i]) _maximum[i] = values[i];
      }
    }
    _last = time;
    return (time.difference(_start!).inMicroseconds /
            config.captureWindow.inMicroseconds)
        .clamp(0.0, 1.0);
  }
}
