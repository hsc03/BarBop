# Privacy and Permissions

BarBop is designed as a local-only visual feedback utility for the macOS menu
bar. It should remain understandable to users and conservative about system
access.

## What BarBop Observes

BarBop observes mouse down events so it can determine whether a click happened
inside a menu bar area. The app uses the current pointer location and the
visible screen geometry to decide whether an effect should play.

The app does not store click history.

## What BarBop Stores

BarBop stores only effect settings in local user defaults:

- Effect enabled state
- Color
- Opacity
- Duration
- Effect style

If the stored settings data is missing, unsupported, or corrupted, BarBop falls
back to default settings.

## What BarBop Does Not Collect

BarBop does not collect or store:

- Menu contents
- App usage history
- Keyboard input
- Screenshots
- Screen recordings
- Screen pixels
- General click history
- Account information
- Analytics events

BarBop does not make network requests.

## Permissions

BarBop relies on macOS event monitoring behavior to observe clicks outside its
own process. Depending on the macOS version and local security settings, users
may need to approve the app in System Settings.

BarBop must continue to behave safely when permission is missing:

- The settings window should remain usable.
- The app should not crash.
- The app should not attempt private APIs or event injection as a workaround.

## Overlay Behavior

The visual effect is drawn in a temporary, transparent, non-activating panel.
The panel is configured to ignore mouse events, so the original menu bar click
continues to reach macOS or the clicked menu bar app.

The overlay is hidden after the configured effect duration.
