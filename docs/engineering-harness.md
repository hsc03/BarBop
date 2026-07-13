# BarBop Engineering Harness

This document defines the working harness for implementing BarBop in small,
verifiable slices. It is intentionally separate from product planning: the goal
is to keep each development step testable, reviewable, and safe for a macOS
menu bar click-effect utility.

## Principles

- Prefer a thin vertical slice over broad unfinished infrastructure.
- Keep system integration behind small boundaries so pure logic can be tested.
- Treat global event monitoring and overlay windows as manual
  verification surfaces unless behavior can be isolated into pure functions.
- Never let a failed best-effort integration path break the default effect.
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
- `feature/menu-bar-effect`
- `feature/effect-settings`
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
- Effect settings encoding, decoding, and recovery.
- Codable color conversion.
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
- Non-activating transparent overlay panel.
- Menu bar click effect rendering.
- Own status item exclusion.

Rules:

- Integration objects must fail closed and report status instead of trapping.
- Global monitors must have explicit start and stop methods.
- Overlay playback must expose enough state for diagnostics, but not for product
  UI coupling.
- The app must remain usable when global event observation is unavailable or
  restricted.

### Manual Verification Harness

Each phase that touches system behavior must include a short manual checklist.
The checklist records what was verified on the current machine and what remains
untested.

Required checks for menu bar effect behavior:

- Left click on macOS menu bar item shows the temporary effect.
- Right click on macOS menu bar item shows the temporary effect if the item
  opens a menu.
- Normal menu opens without delay or focus change.
- Non-menu-bar clicks do not show the effect.
- Effect appears on the display where the click occurred.
- The app's own status item does not trigger the effect.
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
- No settings UI or advanced effect style work is added yet.

### Phase 2: Full Menu Bar Effect

Implementation scope:

- Replace the prototype overlay with a full-width menu bar effect.
- Keep the panel click-through and non-activating.
- Cancel an existing effect before starting a new one.

Exit criteria:

- Build succeeds.
- Menu bar clicks show the configured effect.
- Original menu behavior is preserved.

### Phase 3: Settings

Implementation scope:

- Add effect settings UI.
- Persist settings locally.
- Recover corrupted settings data to defaults.

Exit criteria:

- Build succeeds.
- Store tests pass or compile in restricted environments.
- Manual verification confirms setting changes apply on the next click.

### Phase 4: Effect Styles

Implementation scope:

- Add Pulse, Sweep, and Aurora styles.
- Respect Reduce Motion by falling back to a simple fade.

Exit criteria:

- Build succeeds.
- All styles are selectable.
- Manual verification confirms each style plays and does not capture input.

### Phase 5: Quality Documentation

Implementation scope:

- Update README.
- Add privacy and permissions documentation.
- Add manual quality checklist.
- Validate Release build.

Exit criteria:

- Build succeeds in Release configuration.
- Known limitations are documented.
- The project is ready to move toward release preparation.

## Reporting Template

Each completed phase should report:

- Files changed.
- Build result.
- Automated test result.
- Manual checks completed.
- Known gaps or environment-specific risks.

## Current Baseline

The repository is now a menu bar click-effect utility on `develop`. Character
reaction and status-item identity work from the earlier direction has been
removed from the active product scope.
