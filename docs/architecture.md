# Architecture

BarBop is an AppKit and SwiftUI menu bar application. It renders short,
click-through overlays without modifying macOS menus or third-party apps.

## Event Flow

```text
Menu bar mouse event ─┐
                     ├─> EffectCoordinator ─> target display(s)
Visible AX banner ───┘                         └─> MenuBarEffectController
                                                       └─> temporary panels
```

- `MenuBarEventMonitor` observes mouse-down events and accepts only points in a
  connected display's menu bar geometry.
- `NotificationBannerDetector` observes structural Accessibility events from
  `com.apple.notificationcenterui`, filters banner-shaped elements, resolves a
  display, and deduplicates repeated events.
- `EffectCoordinator` keeps click and notification triggers independent while
  applying the same appearance settings.
- `MenuBarEffectController` cancels existing panels before displaying the
  newest effect. Panels are non-activating and ignore mouse events.

## Settings

`EffectSettingsStore` persists schema-versioned JSON in `UserDefaults`.
Schema v3 stores trigger toggles, the selected notification display policy,
single-color and Aurora palettes, opacity, duration, and style. Older settings
are migrated, invalid values are clamped, and corrupted data falls back to
defaults.

Specific displays are persisted by UUID rather than transient display ID. If a
selected display is disconnected, notification effects temporarily use the
main display and resume the saved target when it reconnects.

## Notification Detection Boundary

The detector reads only Accessibility event type, element identity, role,
subrole, frame, parent depth, timing, and a derived display ID. It does not
request content attributes such as titles, descriptions, app names, or button
labels. It does not access Notification Center databases, logs, screenshots,
pixels, OCR, or private APIs.

The detector is shared directly as source by the production app and the
development-only `NotificationObserverSpike` target. The spike exposes
in-memory structural diagnostics for manual macOS validation and is excluded
from installation and release archives.

## Updates and Distribution

BarBop is non-sandboxed because the tested sandbox configuration could not
register the application as an Accessibility client. Public builds therefore
use Developer ID signing, Hardened Runtime, Apple notarization, and stapling.

Sparkle verifies appcast signatures and replacement application signatures.
The Sparkle public key is committed in `Info.plist`; its private signing key and
Apple credentials must never enter the repository.
