import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../services/marker_sheet.dart';

class MarkerSheetScreen extends StatefulWidget {
  const MarkerSheetScreen({super.key});
  @override
  State<MarkerSheetScreen> createState() => _MarkerSheetScreenState();
}

class _MarkerSheetScreenState extends State<MarkerSheetScreen> {
  Uint8List? _bytes;
  bool _busy = false;
  String? _error;
  Future<void> _export({required bool print}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = _bytes ??= await MarkerSheet().generatePdf();
      final result = print
          ? await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              format: PdfPageFormat.letter,
              dynamicLayout: false,
              name: 'calibration-markers-letter.pdf',
            )
          : await Printing.sharePdf(
              bytes: bytes,
              filename: 'calibration-markers-letter.pdf',
            );
      if (!result && mounted) {
        setState(
          () => _error =
              'Export was cancelled or unavailable. You can try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not export the PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('QR calibration sheet')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.qr_code_2, size: 96),
            const SizedBox(height: 24),
            Text(
              'Print your calibration markers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'One US Letter sheet with Alpha, Beta, and Gamma strips. Each pair has 40 mm center-to-center spacing and a marked midpoint.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Print in black ink at Actual size / 100%. Disable Fit or Shrink. Verify the 100 mm ruler before cutting the strips.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _export(print: false),
              icon: Icon(kIsWeb ? Icons.download : Icons.share),
              label: Text(kIsWeb ? 'Download PDF' : 'Save / share PDF'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(print: true),
              icon: const Icon(Icons.print),
              label: const Text('Print / Save as PDF'),
            ),
            const SizedBox(height: 12),
            if (!kIsWeb)
              const Text(
                'Use the system print dialog’s Save as PDF destination to save a copy on your device, or share it to a files app.',
              ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    ),
  );
}
