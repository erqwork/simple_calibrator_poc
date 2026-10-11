import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/configuration/providers/configuration_provider.dart';
import 'core/geometry/calibration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CalibrationConfig config;
  try {
    config = await ConfigurationStore().load();
  } catch (_) {
    config = const CalibrationConfig();
  }
  runApp(
    ProviderScope(
      overrides: [initialConfigProvider.overrideWithValue(config)],
      child: const CalibrationApp(),
    ),
  );
}
