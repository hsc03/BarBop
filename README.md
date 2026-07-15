# BarBop

BarBop is a small macOS menu bar utility that adds a short visual click effect
across the menu bar. It does not modify system menus or third-party menu bar
apps. It only observes clicks, checks whether the click happened in the menu
bar area, and shows a temporary click-through overlay on the clicked display.

## Current Features

- Menu bar click detection
- First-launch settings popover guidance
- Conditional guidance when click monitoring cannot start
- Click-through menu bar overlay
- Multi-display menu bar targeting
- Effect enable/disable setting
- Color, opacity, duration, and style settings
- Flash, Pulse, Sweep, and Aurora effects
- Reduce Motion fallback
- Local settings persistence with recovery from invalid stored data
- Local test notification control for notification-trigger diagnostics
- Experimental effects for visible notification banners, using the same color,
  Aurora palette, opacity, duration, and style as click effects
- Notification display targeting: follow the visible banner, use the main or a
  specific display, or play simultaneously on every connected display

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

`NotificationObserverSpike` is a development-only diagnostic target used to
verify Notification Center's public Accessibility structure. It is not bundled
in the BarBop application or included in release ZIP files.

On the first launch, BarBop opens its settings popover from the menu bar item
once. Later, clicking the BarBop menu bar item toggles the same attached
popover; no separate settings window is created. Effects and Notifications are
organized in separate tabs. Click-monitoring guidance appears only when the
system-wide mouse event monitor cannot start. BarBop does not monitor keyboard
events.

The Notifications tab includes a collapsed Troubleshooting section that can
send a fixed local test notification after the user grants macOS notification
permission. This diagnostic action does not enable notification effects,
change effect settings, or use the network.

Click Effects and Notification Effects are independent. Notification Effects
observe only banners that macOS actually displays. Enabling them requires
Accessibility approval because BarBop watches the public structural
Accessibility events exposed by Notification Center. BarBop does not read the
notification title, body, source app, or button labels. BarBop explains this
use before opening the macOS Accessibility prompt and disables notification
effects if access is later revoked.

Local test notifications also require BarBop alerts to use a visible banner or
alert style. Troubleshooting links to System Settings when local notifications
are denied or their banners are disabled. Focus modes and other system delivery
settings can still suppress a test banner.

Notification display selection is stored by the display's stable UUID. If a
selected display is disconnected, BarBop temporarily uses the current main
display and automatically resumes the selected display when it reconnects.

## Documentation

- Product plan: `docs/product-plan.md`
- Engineering harness: `docs/engineering-harness.md`
- Privacy and permissions: `docs/privacy-and-permissions.md`
- Manual verification: `docs/phase-5-quality-checklist.md`
- Personal Homebrew Tap distribution: `docs/personal-homebrew-tap.md`

## Distribution Goal

The release path targets a signed and notarized macOS app distributed through
GitHub Releases first. Homebrew Cask support is planned after a release artifact
and SHA-256 checksum are available.

Notification banner observation requires Accessibility access and is not
compatible with BarBop's tested App Sandbox build. BarBop therefore targets
direct Developer ID distribution rather than the Mac App Store.
