import 'dart:math';

Point<double> midpoint(Point<double> a, Point<double> b) =>
    Point((a.x + b.x) / 2, (a.y + b.y) / 2);

/// Corners must describe a nondegenerate convex quadrilateral in perimeter order.
bool validCorners(List<Point<double>> corners) {
  if (corners.length != 4 ||
      corners.any((p) => !p.x.isFinite || !p.y.isFinite)) {
    return false;
  }
  double? sign;
  for (var i = 0; i < 4; i++) {
    final a = corners[i];
    final b = corners[(i + 1) % 4];
    final c = corners[(i + 2) % 4];
    final cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
    if (!cross.isFinite || cross.abs() < 1e-9) return false;
    if (sign != null && cross * sign <= 0) return false;
    sign = cross;
  }
  return true;
}

Point<double> markerCenter(List<Point<double>> corners) => Point(
  corners.fold(0.0, (sum, p) => sum + p.x) / 4,
  corners.fold(0.0, (sum, p) => sum + p.y) / 4,
);
