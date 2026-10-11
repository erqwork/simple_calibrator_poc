# Printable calibration markers

Run from the project root:

```powershell
flutter pub get
dart run tool/generate_markers.dart
# Optional destination:
dart run tool/generate_markers.dart generated/my-markers.pdf
```

Default output: `generated/calibration-markers-letter.pdf`.

Print on US Letter / ANSI A paper in black ink at **Actual size / 100%**.
Disable Fit and Shrink. Verify the ruler's end ticks are **100 mm apart**.
Cut the three **80 x 42 mm** strips along their borders, keeping each pair
together. Mount flat on matte white paper; do not obscure the codes or margins.
The QR centers are **40 mm apart**; the `+` marks their measurement midpoint.

Profile v1 uses exact payloads `alpha:1`, `alpha:2`, `beta:1`, `beta:2`,
`gamma:1`, `gamma:2`. Symbols are 24 mm square, QR version 2 (25 modules),
with medium error correction and at least four modules of white clearance.
PDF uses vector rectangles and physical units, avoiding raster DPI ambiguity.
Print and test detection before freezing the symbol size for physical mounting.

Keep all six codes visible in one frame; move closer if detection is difficult.
No fixed camera distance is required. Future calculations will validate geometry
after detection. Simple scaling assumes a flat plane viewed approximately
perpendicular to the camera; detection alone cannot establish millimeter accuracy.

Generation is local, independent of Flutter widgets and camera initialization.
The service lives in `lib/features/marker_generator/services/marker_sheet.dart`;
the CLI only handles output files. The app also provides PDF generation. This
generator exports PDF; PNG export is not implemented.

Checks: `flutter analyze` and `flutter test`.
