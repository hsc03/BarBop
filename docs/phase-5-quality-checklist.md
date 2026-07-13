# Phase 5 Quality Checklist

Use this checklist after building and running BarBop from Xcode or a local
Release build.

Branch: `develop`

## Build Checks

- [ ] Debug build succeeds.
- [ ] Release build succeeds.
- [ ] Xcode Issue Navigator has no errors.
- [ ] Swift Testing unit tests compile.
- [ ] If command-line test execution is blocked by the local sandbox, record
      the exact error in the phase report.

## Manual App Checks

- [ ] BarBop launches as a menu bar utility.
- [ ] BarBop's own menu bar item opens its menu.
- [ ] BarBop's own menu bar menu opens Settings.
- [ ] Quit BarBop exits the app.
- [ ] Menu bar clicks trigger a visual effect when effects are enabled.
- [ ] Menu bar clicks do not trigger a visual effect when effects are disabled.
- [ ] Menu bar clicks still open the original menu or popover.
- [ ] Non-menu-bar clicks do not trigger an effect.
- [ ] The overlay does not capture mouse input.
- [ ] Rapid repeated menu bar clicks do not leave stuck overlays.
- [ ] On multi-display setups, the effect appears only on the clicked display.

## Settings Checks

- [ ] Color changes are reflected on the next effect.
- [ ] Style changes are reflected on the next effect.
- [ ] Opacity changes are reflected on the next effect.
- [ ] Duration changes are reflected on the next effect.
- [ ] Flash plays without horizontal movement.
- [ ] Pulse plays as a soft repeated opacity effect.
- [ ] Sweep moves horizontally across the menu bar.
- [ ] Aurora shows a moving multi-color gradient.
- [ ] Reduce Motion simplifies moving effects to a short fade.
- [ ] Settings persist after quitting and relaunching the app.
- [ ] Invalid stored settings recover to defaults without crashing.

## Documentation Checks

- [ ] README describes the current product direction.
- [ ] Privacy and permissions documentation matches current behavior.
- [ ] Known limitations are documented.
- [ ] Release and Homebrew work are clearly described as later distribution
      steps, not current user-facing promises.

## Known Limitations

- BarBop cannot style, animate, or replace other apps' menu windows or popovers
  through public macOS APIs.
- BarBop is a visual overlay utility; it must not block or replay menu bar
  clicks.
- Global event observation behavior can vary by macOS version and user security
  settings.
- Command-line UI or test execution may be restricted by local sandboxing even
  when the app builds successfully.
