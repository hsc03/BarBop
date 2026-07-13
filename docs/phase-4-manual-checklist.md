# Phase 4 Manual Verification Checklist

Branch: `feature/phase-4-settings-store`

Use this checklist after building and running BarBop from Xcode.

## Required Checks

- [ ] Menu bar clicks still trigger reactions when reactions are enabled.
- [ ] Turning reactions off in Settings stops future overlay reactions.
- [ ] Turning reactions back on resumes overlay reactions.
- [ ] Clicking identifiable or unidentifiable menu bar items adds them to the
      Detected Menu Bar Items list.
- [ ] Repeated clicks on the same item update the last detected time without
      creating duplicates.
- [ ] Default character selection persists after closing and reopening Settings.
- [ ] Per-item character assignment persists after closing and reopening
      Settings.
- [ ] Removing an item mapping makes it use the default character again.
- [ ] Reset Mappings removes all per-item assignments.
- [ ] Clear Detected Items removes detected items and their assignments.
- [ ] Corrupted settings data recovers to defaults without crashing.

## Notes

Only one placeholder built-in character exists in this phase. Later phases add
the monkey, cat, and slime characters plus imported PNG/GIF characters.
