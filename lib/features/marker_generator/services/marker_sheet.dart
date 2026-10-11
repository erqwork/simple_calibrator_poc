import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

/// Physical dimensions and payloads for the first printable marker profile.
/// QR symbol size excludes the four-module white quiet zone on each side.
class MarkerSheet {
  static const groups = ['alpha', 'beta', 'gamma'];
  static const separationMm = 40.0;
  static const symbolMm = 24.0;
  static const stripWidthMm = 80.0;
  static const stripHeightMm = 42.0;
  static const quietModules = 4;

  static String identifier(String group, int number) => '$group:$number';

  static QrImage matrix(String payload) =>
      QrImage(QrCode(2, QrErrorCorrectLevel.M)..addData(payload));

  Future<Uint8List> generatePdf() async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: pw.EdgeInsets.all(15 * PdfPageFormat.mm),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Calibration markers - profile v1',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'US Letter (8.5 x 11 inches). Print at 100% / Actual size.\n'
              'Disable Fit, Shrink, and scaling. Verify the ruler before cutting.\n'
              'Cut along each border; keep both QR codes together on the strip.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            for (final group in groups) ...[
              pw.Center(child: _strip(group)),
              pw.SizedBox(height: 16),
            ],
            pw.Text(
              'Scale check: end-to-end length must be 100 mm.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.CustomPaint(
              size: PdfPoint(100 * PdfPageFormat.mm, 8 * PdfPageFormat.mm),
              painter: (canvas, size) {
                canvas.setStrokeColor(PdfColors.black);
                canvas.setLineWidth(0.5);
                canvas.drawLine(0, 10, size.x, 10);
                for (var i = 0; i <= 10; i++) {
                  final x = i * 10 * PdfPageFormat.mm;
                  canvas.drawLine(x, 6, x, 18);
                }
                canvas.strokePath();
              },
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Each QR symbol is 24 mm wide, with a clear white margin.\n'
              'QR centers are 40 mm apart. The + marks the pair midpoint.\n'
              'Use flat, matte strips. Keep all six codes visible in one frame.\n'
              'Detection and consistent scale do not guarantee measurement accuracy.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
    return document.save();
  }

  pw.Widget _strip(String group) {
    const mm = PdfPageFormat.mm;
    return pw.Container(
      width: stripWidthMm * mm,
      height: stripHeightMm * mm,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.4)),
            ),
          ),
          pw.Positioned(
            left: 0,
            right: 0,
            top: 2 * mm,
            child: pw.Center(
              child: pw.Text(
                group.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          for (var number = 1; number <= 2; number++)
            pw.Positioned(
              left: ((number == 1 ? 20 : 60) - symbolMm / 2) * mm,
              top: 10 * mm,
              child: _symbol(identifier(group, number)),
            ),
          for (var number = 1; number <= 2; number++)
            pw.Positioned(
              left: (number == 1 ? 4 : 44) * mm,
              top: 38 * mm,
              right: (number == 1 ? 44 : 4) * mm,
              child: pw.Center(
                child: pw.Text(
                  identifier(group, number),
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ),
          pw.Positioned(
            left: 37 * mm,
            top: 19 * mm,
            right: 37 * mm,
            child: pw.Center(
              child: pw.Text('+', style: const pw.TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _symbol(String payload) {
    final qr = matrix(payload);
    return pw.CustomPaint(
      size: PdfPoint(symbolMm * PdfPageFormat.mm, symbolMm * PdfPageFormat.mm),
      painter: (canvas, size) {
        final module = size.x / qr.moduleCount;
        canvas.setFillColor(PdfColors.black);
        for (var row = 0; row < qr.moduleCount; row++) {
          for (var col = 0; col < qr.moduleCount; col++) {
            if (qr.isDark(row, col)) {
              canvas.drawRect(
                col * module,
                size.y - (row + 1) * module,
                module,
                module,
              );
            }
          }
        }
        canvas.fillPath();
      },
    );
  }
}
