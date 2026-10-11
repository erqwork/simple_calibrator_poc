import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/geometry/calibration.dart';
import '../../core/geometry/measurement.dart';
import '../../features/scanner/models/scan_observation.dart';
import 'pair_result.dart';

/// Maps oriented detector pixels to a centered BoxFit.contain preview.
class PreviewProjection {
  PreviewProjection(this.coordinates, this.viewport);
  final CaptureCoordinates coordinates;
  final Size viewport;
  bool get isValid => coordinates.isValid && viewport.width.isFinite &&
    viewport.height.isFinite && viewport.width > 0 && viewport.height > 0;
  double get scale => min(viewport.width / coordinates.width, viewport.height / coordinates.height);
  Offset project(Point<double> point) => Offset(
    (viewport.width - coordinates.width * scale) / 2 + point.x * scale,
    (viewport.height - coordinates.height * scale) / 2 + point.y * scale);
}

/// Camera-independent renderer: takes a current observation and computed result.
/// Frozen captures and persistence stay outside this widget.
class MeasurementOverlay extends StatelessWidget {
  const MeasurementOverlay({super.key, required this.observation, required this.result,
    required this.enabled});
  final ScanObservation? observation;
  final MeasurementResult? result;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final coordinates = observation?.coordinates;
    if (!enabled || coordinates == null || !coordinates.isValid || result == null ||
      !identical(result!.observation, observation) ||
      observation!.markers.any((m) => m.corners.any((p) => !coordinates.contains(p)))) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(child: SizedBox.expand(child: CustomPaint(
      painter: _MeasurementPainter(coordinates, result!),
    )));
  }
}

class _MeasurementPainter extends CustomPainter {
  _MeasurementPainter(this.coordinates, this.result);
  final CaptureCoordinates coordinates;
  final MeasurementResult result;
  @override
  void paint(Canvas canvas, Size size) {
    final projection = PreviewProjection(coordinates, size);
    if (!projection.isValid) return;
    const groups = {
      MeasurementPair.alphaBeta: ('alpha', 'beta'),
      MeasurementPair.betaGamma: ('beta', 'gamma'),
      MeasurementPair.alphaGamma: ('alpha', 'gamma'),
    };
    for (final distance in result.distances) {
      final pair = groups[distance.pair]!;
      final start = result.groupMidpoints[pair.$1];
      final end = result.groupMidpoints[pair.$2];
      if (start == null || end == null) continue;
      final a = projection.project(start);
      final b = projection.project(end);
      final color = resultColor(distance);
      canvas.drawLine(a, b, Paint()..color = Colors.black87..strokeWidth = 5);
      canvas.drawLine(a, b, Paint()..color = color..strokeWidth = 3);
      for (final point in [a, b]) {
        canvas.drawCircle(point, 5, Paint()..color = Colors.black87);
        canvas.drawCircle(point, 3, Paint()..color = color);
      }
      final text = TextPainter(text: TextSpan(
        text: '${distance.measuredMm.toStringAsFixed(1)} mm',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout(maxWidth: max(1, size.width - 12));
      final center = Offset.lerp(a, b, 0.5)!;
      final position = Offset((center.dx - text.width / 2).clamp(6.0, max(6, size.width - text.width - 6)),
        (center.dy - text.height - 6).clamp(6.0, max(6, size.height - text.height - 6)));
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx - 4, position.dy - 3, text.width + 8, text.height + 6),
        const Radius.circular(4)), Paint()..color = Colors.black87);
      text.paint(canvas, position);
    }
  }
  @override
  bool shouldRepaint(covariant _MeasurementPainter oldDelegate) =>
    oldDelegate.result != result || oldDelegate.coordinates != coordinates;
}
