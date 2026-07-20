# BarBop

BarBop is a small macOS menu bar utility that adds short visual effects for
menu bar clicks and visible notification banners. It does not modify system
menus or third-party menu bar apps. Effects appear in temporary click-through
overlays and use the display policy selected by the user.

The `0.1.0` release is an early preview. Notification Effects remain
experimental while their macOS Accessibility-based detection is refined.

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
in the BarBop application or included in release ZIP files, and its target is
explicitly marked to skip installation.

The production app and diagnostic target compile the same detector sources from
`NotificationBannerCore`. These sources are linked into each app binary; they
are not a separate framework or release artifact.

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

## Preview Limitation

Opening or closing Notification Center can occasionally produce the same
public Accessibility structure as a newly displayed notification banner. As a
result, Notification Effects may rarely play while the user opens or closes
Notification Center. The final local validation observed one false effect in
ten open/close cycles. Notification Effects are off by default and clearly
marked Experimental; users who prefer deterministic behavior can leave them
disabled without affecting Click Effects.

BarBop does not inspect notification contents or use private APIs, Notification
Center databases, screenshots, or OCR to work around this limitation.

## Documentation

- Product plan: `docs/product-plan.md`
- Engineering harness: `docs/engineering-harness.md`
- Privacy and permissions: `docs/privacy-and-permissions.md`
- Manual verification: `docs/phase-5-quality-checklist.md`
- Release validation results: `docs/release-validation-report.md`
- Personal Homebrew Tap distribution: `docs/personal-homebrew-tap.md`
- In-app update distribution: `docs/update-distribution.md`

## Distribution Goal

The release path targets a signed and notarized macOS app distributed through
GitHub Releases first. Homebrew Cask support is planned after a release artifact
and SHA-256 checksum are available.

Signed in-app updates use Sparkle 2, an EdDSA-signed appcast hosted in this
repository, and immutable notarized ZIP assets from GitHub Releases. Homebrew
users may use either BarBop's update UI or `brew upgrade --cask barbop`.

Notification banner observation requires Accessibility access and is not
compatible with BarBop's tested App Sandbox build. BarBop therefore targets
direct Developer ID distribution rather than the Mac App Store.
