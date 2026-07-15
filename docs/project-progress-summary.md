# BarBop Progress Summary

Date: 2026-07-15

Branch: `develop`

## Current Product Direction

BarBop is a macOS menu bar utility that plays short visual effects for menu bar
clicks and visible notification banners. It does not modify system menus or
third-party popovers. Effects are rendered in temporary click-through panels.

Click Effects and Notification Effects are independent. Notification Effects
observe only structural Accessibility events for banners that macOS actually
displays; BarBop does not read notification content.

## Current Feature Set

- Menu bar status item with Settings and Quit actions.
- First-launch Settings guidance and click-monitor status.
- Independent Click Effects and Notification Effects toggles.
- Flash, Pulse, Sweep, and three-color Aurora styles.
- Blue default color, dedicated opacity control, and persistent settings.
- Reduce Motion fallback and rapid-event panel cancellation.
- Local test notification control with foreground presentation.
- Accessibility onboarding and automatic detector reconnection.
- Notification display targets: banner display, main display, a stable
  UUID-selected display, or all connected displays.
- Aurora Bar application icon and a template-rendered menu bar symbol.
- Settings schema v3 with v1 and v2 migration and corrupted-data recovery.

## Architecture

| Component | Responsibility |
|---|---|
| `AppDelegate` / `AppEnvironment` | Lifecycle, status item, settings window, and service wiring |
| `EffectSettingsStore` | Versioned local persistence and migration |
| `MenuBarEventMonitor` | Global and local mouse monitoring |
| `NotificationBannerDetector` | Public AX observation, structural filtering, deduplication, and diagnostics |
| `NotificationEffectController` | Permission gating, lifecycle recovery, and notification effect routing |
| `NotificationDisplayResolver` | Pure display-target policy resolution using stable display UUIDs |
| `MenuBarEffectController` | Single- or multi-display click-through panel playback |
| `NotificationObserverSpike` | Development-only AX structure and reliability diagnostic app |

## Privacy and Distribution Boundaries

BarBop does not read notification titles, bodies, source application names, or
button labels. It does not access Notification Center databases, system logs,
screenshots, pixels, OCR, private APIs, or the network. Detector diagnostics
remain in memory and are not printed by the shared production implementation.

The tested App Sandbox configuration could not register as an Accessibility
client. BarBop therefore keeps Hardened Runtime enabled but uses a non-Sandbox
Developer ID distribution path. The Mac App Store is not a target for the
current notification implementation.

## Validation Status

- BarBop and NotificationObserverSpike Debug and Release builds have passed.
- The full automated suite most recently passed 42 tests.
- Settings migration, detector filtering and deduplication, permission gating,
  notification scheduling, display resolution, and multi-panel playback have
  automated coverage.
- Five local test notification banners were visually confirmed. The isolated
  reset-and-five detector count is still pending.
- External-app reliability, idle false positives, Focus mode, two-display
  routing, sleep/wake, and Notification Center restart scenarios remain manual
  release gates.
- Developer ID signing, notarization, stapling, and clean-install verification
  have not yet been completed.

See `phase-5-validation-report.md`, `phase-5-quality-checklist.md`, and
`notification-trigger-spike-report.md` for the detailed evidence and pending
matrix.

## Repository and Release Flow

- Active implementation is committed to `develop`.
- Validated release preparation moves to `release`.
- Stable release history is merged to `main` after signing and validation.
- Source and GitHub Release artifacts live in `hsc03/BarBop`.
- Homebrew metadata lives separately in `hsc03/homebrew-tap`.

The proposed first public version is `0.1.0`, but the project version and build
number are finalized only on the release branch. The current macOS 26.5 and
arm64 requirements must be verified before publishing the Cask.

## Next Work

1. Complete the manual notification and multi-display reliability matrix.
2. Finalize the minimum supported macOS version and CPU architecture.
3. Prepare the `release` branch and set version/build numbers.
4. Sign with Developer ID, notarize, staple, and verify on a clean account.
5. Publish the immutable GitHub Release and public SHA-256 checksum.
6. Publish and validate `Casks/barbop.rb` in `hsc03/homebrew-tap`.
