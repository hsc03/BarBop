# Notification Trigger Spike Report

Date: 2026-07-20

Status: No-Go — Notification Center presentation cannot be distinguished reliably

## Goal

Determine whether BarBop can reliably detect visible macOS notification banners
through public Accessibility APIs without reading notification content, using
private APIs, accessing Notification Center databases, or capturing the screen.

## Environment

- macOS: 26.5.2 (25F84)
- Architecture: Apple silicon (`arm64`)
- Notification Center bundle identifier: `com.apple.notificationcenterui`
- Spike target: `NotificationObserverSpike`
- App Sandbox: disabled for the spike and BarBop targets after the interactive
  Sandbox runtime failed to register BarBop as an Accessibility client
- Hardened Runtime: enabled
- Local signing: ad-hoc (`-`), with no Developer ID distribution

The comparison build is produced from the same target with
`ENABLE_APP_SANDBOX=YES`. It is a separate local artifact and does not change
the checked-in spike or BarBop entitlements.

## Automated Validation

| Check | Result | Notes |
|---|---|---|
| Xcode project and shared scheme discovery | Passed | `NotificationObserverSpike` is listed as a target and scheme. |
| Spike Debug build | Passed | Ad-hoc signed local build completed after lifecycle cleanup changes. |
| Spike Release build | Passed | Ad-hoc signed local build completed after lifecycle cleanup changes. |
| Existing BarBop Debug build | Passed | Existing target still compiles. |
| Existing BarBop Release build | Passed | Existing target still compiles. |
| Unit tests | Passed | 59 tests passed, including detector-core coverage for native banners and Slack alert-stack structures, expanded Notification Center structure classification, existing-element suppression, collapse-state timing, animation duplicate suppression, callback filtering and retry bounds, v1/v2-to-v3 migration, display routing, permission/scheduling, Accessibility gating, configured-effect routing, and update-controller behavior. |
| Candidate classification | Passed | Boundary rejection and largest cross-display intersection selection are covered by pure tests. |
| Duplicate suppression | Passed | Native banners suppress repeated callbacks for the same element and frame for one second. Slack alert-stack entrance animation suppresses repeated geometry callbacks for 0.4 seconds while preserving different screens and vertical positions. |
| State and diagnostics | Passed | Permission, process, observer states, reconnect counting, and average/maximum latency aggregation are covered by pure tests. |
| Local test notification | Passed | Permission states, first-use authorization, immediate scheduling, denied behavior, and effect-setting isolation are covered by injected tests. |
| Rejected callback structure | Passed | The last callback retains up to six structural ancestor snapshots even when no candidate passes the geometry filter. |
| Spike signature verification | Passed | The Debug app reports `adhoc,runtime` code-signing flags. |
| Local Debug launch | Passed | Disabled Xcode's separate Debug Dylib for the ad-hoc Hardened Runtime target after its mismatched Team ID caused an immediate dyld rejection; the rebuilt single-executable app remains running. |
| Checked-in Sandbox boundary | Direct distribution selected | The Sandbox BarBop build did not appear in System Settings > Accessibility after requesting access. BarBop is now `ENABLE_APP_SANDBOX=NO`; Hardened Runtime remains enabled. |
| Sandbox comparison build | Build passed; runtime pending | The override build contains `com.apple.security.app-sandbox=true`; five interactive detections and observer attachment still need validation. |
| Shared detector integration | Passed | The spike and BarBop now compile the same `NotificationBannerDetector`; the spike injects its fixed cyan panel and BarBop injects the configured effect renderer. |
| Notification display routing | Automated gate passed | Display targets use stable UUIDs. Follow, main, specific, disconnected fallback, and all-display frames pass pure and controller tests; interactive two-display validation remains pending. |

Automated checks validate the implementation mechanics, not whether the
current macOS Notification Center Accessibility tree exposes enough stable
structure. That question remains intentionally interactive.

Launching the spike executable as a child of Codex is not a valid Accessibility
test: TCC attributes that process to `com.openai.codex`, so the spike's enabled
Accessibility entry is not honored. Interactive validation must launch the
fixed `build/NotificationObserverSpike.app` from Finder (or Xcode), making the
spike the responsible application. No private TCC entitlement will be added.

## Privacy Boundary

The spike reads only the AX callback event name, receive time, element identity,
role, subrole, parent depth, position, size, and derived display ID. It does not
request or retain notification titles, bodies, source app names, button labels,
screenshots, pixels, system logs, or Notification Center database records.
Metrics remain in memory and are cleared when the spike exits.

Candidate selection, display matching, duplicate suppression, and latency
aggregation are isolated from AppKit and AX observation. The clock and screen
geometry used by the live monitor are injected dependencies. Duplicate keys use
both AX element identity and rounded frame, preventing repeated callbacks for
one element while allowing rapid banners that reuse the same screen position.

On app activation, wake, and Notification Center termination/relaunch, the AX
observer and any visible test panel are cleaned up before reconnection. The
diagnostic UI exposes registered AX event names, callback/candidate/detection/
duplicate counts, successful reconnects, average and maximum effect-start
latency, the last accepted structural event, and the last callback's structural
ancestor chain. Rejected callbacks remain visible without reading content.

## Validation Procedure

1. Run the `NotificationObserverSpike` scheme from Xcode.
2. Choose **Request Accessibility Access**, approve the spike in System
   Settings, return to the app, and choose **Reconnect**.
3. Confirm the state changes to **Observing visible notification banners**.
4. Reset counters before each scenario and record the observed results below.
5. In BarBop Settings, choose **Send Test Notification**, approve local
   notification permission if requested, and verify five visible test banners.
6. Repeat the core five-banner check with the Sandbox comparison artifact and
   record whether permission and observer attachment still work.

## Results

| Scenario | Required sample | Pass threshold | Actual | Result |
|---|---:|---:|---:|---|
| Visible banners from different apps | 20 | At least 19 detected, one effect each | Pending | Pending |
| Primary display targeting | 10 | At least 95% correct display | Pending | Pending |
| Secondary display targeting | 10 | At least 95% correct display | Pending | Pending |
| User-selected display targeting | 10 per mode | Follow, main, specific, and all-display policies match Settings | Pending | Pending |
| Idle false positives | 10 minutes | 0 effects | Pending | Pending |
| Open and close Notification Center | 10 cycles | 0 effects | Final run: 99 callbacks, 5 candidates, 1 detected false-positive, 4 duplicates removed; effect latency 291 ms. Earlier refinements also produced 25, 12, 1, 1, and 2 false-positive detections. | Failed |
| Focus mode suppressed notifications | 5 | 0 effects | Pending | Pending |
| Rapid and grouped notifications | 10 | No duplicate effects or stuck panel | Pending | Pending |
| Sleep and wake | 3 cycles | Observer reconnects | Pending | Pending |
| Notification Center process restart | 3 cycles | Observer reconnects | Pending | Pending |
| Detection-to-effect latency | 20 | Maximum 500 ms | Pending | Pending |
| BarBop local test banners | 5 | 5 visible banners, each detected exactly once | The product-side visual run passed 5/5 at manual two-second intervals with one effect on all three displays and no residual panel. A later product-only cold start passed after stale TCC entries were reset: the saved yellow Flash effect appeared on all three displays without a preceding ordinary menu bar click. The isolated spike rerun was not countable: approximately five requests produced 6 distinct candidates / 6 detections / 0 duplicates because macOS delivered an earlier delayed local request in the same run; average latency was 24 ms and maximum latency was 67 ms. | Product visual pass; exact isolated 5/5 spike count pending |
| Slack example banner | 1 | One effect for one visible banner | Earlier isolated sample: 12 callbacks, 3 structural candidates, 1 detection, 2 animation duplicates removed; 5 ms effect latency. | Passed as a structural regression sample; external 20-banner gate remains pending |
| Slack Preview regression | 3 | Three visible banners, one effect each, maximum 500 ms | The user-triggered `11:56:54–11:56:56` segment produced three distinct structural events and three detections. The full non-isolated counter window contained three earlier unrelated detections; its maximum latency was 292 ms. | Passed for the isolated three-event segment; known false-positive limitation remains |
| Sandbox observer attachment | 1 connection | Permission granted and observer active | BarBop did not appear in Accessibility | Failed |
| Sandbox visible banners | 5 | 5 detected, one effect each | Could not start because permission registration failed | Failed |

## Observed Accessibility Structure

Record only roles, subroles, frames, supported creation notification names, and
display IDs. Do not paste notification content into this report.

- Registered AX notifications: `AXCreated`, `AXWindowCreated`,
  `AXLayoutChanged`, `AXValueChanged`, `AXRowCountChanged`,
  `AXSelectedChildrenChanged`, and `AXResized`
- Accepted event: `AXLayoutChanged` only
- Observed native banner role/subrole: `AXGroup/AXNotificationCenterBanner`
- Observed Slack callback root: `AXGroup/none` at depth `0`, with a direct
  `AXGroup/AXNotificationCenterAlertStack` child. The stable child frame is
  used for geometry and display selection; notification content is not read.
- Accepted parent depth: `0` (the callback element itself)
- Typical observed banner frames: height `73`, widths approximately `344–577`
- Latest reset diagnostic: 6 candidates, 6 detections, 0 duplicates,
  24 ms average effect latency, 67 ms maximum effect latency. The user made
  approximately five requests, so the run is retained as latency and structure
  evidence but not counted as the exact five-banner sample; a previously
  delayed local notification was delivered after the reset.
- Latest isolated Slack example diagnostic: 12 callbacks, 3 accepted
  structural candidates, 1 detection, 2 duplicates removed, 5 ms average and
  maximum effect latency. The three candidates were repeated callbacks during
  one banner's horizontal entrance animation.
- Latest Preview regression: the exact user-triggered segment from
  `11:56:54` through `11:56:56` contained three distinct root Alert/AlertStack
  identities and three detections. The full counter window reported 20
  callbacks, 9 candidates, 6 detections, 3 duplicates, 180 ms average latency,
  and 292 ms maximum latency because three earlier unrelated structural events
  occurred before the requested Slack sends. Only the exact three-event segment
  is counted as the Slack regression result.
- Rejected structural callbacks included full-screen
  `AXWindow/AXSystemDialog` roots and `AXScrollArea` roots containing the banner
  as a descendant. Restricting acceptance to the banner callback root removes
  those duplicate structural paths without reading content.
- Expanded Notification Center presentations exposed an
  `AXOpaqueProviderGroup/AXOpaqueProviderGrid` descendant, but the presentation
  transition also emitted a root `AXGroup/AXNotificationCenterAlertStack` with
  the same banner-sized frame used by genuine visible notifications. Width
  checks, expanded-structure checks, persistent existing-element suppression,
  a 250 ms structural recheck, and a 750 ms collapse suppression window reduced
  but did not eliminate the false positive.
- The final false-positive frame was approximately `344×57` at the top of
  display ID 1. Its role, subrole, root depth, event kind, frame, and timing were
  not stably distinguishable from the accepted Slack banner structure without
  consulting prohibited content or private implementation details.
- Multi-display coordinate notes: display ID 1 was observed in the latest run;
  the second-display routing threshold remains pending.

The classifier requires the confirmed role, subrole, callback-root depth,
event kind, size, upper-screen region, and presentation-state checks. Content
attributes are not consulted. The structure gate nevertheless failed the
zero-false-positive requirement, so the remaining release matrix cannot convert
this spike to a Go decision.

## Decision

Current integration decision: **No-Go**

Stable release decision: **Blocked for the notification-enabled product**

Preview release decision: **Accepted with a documented known limitation**

The public Accessibility structure does not reliably distinguish a genuine
visible banner from Notification Center's own open/close presentation. The
final 10-cycle run produced one false effect, violating the required zero-false-
positive threshold after multiple structure-only refinements. No notification
content, database access, screen capture/OCR, private API, or private
entitlement was used or will be introduced to bypass this result.

BarBop must not represent the current system-wide notification effect as a
stable or reliability-validated feature. The project owner accepted a limited
`0.1.0` Preview distribution with Notification Effects marked Experimental,
off by default, and the Notification Center open/close false-positive disclosed
in Settings, README, and release notes. A future stable designation still
requires the zero-false-positive gate or a reliable public macOS signal. The
diagnostic spike may remain as development evidence but is not part of the
distributed app.
