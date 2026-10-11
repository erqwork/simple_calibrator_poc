import 'package:flutter/material.dart';

import '../../core/geometry/measurement.dart';
import '../../core/geometry/calibration.dart';

Color resultColor(PairMeasurement distance) => distance.withinTolerance
    ? Colors.green
    : distance.deviationMm > 0
    ? Colors.red
    : Colors.blue;

class PairResult extends StatelessWidget {
  const PairResult(this.distance, {super.key, this.highContrast = false});
  final PairMeasurement distance;
  final bool highContrast;
  @override
  Widget build(BuildContext context) => Text(
    '${switch (distance.pair) {
      MeasurementPair.alphaBeta => 'Alpha-Beta',
      MeasurementPair.betaGamma => 'Beta-Gamma',
      MeasurementPair.alphaGamma => 'Alpha-Gamma',
    }}: ${distance.measuredMm.toStringAsFixed(1)} mm '
    '(target ${distance.targetMm.toStringAsFixed(1)}; '
    '${distance.deviationMm >= 0 ? '+' : ''}${distance.deviationMm.toStringAsFixed(1)} mm) '
    '${distance.withinTolerance
        ? 'Pass'
        : distance.deviationMm > 0
        ? 'Over'
        : 'Short'}',
    style: TextStyle(
      color: highContrast
          ? distance.withinTolerance
                ? Colors.green.shade900
                : distance.deviationMm > 0
                ? Colors.red.shade900
                : Colors.blue.shade900
          : resultColor(distance),
    ),
  );
}
