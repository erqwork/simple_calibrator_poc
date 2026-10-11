import 'dart:convert';

import 'package:simple_calibrator_poc/features/marker_generator/services/marker_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('six unique payloads fit the fixed QR profile with clear margins', () {
    final ids = <String>{};
    for (final group in MarkerSheet.groups) {
      for (var number = 1; number <= 2; number++) {
        final id = MarkerSheet.identifier(group, number);
        ids.add(id);
        final qr = MarkerSheet.matrix(id);
        expect(qr.moduleCount, 25);
        final quietMm =
            MarkerSheet.quietModules * MarkerSheet.symbolMm / qr.moduleCount;
        expect(quietMm, lessThan(4));
        expect(
          MarkerSheet.symbolMm + 2 * quietMm,
          lessThan(MarkerSheet.separationMm),
        );
      }
    }
    expect(ids, {
      'alpha:1',
      'alpha:2',
      'beta:1',
      'beta:2',
      'gamma:1',
      'gamma:2',
    });
  });
  test('generates a PDF without camera initialization', () async {
    final bytes = await MarkerSheet().generatePdf();
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
