# Phase 3 Manual Verification Checklist

Branch: `feature/phase-3-reaction-core`

Use this checklist after building and running BarBop from Xcode.

## Required Checks

- [ ] App still detects menu bar clicks.
- [ ] Existing system and third-party menus still open normally.
- [ ] The temporary character appears within 100ms of a menu bar click.
- [ ] The character drops in from above, dips briefly, and exits upward.
- [ ] A rapid second click cancels/replaces the previous reaction instead of
      stacking multiple panels.
- [ ] The overlay does not take keyboard focus.
- [ ] The overlay does not intercept mouse input.
- [ ] With Reduce Motion enabled in System Settings, the reaction switches to a
      short fade without large movement.
- [ ] After playback completes, no visible overlay remains.

## Notes

The character is still a replaceable placeholder. The purpose of this phase is
to validate the reaction orchestration and rendering boundaries before adding
the real built-in characters.
