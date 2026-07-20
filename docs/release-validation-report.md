# Release Validation Report

Date: 2026-07-20

Branch: `develop`

## Summary

Automated implementation checks pass for the current click and notification
feature set. The stable notification reliability gate failed because opening
and closing Notification Center produced an intermittent false effect. The
project owner accepted this known limitation only for a clearly labeled
`0.1.0` Preview release.

## Automated Results

| Check | Result | Notes |
|---|---|---|
| BarBop Debug build | Passed | Current non-Sandbox, Hardened Runtime target compiles. |
| BarBop Release build | Passed | Current release configuration compiles. |
| NotificationObserverSpike Debug/Release | Passed | Development-only target compiles with its shared scheme. |
| Test bundle compile | Passed | Swift Testing bundle compiles. |
| Unit tests | Passed | Most recent run: 59 tests, 0 failures. |
| Settings migrations | Passed | v1/v2 data migrates to v3 and invalid data recovers. |
| Notification detector core | Passed | Structure filtering, display selection, deduplication, callback filtering, retry bounds, state, and latency aggregation covered. |
| Display routing | Passed | Follow, main, specific, disconnected fallback, and all-display policies covered. |
| Sparkle update controller | Passed | Version UI, updater startup, readiness gating, and manual checks are covered by the 51-test suite. |

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
- A single isolated Slack example banner produced 12 callbacks and 3 accepted
  structural candidates, but exactly 1 detection and effect; 2 callbacks from
  the horizontal entrance animation were removed as duplicates. Effect latency
  was 5 ms. Slack exposed a root `AXGroup/none` with a direct
  `AXGroup/AXNotificationCenterAlertStack` child, without requiring content
  attributes.
- A later Preview regression segment at `11:56:54–11:56:56` detected the three
  user-triggered Slack banners as three distinct events. The enclosing
  non-isolated counter window reported a maximum 292 ms effect latency and also
  contained three earlier unrelated detections, which remain covered by the
  documented Preview false-positive limitation.
- The Sandbox comparison could not register BarBop as an Accessibility client,
  so direct Developer ID distribution is required.
- The final Notification Center open/close run produced 99 callbacks,
  5 candidates, 1 false detection, and 4 removed duplicates. Effect latency was
  291 ms. The zero-false-positive stable gate therefore failed even after
  structure, identity, presentation, and timing refinements.
- A real Sparkle update from notarized `0.1.0 (3)` to notarized `0.1.0 (4)`
  passed using the public `v0.1.0-build4-test` prerelease and its EdDSA-signed
  appcast. Sparkle downloaded, verified, installed, and relaunched the arm64
  update. The installed app reported build 4, retained settings and
  Accessibility behavior, passed strict nested code-signature verification,
  was accepted by Gatekeeper as `Notarized Developer ID`, and retained a valid
  stapled ticket. The public ZIP SHA-256 was
  `156306648c385866d094c690ed268117f1ec8ba9eb97513344ec455d57c56e3d`.

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
- Verify zero false positives during 10 minutes idle. The ten-cycle Notification
  Center open/close check failed with one false effect and is an explicitly
  accepted Preview limitation, not a passed stable gate.
- Verify no effects for five notifications suppressed by Focus mode or app
  settings.
- Verify rapid/grouped notifications, three sleep/wake cycles, and three
  Notification Center restarts without duplicate or residual panels.
- Verify maximum detection-to-effect latency remains within 500 ms.
- Complete the click, settings, persistence, Reduce Motion, and corrupted-data
  checks in `phase-5-quality-checklist.md`.

## Release Readiness

Automated gate: **Passed**

Stable interactive reliability gate: **Failed**

Preview exception: **Accepted with disclosure and Notification Effects off by default**

Signing and notarization gate: **Passed for 0.1.0 (4)**

Next release candidate: **0.1.0 (5); new archive and notarization required**

The application may proceed only as a clearly labeled Preview release. Release
notes, Settings, and README must disclose the Notification Center open/close
false-positive. It must not be described as having passed the stable
notification reliability gate.
