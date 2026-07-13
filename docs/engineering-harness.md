# BarBop Engineering Harness

This document defines the working harness for implementing BarBop in small,
verifiable slices. It is intentionally separate from product planning: the goal
is to keep each development step testable, reviewable, and safe for a macOS
menu bar utility.

## Principles

- Prefer a thin vertical slice over broad unfinished infrastructure.
- Keep system integration behind small boundaries so pure logic can be tested.
- Treat Accessibility, global event monitoring, and overlay windows as manual
  verification surfaces unless behavior can be isolated into pure functions.
- Never let a failed best-effort integration path break the default reaction.
- Preserve the original menu behavior as the primary acceptance criterion.

## Branching Model

Use three long-lived branches:

- `main`: final stable history only. Changes reach `main` after a release branch
  has been fully validated.
- `release`: release preparation and final packaging branch. Only receives
  validated work from `develop` when preparing a distribution build.
- `develop`: integration branch for completed feature work.

During the current product pivot, implementation work can happen directly on
`develop`. Once the MVP stabilizes and work becomes less exploratory, return to
short-lived feature branches created from `develop`.

Recommended naming:

- `feature/phase-1-technical-prototype`
- `feature/phase-2-status-item-resolver`
- `feature/character-store`
- `fix/overlay-positioning`

Default merge flow after the pivot stabilizes:

1. Create a feature branch from the latest `develop`.
2. Implement the scoped phase or fix.
3. Run the phase's required build, automated tests, and manual checklist.
4. Merge the feature branch into `develop` only after the checks pass or known
   gaps are documented.
5. Validate `develop` before release preparation.
6. Merge `develop` into `release` for release-specific versioning, signing,
   packaging, documentation, and final verification.
7. Merge `release` into `main` only after the release is considered final.

Operational rules:

- Do not commit feature work directly to `main` or `release`.
- During the pivot, keep direct `develop` commits small and reversible.
- Keep release-only changes, such as version bumps and packaging metadata, on
  `release` unless they are also needed for ongoing development.
- If a release fix is made on `release`, port it back to `develop`.
- Record build, test, and manual verification results before merging each phase.

## Harness Layers

### Pure Unit Harness

Use Swift Testing in `BarBopTests` for logic that does not require macOS
permissions or live windows.

Initial coverage targets:

- Menu bar region calculation.
- Multi-screen coordinate selection.
- Overlay clamping inside visible screen bounds.
- Stable status item identity generation.
- Assignment and fallback selection.
- Store decoding recovery from invalid data.

Rules:

- Keep these functions free of `NSScreen`, `NSEvent`, `AXUIElement`, and
  `NSWindow` where practical.
- Adapt AppKit values into small plain Swift structs before testing.
- Tests should not require Accessibility permission.

### Integration Harness

Use narrow AppKit objects in the app target for behavior that needs the real
system:

- Global mouse event monitor.
- Accessibility hit testing.
- Non-activating transparent overlay panel.
- Menu bar status item exclusion.
- Login item registration.

Rules:

- Integration objects must fail closed and report status instead of trapping.
- Global monitors must have explicit start and stop methods.
- Overlay playback must expose enough state for diagnostics, but not for product
  UI coupling.
- The app must remain usable without Accessibility permission.

### Manual Verification Harness

Each phase that touches system behavior must include a short manual checklist.
The checklist records what was verified on the current machine and what remains
untested.

Required checks for phase 1:

- Left click on macOS menu bar item shows the temporary reaction.
- Right click on macOS menu bar item shows the temporary reaction if the item
  opens a menu.
- Normal menu opens without delay or focus change.
- Non-menu-bar clicks do not show the reaction.
- Reaction appears on the display where the click occurred.
- The app's own status item does not trigger the reaction.
- Overlay never captures mouse input.

## Phase Gates

### Phase 1: Technical Prototype

Implementation scope:

- Convert the template app into a menu bar utility prototype.
- Observe global mouse clicks.
- Determine whether the click is inside the menu bar area.
- Show a non-activating transparent `NSPanel` with a red circle for 0.8 seconds.
- Exclude the app's own status item.
- Add unit tests for coordinate logic.

Exit criteria:

- Build succeeds.
- Coordinate tests pass.
- Manual verification checklist is completed or gaps are documented.
- No settings UI, character store, or Accessibility resolver is added yet.

### Phase 2: Status Item Identity

Implementation scope:

- Add Accessibility hit testing at the clicked menu bar coordinate.
- Collect best-effort role, title, identifier, PID, bundle ID, and app name.
- Generate stable identity keys with a pure function.
- Log debug information without crashing on missing permissions or missing data.

Exit criteria:

- Build succeeds.
- Identity tests pass.
- Representative system and third-party status items produce useful logs when
  available.
- Unknown items still return a safe fallback identity.

### Phase 3: Reaction Core

Implementation scope:

- Introduce `ReactionCoordinator`, `OverlayWindowController`, and
  `CharacterRenderer`.
- Replace the red circle with one temporary character reaction.
- Cancel the previous reaction on rapid repeated clicks.
- Respect Reduce Motion.
- Stop timers when idle.

Exit criteria:

- Build succeeds.
- Coordinator tests pass.
- Manual verification confirms no panel accumulation or input capture.

## Reporting Template

Each completed phase should report:

- Files changed.
- Build result.
- Automated test result.
- Manual checks completed.
- Known gaps or environment-specific risks.

## Current Baseline

The repository currently starts from the default SwiftUI macOS template. The
first engineering task is phase 1, with no product settings UI and no character
management.
