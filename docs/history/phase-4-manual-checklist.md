# Phase 4 Manual Verification Checklist

> Historical development checklist. Phase 4 has been superseded by the current
> Phase 5 quality checklist; unchecked boxes below are retained as design
> history and are not current release status.

Use this checklist after building and running BarBop from Xcode.

Branch: `develop`

## Scope

Phase 4 validates the expanded effect styles and Reduce Motion fallback.

## Required Checks

- [ ] Flash appears as a simple fade across the menu bar.
- [ ] Pulse appears as a soft repeated opacity effect.
- [ ] Sweep moves horizontally across the menu bar.
- [ ] Aurora appears as a moving multi-color gradient.
- [ ] Switching styles in Settings affects the next menu bar click.
- [ ] Enabling Reduce Motion simplifies moving effects to a short fade.
- [ ] Disabling Reduce Motion restores the selected moving effect.
- [ ] No style captures mouse input or keyboard focus.
- [ ] Rapid repeated clicks do not leave stacked or stuck overlays.

## Environment Notes

- macOS version:
- Reduce Motion checked:
- Displays:
- Known gaps:
