import 'dart:math';

import '../../features/scanner/models/scan_observation.dart';
import 'calibration.dart';
import 'point_utils.dart';

class PairMeasurement {
  const PairMeasurement(
    this.pair,
    this.measuredMm,
    this.targetMm,
    this.toleranceMm,
  );
  final MeasurementPair pair;
  final double measuredMm;
  final double targetMm;
  final double toleranceMm;
  double get deviationMm => measuredMm - targetMm;
  bool get withinTolerance => deviationMm.abs() <= toleranceMm + 1e-9;
}

class MeasurementResult {
  MeasurementResult({
    required this.observation,
    required this.config,
    required Iterable<PairMeasurement> distances,
    required this.pixelsPerMm,
    Map<String, Point<double>> groupMidpoints = const {},
  }) : distances = List.unmodifiable(distances),
       groupMidpoints = Map.unmodifiable(groupMidpoints);
  final ScanObservation observation;
  final CalibrationConfig config;
  final List<PairMeasurement> distances;
  final double pixelsPerMm;
  final Map<String, Point<double>> groupMidpoints;
}

class MeasurementAttempt {
  const MeasurementAttempt({this.result, this.issue});
  final MeasurementResult? result;
  final String? issue;
}

MeasurementAttempt measure(ScanObservation scan, CalibrationConfig config) {
  if (!config.isValid) {
    return const MeasurementAttempt(
      issue: 'Invalid calibration configuration.',
    );
  }
  final obstructed = scan.markers
      .where((m) => !validCorners(m.corners))
      .map((m) => m.identifier.split(':').first)
      .toSet();
  if (obstructed.isNotEmpty) {
    final names = obstructed
        .map((g) => '${g[0].toUpperCase()}${g.substring(1)}')
        .join(', ');
    return MeasurementAttempt(
      issue:
          '$names ${obstructed.length == 1 ? 'is' : 'are'} obstructed or corners are unreadable; please correct.',
    );
  }
  if (!scan.isComplete) {
    return const MeasurementAttempt(
      issue: 'All six unique markers are required. Check missing markers for obstruction.',
    );
  }
  if (scan.markers.any((m) => !validCorners(m.corners))) {
    return const MeasurementAttempt(
      issue: 'Marker corners are missing or invalid.',
    );
  }
  final centers = {
    for (final m in scan.markers) m.identifier: markerCenter(m.corners),
  };
  final midpoints = <String, Point<double>>{};
  final scales = <double>[];
  for (final group in ['alpha', 'beta', 'gamma']) {
    final a = centers['$group:1']!;
    final b = centers['$group:2']!;
    final scale = a.distanceTo(b) / config.markerSeparationMm;
    if (!scale.isFinite || scale <= 1e-9) {
      return const MeasurementAttempt(
        issue: 'Marker pair separation is invalid.',
      );
    }
    scales.add(scale);
    midpoints[group] = midpoint(a, b);
  }
  final scale = scales.reduce((a, b) => a + b) / scales.length;
  if (!scale.isFinite ||
      scales.any(
        (s) => (s - scale).abs() / scale > config.scaleRelativeTolerance + 1e-9,
      )) {
    return const MeasurementAttempt(
      issue: 'Calibration scales disagree. Flatten the strips and face the camera straight toward them.',
    );
  }
  final pairs = {
    MeasurementPair.alphaBeta: ('alpha', 'beta'),
    MeasurementPair.betaGamma: ('beta', 'gamma'),
    MeasurementPair.alphaGamma: ('alpha', 'gamma'),
  };
  final distances = <PairMeasurement>[];
  for (final entry in pairs.entries) {
    final distance =
        midpoints[entry.value.$1]!.distanceTo(midpoints[entry.value.$2]!) /
        scale;
    if (!distance.isFinite) {
      return const MeasurementAttempt(issue: 'Calculated distance is invalid.');
    }
    distances.add(
      PairMeasurement(
        entry.key,
        distance,
        config.targetFor(entry.key),
        config.allowedDeviationMm,
      ),
    );
  }
  return MeasurementAttempt(
    result: MeasurementResult(
      observation: scan,
      config: config,
      distances: distances,
      pixelsPerMm: scale,
      groupMidpoints: midpoints,
    ),
  );
}
