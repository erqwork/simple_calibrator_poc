import 'dart:math';

const expectedMarkerIds = {
  'alpha:1',
  'alpha:2',
  'beta:1',
  'beta:2',
  'gamma:1',
  'gamma:2',
};

class MarkerDetection {
  MarkerDetection(this.identifier, Iterable<Point<double>> corners)
    : corners = List.unmodifiable(corners);
  final String identifier;
  final List<Point<double>> corners;
  bool get hasCorners =>
      corners.length == 4 && corners.every((p) => p.x.isFinite && p.y.isFinite);
}

/// One detector callback, never an accumulation across camera frames.
class ScanObservation {
  ScanObservation({
    required this.timestamp,
    required Iterable<MarkerDetection> markers,
    this.coordinates,
  }) : markers = List.unmodifiable(
         markers.where((m) => expectedMarkerIds.contains(m.identifier)),
       );
  final DateTime timestamp;
  final CaptureCoordinates? coordinates;
  final List<MarkerDetection> markers;
  Set<String> get identifiers =>
      Set.unmodifiable(markers.map((m) => m.identifier));
  bool get hasDuplicates => identifiers.length != markers.length;
  bool get isComplete =>
      !hasDuplicates && identifiers.containsAll(expectedMarkerIds);
  bool get hasAllCorners => isComplete && markers.every((m) => m.hasCorners);
}

/// Top-left origin, x right and y down; detector has already rotated/mirrored
/// corners into the displayed camera orientation. Dimensions are pixel units.
class CaptureCoordinates {
  const CaptureCoordinates({required this.reportedWidth, required this.reportedHeight,
    required this.width, required this.height, required this.backend,
    this.landscapeAdjusted = false});
  final double reportedWidth;
  final double reportedHeight;
  final double width;
  final double height;
  final String backend;
  final bool landscapeAdjusted;
  bool get isValid => width.isFinite && height.isFinite && width > 0 && height > 0;
  bool contains(Point<double> point) => isValid && point.x.isFinite && point.y.isFinite &&
    point.x >= 0 && point.y >= 0 && point.x <= width && point.y <= height;
}
