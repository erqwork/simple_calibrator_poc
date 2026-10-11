import '../../../core/geometry/measurement.dart';
import '../../../core/geometry/calibration.dart';

class HistoryCapture {
  HistoryCapture({
    required this.timestamp,
    required this.config,
    required Iterable<PairMeasurement> distances,
    required this.pixelsPerMm,
  }) : distances = List.unmodifiable(distances);
  factory HistoryCapture.fromResult(MeasurementResult result) => HistoryCapture(
    timestamp: result.observation.timestamp,
    config: result.config,
    distances: result.distances,
    pixelsPerMm: result.pixelsPerMm,
  );
  final DateTime timestamp;
  final CalibrationConfig config;
  final List<PairMeasurement> distances;
  final double pixelsPerMm;
  bool get allPass => distances.every((d) => d.withinTolerance);
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'pixelsPerMm': pixelsPerMm,
    'config': {
      'separation': config.markerSeparationMm,
      'targets': [
        config.alphaBetaTargetMm,
        config.betaGammaTargetMm,
        config.alphaGammaTargetMm,
      ],
      'tolerance': config.allowedDeviationMm,
      'scaleTolerance': config.scaleRelativeTolerance,
      'stabilityRange': config.stabilityRangeMm,
      'windowMs': config.captureWindow.inMilliseconds,
      'gapMs': config.maximumDetectionGap.inMilliseconds,
    },
    'distances': distances
        .map(
          (d) => {
            'pair': d.pair.name,
            'measured': d.measuredMm,
            'target': d.targetMm,
            'tolerance': d.toleranceMm,
          },
        )
        .toList(),
  };
  factory HistoryCapture.fromJson(Map<String, dynamic> json) {
    final c = json['config'] as Map<String, dynamic>;
    final targets = c['targets'] as List;
    return HistoryCapture(
      timestamp: DateTime.parse(json['timestamp'] as String),
      pixelsPerMm: (json['pixelsPerMm'] as num).toDouble(),
      config: CalibrationConfig(
        markerSeparationMm: (c['separation'] as num).toDouble(),
        alphaBetaTargetMm: (targets[0] as num).toDouble(),
        betaGammaTargetMm: (targets[1] as num).toDouble(),
        alphaGammaTargetMm: (targets[2] as num).toDouble(),
        allowedDeviationMm: (c['tolerance'] as num).toDouble(),
        scaleRelativeTolerance: (c['scaleTolerance'] as num).toDouble(),
        stabilityRangeMm: (c['stabilityRange'] as num).toDouble(),
        captureWindow: Duration(milliseconds: c['windowMs'] as int),
        maximumDetectionGap: Duration(milliseconds: c['gapMs'] as int),
      ),
      distances: (json['distances'] as List).map(
        (value) => PairMeasurement(
          MeasurementPair.values.byName(value['pair'] as String),
          (value['measured'] as num).toDouble(),
          (value['target'] as num).toDouble(),
          (value['tolerance'] as num).toDouble(),
        ),
      ),
    );
  }
}

class MeasurementGroup {
  MeasurementGroup({
    required this.id,
    required this.startedAt,
    required this.dailyNumber,
    Iterable<HistoryCapture> captures = const [],
  }) : captures = List.unmodifiable(captures);
  final String id;
  final DateTime startedAt;
  final int dailyNumber;
  final List<HistoryCapture> captures;

  /// Initial capture is attempt one, each later capture is a measured adjustment.
  int? get adjustmentsToIdeal {
    final index = captures.indexWhere((c) => c.allPass);
    return index < 0 ? null : index;
  }

  MeasurementGroup append(HistoryCapture capture) => MeasurementGroup(
    id: id,
    startedAt: startedAt,
    dailyNumber: dailyNumber,
    captures: [...captures, capture],
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'dailyNumber': dailyNumber,
    'captures': captures.map((c) => c.toJson()).toList(),
  };
  factory MeasurementGroup.fromJson(Map<String, dynamic> json) =>
      MeasurementGroup(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        dailyNumber: json['dailyNumber'] as int,
        captures: (json['captures'] as List).map(
          (c) => HistoryCapture.fromJson(c as Map<String, dynamic>),
        ),
      );
}
