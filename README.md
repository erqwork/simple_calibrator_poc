# Simple Calibrator PoC

## Platforms

Android and web are the only current development targets. The Windows runner is kept
for possible desktop builds; Windows camera scanning is not supported.

## Simple Calibrator

The app starts at Home with Scanner, History, QR calibration sheet, and
Configuration options. Home and History do not create measurement groups.
Pressing Start camera in Scanner starts a fresh group; Back returns to Home.

The QR sheet screen generates the same Letter-size PDF as the CLI. Chrome's
Download PDF saves it through the browser. On Android, use Save / share PDF or
Print / Save as PDF and choose the system Save as PDF destination. Print at
100% / Actual size and verify the ruler before using the strips.

Configuration edits the three target distances in millimeters. Inputs must be
finite and positive. Targets persist locally across restarts and apply to new
measurements; historical captures retain their original values. Marker spacing
and reliability thresholds remain fixed for the printed marker profile.

## Test the six markers in the app

```powershell
flutter run -d chrome
flutter devices
flutter run -d <device-id>
```

Tap **Start camera** and grant permission. Arrange all three printed strips
in view. The scanner shows each pair's status and the number of expected
identifiers in the latest detection result. Success requires all six distinct
identifiers in **one callback**; detections from separate frames are never
combined. The last successful observation is retained with its time and whether
four corner coordinates were supplied for every marker. Reset starts a fresh
test. Live indicators clear after the 500 ms detection gap.

Android is the main physical test target. Chrome camera access requires localhost
or HTTPS; opening a plain HTTP development server from a phone will not suffice.
Web scanning may download its decoding library on first use. Camera permission
errors have retry guidance. Windows desktop camera scanning is not supported.

This stage retains immutable observations, calculates approximate distances,
and automatically captures after a stable window. It saves grouped history
locally; photos are not saved. `mobile_scanner`
handles the camera; Riverpod handles scan state. The existing PDF/QR generator
remains the printing tool, so a separate camera or QR widget package is not
needed at this stage.

## Measurement and automatic capture

The immutable `CalibrationConfig` in `lib/core/geometry/calibration.dart`
contains the default 90/70/72 mm targets, 40 mm marker separation, and inclusive
±5 mm testing tolerance. `withTargets` creates a new configuration for a future editor;
results retain their original configuration snapshot. The engine takes this
configuration explicitly and has no camera or Flutter imports.

The engine validates convex, nondegenerate QR corners, averages their coordinates
for QR centers, and uses each pair's midpoint as its reference point. It averages
the three pixels-per-mm scales; each must be within 5% of the average.

Automatic capture requires qualifying observations spanning at least 1.5 seconds,
with no gap greater than 500 ms. Each pairwise distance must stay within a 1 mm
total range across that window. Missing or invalid markers, inconsistent scale,
or excessive movement restart the window. Capture freezes the latest qualifying
result, including warnings for distances outside target tolerance. Reset permits
another capture. Reliability thresholds are initial tuning values, not accuracy
guarantees; stable perspective distortion can still bias measurements.

## Grouped history

The first Start camera press creates a persistent group, including attempts with
no captures. Simply opening Scanner does not add history.
Use **Take next measurement** after making an adjustment to append another capture
to the same group. The History icon opens saved groups; the scanner icon in
History opens Scanner, ready to start a fresh group. Captures appear in chronological order inside groups,
with newest groups first. Each capture keeps its original configuration and values.

The initial capture is the baseline; each subsequent capture counts as one measured
adjustment. History reports the number before the first capture with all three
distances inside tolerance, or says ideal distances were not reached. This counts
captured attempts, not unobserved physical changes. Overages are red, shortages
blue, and acceptable distances green. Local JSON history uses shared_preferences;
Android and browser histories are separate, and clearing app/browser data removes
them. A full app restart is needed after adding the storage plugin.

Detected markers with invalid corners get a group-specific obstruction message.
When a QR cannot be decoded at all, the scanner reports a missing marker because
its group cannot be inferred from an unreadable identifier.

## Printable calibration markers

Run `dart run tool/generate_markers.dart` to create the Letter-size marker PDF
at `generated/calibration-markers-letter.pdf`. Print at **Actual size / 100%**.
See [generator instructions](tool/README.md) for dimensions and verification.
