# Phase 1 Manual Verification Checklist

> Historical development checklist. Phase 1 has been superseded by the current
> Phase 5 quality checklist; unchecked boxes below are retained as design
> history and are not current release status.

Use this checklist after building and running BarBop from Xcode.

Branch: `develop`

## Scope

Phase 1 validates the basic menu bar utility shell and menu bar click detection.

## Required Checks

- [ ] App launches without showing a normal product window.
- [ ] BarBop status item appears in the macOS menu bar.
- [ ] Clicking BarBop's own status item opens its menu.
- [ ] Clicking BarBop's own status item does not trigger the click effect.
- [ ] Clicking a system menu bar item is detected.
- [ ] The original system menu opens normally.
- [ ] Clicking outside the menu bar does not trigger any effect.
- [ ] If an external display is attached, clicks are associated with the
      correct display.

## Environment Notes

- macOS version:
- Mac model:
- Displays:
- Menu bar auto-hide enabled:
- Known gaps:
