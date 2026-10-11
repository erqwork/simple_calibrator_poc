import 'package:flutter/material.dart';

import 'home_screen.dart';

class CalibrationApp extends StatelessWidget {
  const CalibrationApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Simple Calibrator',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
    ),
    home: const HomeScreen(),
  );
}
