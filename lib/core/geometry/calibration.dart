enum MeasurementPair { alphaBeta, betaGamma, alphaGamma }

class CalibrationConfig {
  const CalibrationConfig({
    this.markerSeparationMm = 40,
    this.alphaBetaTargetMm = 90,
    this.betaGammaTargetMm = 70,
    this.alphaGammaTargetMm = 72,
    this.allowedDeviationMm = 5,
    this.scaleRelativeTolerance = 0.05,
    this.stabilityRangeMm = 1,
    this.captureWindow = const Duration(milliseconds: 1500),
    this.maximumDetectionGap = const Duration(milliseconds: 500),
  });
  final double markerSeparationMm;
  final double alphaBetaTargetMm;
  final double betaGammaTargetMm;
  final double alphaGammaTargetMm;
  final double allowedDeviationMm;
  final double scaleRelativeTolerance;
  final double stabilityRangeMm;
  final Duration captureWindow;
  final Duration maximumDetectionGap;

  double targetFor(MeasurementPair pair) => switch (pair) {
    MeasurementPair.alphaBeta => alphaBetaTargetMm,
    MeasurementPair.betaGamma => betaGammaTargetMm,
    MeasurementPair.alphaGamma => alphaGammaTargetMm,
  };

  bool get isValid =>
      [
        markerSeparationMm,
        alphaBetaTargetMm,
        betaGammaTargetMm,
        alphaGammaTargetMm,
      ].every((v) => v.isFinite && v > 0) &&
      [
        allowedDeviationMm,
        scaleRelativeTolerance,
        stabilityRangeMm,
      ].every((v) => v.isFinite && v >= 0) &&
      scaleRelativeTolerance < 1 &&
      captureWindow > Duration.zero &&
      maximumDetectionGap > Duration.zero;

  CalibrationConfig withTargets({
    double? alphaBetaMm,
    double? betaGammaMm,
    double? alphaGammaMm,
  }) => CalibrationConfig(
    markerSeparationMm: markerSeparationMm,
    alphaBetaTargetMm: alphaBetaMm ?? alphaBetaTargetMm,
    betaGammaTargetMm: betaGammaMm ?? betaGammaTargetMm,
    alphaGammaTargetMm: alphaGammaMm ?? alphaGammaTargetMm,
    allowedDeviationMm: allowedDeviationMm,
    scaleRelativeTolerance: scaleRelativeTolerance,
    stabilityRangeMm: stabilityRangeMm,
    captureWindow: captureWindow,
    maximumDetectionGap: maximumDetectionGap,
  );
}
