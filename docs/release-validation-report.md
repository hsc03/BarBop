# Release Validation Report

Date: 2026-07-15

Branch: `develop`

## Summary

Automated implementation checks pass for the current click and notification
feature set. Interactive notification reliability and multi-display checks
remain release gates and are not marked complete by automated results.

## Automated Results

| Check | Result | Notes |
|---|---|---|
| BarBop Debug build | Passed | Current non-Sandbox, Hardened Runtime target compiles. |
| BarBop Release build | Passed | Current release configuration compiles. |
| NotificationObserverSpike Debug/Release | Passed | Development-only target compiles with its shared scheme. |
| Test bundle compile | Passed | Swift Testing bundle compiles. |
| Unit tests | Passed | Most recent run: 48 tests, 0 failures. |
| Settings migrations | Passed | v1/v2 data migrates to v3 and invalid data recovers. |
| Notification detector core | Passed | Structure filtering, display selection, deduplication, callback filtering, retry bounds, state, and latency aggregation covered. |
| Display routing | Passed | Follow, main, specific, disconnected fallback, and all-display policies covered. |

Command-line execution can emit unrelated CoreSimulator warnings for this
macOS-only project. Record a new failure only when the build or test command
itself exits unsuccessfully.

## Confirmed Interactive Results

- BarBop local test notifications display after notification permission is
  granted.
- Five local test banners were visually confirmed in the current desktop
  session. The user sent them manually at approximately two-second intervals;
  each banner produced one effect on all three connected displays with no
  duplicate or residual panel. Synthetic Computer Use clicks were excluded
  because macOS did not visibly deliver those automated attempts.
- A clean product-only cold start was also confirmed after removing stale TCC
  entries and granting Accessibility to the fixed-path BarBop build. BarBop
  restored Notification Effects as Active without a preceding ordinary menu
  bar click, displayed the local banner, and replayed the saved yellow Flash
  effect on all three displays. The development spike was not running, so its
  fixed cyan effect could not mask this result.
- The 520x520 settings popover, Effects/Notifications tabs, fixed header and
  footer, scrollable content, collapsed Troubleshooting section, single compact
  color picker, and three-well Aurora editor were interactively confirmed.
- Clicking outside the transient popover closed it without terminating BarBop.
- The non-Sandbox spike can register as an Accessibility client and observe the
  confirmed `AXGroup/AXNotificationCenterBanner` structure.
- The Sandbox comparison could not register BarBop as an Accessibility client,
  so direct Developer ID distribution is required.

## Pending Manual Release Gates

- Independently confirm an isolated five-request spike run produces exactly
  five filtered detections. A reset run made approximately five requests but
  recorded six distinct banners (24 callbacks, 6 candidates, 6 detections,
  0 duplicates, 24 ms average and 67 ms maximum latency) because an earlier
  macOS-delayed local notification was delivered in the same run. This is not
  counted as an exact 5/5 detector sample.
- Verify at least 19 of 20 visible external-app banners with one effect each.
- Verify follow, main, specific, and all-display modes using at least two
  displays, including disconnection and reconnection.
- Verify zero false positives during 10 minutes idle and ten Notification
  Center open/close cycles.
- Verify no effects for five notifications suppressed by Focus mode or app
  settings.
- Verify rapid/grouped notifications, three sleep/wake cycles, and three
  Notification Center restarts without duplicate or residual panels.
- Verify maximum detection-to-effect latency remains within 500 ms.
- Complete the click, settings, persistence, Reduce Motion, and corrupted-data
  checks in `phase-5-quality-checklist.md`.

## Release Readiness

Automated gate: **Passed**

Interactive reliability gate: **Pending**

Signing and notarization gate: **Pending**

The application may be pushed to the development repository, but a public
release and Homebrew Cask must wait for all three gates.
