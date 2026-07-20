# Notification Trigger Spike Report

Date: 2026-07-20

Status: Integration validated; release reliability validation pending

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
| Unit tests | Passed | 51 tests passed, including detector-core coverage for the native banner and Slack alert-stack structures, animation duplicate suppression, callback filtering and retry bounds, v1/v2-to-v3 migration, four notification display modes, disconnected-display fallback, multi-display rendering, permission/scheduling and alert-style handling, live Accessibility revocation, Accessibility gating, configured-effect routing, and update-controller behavior. |
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
| Open and close Notification Center | 10 cycles | 0 effects | Pending | Pending |
| Focus mode suppressed notifications | 5 | 0 effects | Pending | Pending |
| Rapid and grouped notifications | 10 | No duplicate effects or stuck panel | Pending | Pending |
| Sleep and wake | 3 cycles | Observer reconnects | Pending | Pending |
| Notification Center process restart | 3 cycles | Observer reconnects | Pending | Pending |
| Detection-to-effect latency | 20 | Maximum 500 ms | Pending | Pending |
| BarBop local test banners | 5 | 5 visible banners, each detected exactly once | The product-side visual run passed 5/5 at manual two-second intervals with one effect on all three displays and no residual panel. A later product-only cold start passed after stale TCC entries were reset: the saved yellow Flash effect appeared on all three displays without a preceding ordinary menu bar click. The isolated spike rerun was not countable: approximately five requests produced 6 distinct candidates / 6 detections / 0 duplicates because macOS delivered an earlier delayed local request in the same run; average latency was 24 ms and maximum latency was 67 ms. | Product visual pass; exact isolated 5/5 spike count pending |
| Slack example banner | 1 | One effect for one visible banner | 12 callbacks, 3 structural candidates, 1 detection, 2 animation duplicates removed; 5 ms effect latency. | Passed as a structural regression sample; external 20-banner gate remains pending |
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
- Rejected structural callbacks included full-screen
  `AXWindow/AXSystemDialog` roots and `AXScrollArea` roots containing the banner
  as a descendant. Restricting acceptance to the banner callback root removes
  those duplicate structural paths without reading content.
- Multi-display coordinate notes: display ID 1 was observed in the latest run;
  the second-display routing threshold remains pending.

The classifier now requires the confirmed role, subrole, callback-root depth,
event kind, size, and upper-screen region. Content attributes are not consulted.
The structure gate is suitable for continued product validation, but the final
decision still depends on the complete false-positive, external-app,
multi-display, Focus mode, sleep/wake, and Sandbox runtime matrix.

## Decision

Current integration decision: **Go — direct distribution required**

Current release decision: **Pending interactive reliability validation**

The automatic implementation, exact structure gate, and initial product
integration gate have passed. The Sandbox runtime could not register BarBop as
an Accessibility client, while the non-Sandbox spike registered and observed
the confirmed structure. Distribution therefore requires a directly signed and
notarized build rather than the Mac App Store. Genuine external notifications,
Focus mode behavior, idle false positives, two-display routing, sleep/wake, and
Notification Center restarts remain release gates and must not be represented
as passed until their results are recorded above.

Mark the release **No-Go** if validation requires notification content,
Notification Center database access, screen capture/OCR, private APIs, or if
detection and false-positive thresholds are not met. Mark the release **Go**
only after every required scenario passes in a normal interactive macOS
session. The existing Sandbox comparison failure fixes the distribution path
as direct Developer ID distribution for this implementation.
