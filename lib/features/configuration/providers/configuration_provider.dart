import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/geometry/calibration.dart';

class ConfigurationStore {
  late final _prefs = SharedPreferencesAsync();
  Future<CalibrationConfig> load() async {
    final raw = await _prefs.getString('target_distances_v1');
    if (raw == null) return const CalibrationConfig();
    final values = jsonDecode(raw) as List;
    final config = const CalibrationConfig().withTargets(
      alphaBetaMm: (values[0] as num).toDouble(),
      betaGammaMm: (values[1] as num).toDouble(),
      alphaGammaMm: (values[2] as num).toDouble(),
    );
    return config.isValid ? config : const CalibrationConfig();
  }

  Future<void> save(CalibrationConfig config) => _prefs.setString(
    'target_distances_v1',
    jsonEncode([
      config.alphaBetaTargetMm,
      config.betaGammaTargetMm,
      config.alphaGammaTargetMm,
    ]),
  );
}

final initialConfigProvider = Provider<CalibrationConfig>(
  (ref) => const CalibrationConfig(),
);
final configurationStoreProvider = Provider<ConfigurationStore>(
  (ref) => ConfigurationStore(),
);
final calibrationConfigProvider =
    NotifierProvider<ConfigurationNotifier, CalibrationConfig>(
      ConfigurationNotifier.new,
    );

class ConfigurationNotifier extends Notifier<CalibrationConfig> {
  @override
  CalibrationConfig build() => ref.watch(initialConfigProvider);
  Future<void> setTargets({
    required double alphaBetaMm,
    required double betaGammaMm,
    required double alphaGammaMm,
  }) async {
    final config = state.withTargets(
      alphaBetaMm: alphaBetaMm,
      betaGammaMm: betaGammaMm,
      alphaGammaMm: alphaGammaMm,
    );
    if (!config.isValid) {
      throw ArgumentError('Targets must be finite and positive.');
    }
    await ref.read(configurationStoreProvider).save(config);
    state = config;
  }
}
