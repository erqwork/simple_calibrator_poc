import 'dart:math';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/scan_observation.dart';

ScanObservation observationFromCapture(BarcodeCapture capture, {
  bool androidLandscape = false, String backend = 'unknown',
}) =>
    ScanObservation(
      timestamp: DateTime.now(),
      coordinates: CaptureCoordinates(reportedWidth: capture.size.width,
        reportedHeight: capture.size.height,
        width: androidLandscape ? capture.size.height : capture.size.width,
        height: androidLandscape ? capture.size.width : capture.size.height,
        backend: backend, landscapeAdjusted: androidLandscape),
      markers: capture.barcodes
          .where(
            (b) =>
                b.format == BarcodeFormat.qrCode &&
                expectedMarkerIds.contains(b.rawValue),
          )
          .map(
            (b) => MarkerDetection(
              b.rawValue!,
              b.corners.map((p) => Point(p.dx, p.dy)),
            ),
          ),
    );
