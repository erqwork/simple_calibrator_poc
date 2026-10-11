import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/scanner/presentation/scanner_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/marker_generator/presentation/marker_sheet_screen.dart';
import '../features/configuration/presentation/configuration_screen.dart';
import '../features/configuration/providers/configuration_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(calibrationConfigProvider);
    final options = [
      (
        Icons.qr_code_scanner,
        'Scanner',
        'Measure your three marker strips',
        const ScannerScreen(),
      ),
      (
        Icons.history,
        'History',
        'Review captures and adjustments',
        const HistoryScreen(),
      ),
      (
        Icons.picture_as_pdf,
        'QR calibration sheet',
        'Generate, save, or print your markers',
        const MarkerSheetScreen(),
      ),
      (
        Icons.tune,
        'Configuration',
        'Set target distances between groups',
        const ConfigurationScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Calibrator')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.straighten, size: 64),
              const SizedBox(height: 16),
              Text(
                'Measure. Adjust. Compare.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use three printed QR strips to check distances and track your adjustments.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(option.$1),
                      title: Text(option.$2),
                      subtitle: Text(option.$3),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => option.$4),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Targets: ${config.alphaBetaTargetMm} / ${config.betaGammaTargetMm} / ${config.alphaGammaTargetMm} mm · ±${config.allowedDeviationMm} mm tolerance',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
