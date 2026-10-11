import 'dart:io';

import 'package:simple_calibrator_poc/features/marker_generator/services/marker_sheet.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.length > 1) {
    stdout.writeln('Usage: dart run tool/generate_markers.dart [output.pdf]');
    if (args.length > 1) exitCode = 64;
    return;
  }
  final file = File(
    args.isEmpty ? 'generated/calibration-markers-letter.pdf' : args.single,
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(await MarkerSheet().generatePdf(), flush: true);
  stdout.writeln('Created ${file.absolute.path}');
  stdout.writeln(
    'Print at Actual size / 100%. Verify the 100 mm ruler before use.',
  );
}
