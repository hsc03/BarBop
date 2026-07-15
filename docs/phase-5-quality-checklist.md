# Phase 5 Quality Checklist

Use this checklist after building and running BarBop from Xcode or a local
Release build.

Branch: `develop`

## Build Checks

- [x] Debug build succeeds.
- [x] Release build succeeds.
- [ ] Xcode Issue Navigator has no errors.
- [x] Swift Testing unit tests compile.
- [x] Command-line execution passes the full 44-test suite.

## Manual App Checks

- [ ] On a clean first launch, the menu bar settings popover opens automatically once.
- [ ] On later launches, the settings popover does not open automatically.
- [x] BarBop launches as a menu bar utility.
- [x] BarBop's own menu bar item toggles its attached settings popover.
- [x] The settings UI does not create a separate app window.
- [x] Clicking outside the transient popover closes it without quitting BarBop.
- [ ] Quit BarBop exits the app.
- [ ] Menu bar clicks trigger a visual effect when effects are enabled.
- [ ] Menu bar clicks do not trigger a visual effect when effects are disabled.
- [ ] Menu bar clicks still open the original menu or popover.
- [ ] Non-menu-bar clicks do not trigger an effect.
- [ ] The overlay does not capture mouse input.
- [ ] Rapid repeated menu bar clicks do not leave stuck overlays.
- [ ] On multi-display setups, the effect appears only on the clicked display.

## Settings Checks

- [x] Normal click-monitoring state does not add a diagnostic card to Settings.
- [ ] If the global mouse monitor cannot start, the Effects tab shows a wrapped
      warning that recommends relaunching BarBop and checking privacy settings.
- [x] Effects and Notifications tabs switch without resizing the popover.
- [x] Only the tab content scrolls; the header and footer remain visible.
- [x] Troubleshooting is collapsed initially and reveals local notification
      permission and the test notification controls when expanded.
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
- [ ] Click Effects and Notification Effects can be enabled independently.
- [ ] Without Accessibility approval, enabling Notification Effects returns
      the toggle to off, explains the requested access before the system
      prompt, and shows the System Settings guidance.
- [ ] After Accessibility approval and returning to BarBop, the pending
      Notification Effects request enables automatically and reports an active
      observer.
- [ ] Revoking Accessibility while Notification Effects is active stops the
      observer and turns the toggle off when BarBop next becomes active.
- [x] A visible test notification plays the currently selected solid or
      Aurora colors, opacity, duration, and style on the banner's display.
- [ ] A notification does not trigger an effect when Notification Effects is
      off, and sending a test notification does not change either toggle.
- [ ] If BarBop notification permission is denied or its alert style is set to
      None, Troubleshooting does not claim a visible test was sent and offers
      an Open Notification Settings button.
- [ ] Follow Notification targets the display reported by the visible banner.
- [ ] Main Display always targets the current macOS main display.
- [ ] Each connected display can be selected by name and remains selected after
      relaunching BarBop.
- [x] All Displays plays one simultaneous effect on every connected display.
- [ ] Disconnecting a specifically selected display shows the fallback notice
      and uses Main Display; reconnecting it restores the original selection.
- [ ] Changing the display arrangement refreshes the Display picker without
      requiring an app restart.
- [ ] A click effect still appears only on the clicked display regardless of
      the notification Display setting.

## Documentation Checks

- [x] README describes the current product direction.
- [x] Privacy and permissions documentation matches current behavior.
- [x] Known limitations are documented.
- [x] Release and Homebrew work are clearly described as later distribution
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
