# Phase 2 Manual Verification Checklist

Use this checklist after building and running BarBop from Xcode.

Branch: `develop`

## Scope

Phase 2 validates the full-width menu bar overlay effect.

## Required Checks

- [ ] Menu bar clicks show a temporary effect across the clicked display's menu
      bar.
- [ ] Existing system and third-party menus still open normally.
- [ ] The overlay does not take keyboard focus.
- [ ] The overlay does not intercept mouse input.
- [ ] The overlay hides automatically after playback.
- [ ] Rapid repeated clicks replace the previous effect instead of leaving
      stuck overlays.
- [ ] Clicking outside the menu bar does not show the overlay.
- [ ] On multi-display setups, the overlay appears only on the clicked display.

## Environment Notes

- macOS version:
- Displays:
- System menu items tested:
- Third-party menu bar apps tested:
- Known gaps:
