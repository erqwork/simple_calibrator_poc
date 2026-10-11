import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/scanner_adapter.dart';
import '../providers/scanner_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../history/presentation/history_screen.dart';
import '../../../shared/widgets/pair_result.dart';
import '../../../shared/widgets/measurement_overlay.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  bool _started = false;
  int _session = 0;
  Timer? _expiry;
  String? _groupId;
  String? _historyError;
  bool _saving = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      ref.read(scannerProvider.notifier).reset();
    });
  }

  Future<void> _beginGroup() async {
    try {
      final id = await ref.read(historyProvider.notifier).beginGroup();
      if (mounted) {
        setState(() {
          _groupId = id;
          _historyError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _historyError =
              'Could not start measurement history. Please retry.',
        );
      }
    }
  }

  Future<void> _saveCapture() async {
    final result = ref.read(scannerProvider).measurement;
    if (result == null || _groupId == null || _saving) return;
    setState(() {
      _saving = true;
      _historyError = null;
    });
    try {
      await ref.read(historyProvider.notifier).append(_groupId!, result);
    } catch (_) {
      if (mounted) {
        setState(
          () => _historyError =
              'Measurement not saved. Retry before taking another.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _expiry?.cancel();
      ref.read(scannerProvider.notifier).expire();
    }
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations([]));
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    super.dispose();
  }

  Future<void> _restart() async {
    if (_starting) return;
    if (_groupId == null) {
      setState(() => _starting = true);
      await _beginGroup();
      if (!mounted) return;
      setState(() => _starting = false);
      if (_groupId == null) return;
    }
    _expiry?.cancel();
    ref.read(scannerProvider.notifier).reset();
    setState(() {
      _started = true;
      _session++;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scannerProvider, (previous, next) {
      if (next.measurement != null &&
          next.measurement != previous?.measurement) {
        unawaited(_saveCapture());
      }
    });
    final state = ref.watch(scannerProvider);
    final ids = state.latest?.identifiers ?? <String>{};
    final confirmed = state.confirmed;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration scanner'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: _saving || _starting
                ? null
                : () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen(),
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _started
                          ? MobileScanner(
                              key: ValueKey(_session),
                              fit: BoxFit.contain,
                              overlayBuilder: (_, _) => MeasurementOverlay(
                                observation: state.latest,
                                result: state.trackingResult,
                                enabled: state.measurement != null,
                              ),
                              onDetect: (capture) {
                                ref
                                    .read(scannerProvider.notifier)
                                    .observe(
                                      observationFromCapture(
                                        capture,
                                        backend: kIsWeb
                                            ? 'web'
                                            : defaultTargetPlatform.name,
                                        androidLandscape:
                                            !kIsWeb &&
                                            defaultTargetPlatform ==
                                                TargetPlatform.android &&
                                            MediaQuery.orientationOf(context) ==
                                                Orientation.landscape,
                                      ),
                                    );
                                _expiry?.cancel();
                                _expiry = Timer(
                                  ref
                                          .read(calibrationConfigProvider)
                                          .maximumDetectionGap +
                                      const Duration(milliseconds: 1),
                                  () {
                                    if (mounted) {
                                      ref
                                          .read(scannerProvider.notifier)
                                          .expire();
                                    }
                                  },
                                );
                              },
                              placeholderBuilder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorBuilder: (_, error) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    error.errorCode ==
                                            MobileScannerErrorCode
                                                .permissionDenied
                                        ? 'Camera permission denied. Allow camera access in app or browser settings, then retry.'
                                        : 'Camera unavailable. Check that a camera is connected and not in use, then retry.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              onDetectError: (_, _) =>
                                  ref.read(scannerProvider.notifier).expire(),
                            )
                          : const Center(
                              child: Icon(Icons.qr_code_scanner, size: 96),
                            ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: IconButton.filled(
                          tooltip: state.measurement != null
                              ? 'Take next measurement'
                              : _started
                              ? 'Retry camera'
                              : 'Start camera',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56),
                            side: BorderSide(
                              color:
                                  state.measurement != null &&
                                      !_saving &&
                                      _historyError == null &&
                                      _groupId != null
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          onPressed:
                              _starting || _saving || _historyError != null
                              ? null
                              : _restart,
                          icon: const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        '${ids.length}/6 markers in latest detection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final group in ['alpha', 'beta', 'gamma'])
                            Chip(
                              avatar: Icon(
                                ids.contains('$group:1') &&
                                        ids.contains('$group:2')
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                              ),
                              label: Text(
                                '$group: ${(ids.contains('$group:1') ? 1 : 0) + (ids.contains('$group:2') ? 1 : 0)}/2',
                              ),
                            ),
                        ],
                      ),
                      if (state.latest?.hasDuplicates ?? false)
                        const Text(
                          'Duplicate marker identifiers detected. Use one copy of each strip.',
                        ),
                      if (confirmed != null) ...[
                        const Text(
                          'Confirmed: all six detected together.',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Last confirmation: ${confirmed.timestamp.toLocal().toIso8601String().substring(11, 19)}',
                        ),
                        Text(
                          confirmed.hasAllCorners
                              ? 'Corner coordinates received for all six markers.'
                              : 'Six identifiers read; some corner coordinates are unavailable.',
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (state.measurement == null) ...[
                        LinearProgressIndicator(value: state.progress),
                        Text('Hold steady: ${(state.progress * 100).round()}%'),
                        Text(
                          state.issue ?? 'Keep all six markers flat and visible for 1.5 seconds.',
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const Text(
                          'Measurement captured',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (final distance in state.measurement!.distances)
                          PairResult(distance),
                        const Text(
                          'Stable approximate measurement. Perspective can affect accuracy.',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          state.trackingResult == null
                              ? 'Live overlay paused: keep all six markers visible and geometry valid.'
                              : 'Lines show live distances; the captured result above stays fixed.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (_saving) const Text('Saving measurement…'),
                      if (_historyError != null) ...[
                        Text(_historyError!),
                        TextButton(
                          onPressed: _groupId == null ? _restart : _saveCapture,
                          child: const Text('Retry history save'),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
