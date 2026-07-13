# BarBop

BarBop is a small macOS menu bar utility that adds a short visual click effect
across the menu bar. It does not modify system menus or third-party menu bar
apps. It only observes clicks, checks whether the click happened in the menu
bar area, and shows a temporary click-through overlay on the clicked display.

## Current Features

- Menu bar click detection
- Click-through menu bar overlay
- Multi-display menu bar targeting
- Effect enable/disable setting
- Color, opacity, duration, and style settings
- Flash, Pulse, Sweep, and Aurora effects
- Reduce Motion fallback
- Local settings persistence with recovery from invalid stored data

## Product Boundaries

BarBop intentionally does not:

- Change the appearance of macOS system menus
- Change third-party menu bar app popovers
- Intercept clicks and replay them
- Read menu contents
- Capture screenshots or screen pixels
- Send analytics or network requests

## Development Flow

Current exploratory work happens directly on `develop`. Release preparation
happens on `release`, and final stable history is merged into `main`.

Useful checks:

```sh
xcodebuild -scheme BarBop -configuration Debug -destination 'platform=macOS' build
xcodebuild -scheme BarBop -configuration Release -destination 'platform=macOS' build
```

Unit tests use Swift Testing, but sandboxed command-line test execution may be
blocked by CoreSimulator or test manager permissions in some environments.

## Documentation

- Product plan: `docs/product-plan.md`
- Engineering harness: `docs/engineering-harness.md`
- Privacy and permissions: `docs/privacy-and-permissions.md`
- Manual verification: `docs/phase-5-quality-checklist.md`

## Distribution Goal

The release path targets a signed and notarized macOS app distributed through
GitHub Releases first. Homebrew Cask support is planned after a release artifact
and SHA-256 checksum are available.
