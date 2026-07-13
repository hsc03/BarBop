# Phase 3 Manual Verification Checklist

Use this checklist after building and running BarBop from Xcode.

Branch: `develop`

## Scope

Phase 3 validates settings UI, local persistence, and settings recovery.

## Required Checks

- [ ] Settings window opens from the app's menu bar item.
- [ ] Turning effects off stops future menu bar click effects.
- [ ] Turning effects back on resumes menu bar click effects.
- [ ] Color changes apply on the next effect.
- [ ] Opacity changes apply on the next effect.
- [ ] Duration changes apply on the next effect.
- [ ] Style selection persists after quitting and relaunching the app.
- [ ] Corrupted stored settings recover to defaults without crashing.
- [ ] The settings UI remains usable even if global event observation is
      unavailable.

## Environment Notes

- macOS version:
- Settings persistence checked:
- Permission state:
- Known gaps:
