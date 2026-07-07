# Phase 1 Manual Verification Checklist

Branch: `feature/phase-1-technical-prototype`

Use this checklist after building and running BarBop from Xcode.

## Required Checks

- [ ] App launches without showing a normal product window.
- [ ] BarBop status item appears in the macOS menu bar.
- [ ] Clicking BarBop's own status item opens its menu and does not show the red
      reaction circle.
- [ ] Clicking a system menu bar item shows a red circle near the click for
      about 0.8 seconds.
- [ ] The original system menu opens normally.
- [ ] The red overlay does not take keyboard focus.
- [ ] The red overlay does not intercept mouse input.
- [ ] Clicking outside the menu bar does not show the red circle.
- [ ] If an external display is attached, clicking that display's menu bar shows
      the red circle on that display.

## Environment Notes

Record the machine and display setup used for verification:

- macOS version:
- Mac model:
- Displays:
- Menu bar auto-hide enabled:
- Known gaps:

## Xcode Project Settings To Confirm

The prototype code calls `NSApp.setActivationPolicy(.accessory)` at launch.
For the final menu bar app behavior, also confirm these target settings in
Xcode:

- App target deployment target: macOS 14.0 or later.
- Generated Info.plist key `Application is agent (UIElement)`: `YES`.
