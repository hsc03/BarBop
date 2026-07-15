# Privacy and Permissions

BarBop is designed as a local-only visual feedback utility for the macOS menu
bar. It should remain understandable to users and conservative about system
access.

## What BarBop Observes

BarBop observes mouse down events so it can determine whether a click happened
inside a menu bar area. The app uses the current pointer location and the
visible screen geometry to decide whether an effect should play.

BarBop does not observe keyboard events. The menu bar settings popover shows whether the
system-wide mouse event monitor was created successfully. This is an
operational status, not a claim that a specific macOS privacy permission has
been granted.

The app does not store click history.

## What BarBop Stores

BarBop stores only effect settings in local user defaults:

- Effect enabled state
- Notification effect enabled state
- Color
- Three-color Aurora palette
- Notification display mode and the selected display's UUID and display name
- Opacity
- Duration
- Effect style

If the stored settings data is missing, unsupported, or corrupted, BarBop falls
back to default settings.

Display UUIDs are read locally from connected display hardware only to restore
the user's target-display choice. They are not transmitted or used for
analytics. If a selected display is unavailable, the effect falls back to the
current main display until that UUID reconnects.

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

The settings popover can ask macOS to display one fixed local BarBop test
notification. Its title and body are generated on the Mac, are not derived from
user data, and are not transmitted over the network. Sending a test notification
does not enable notification-triggered effects.

## Permissions

BarBop relies on macOS event monitoring behavior to observe clicks outside its
own process. Depending on the macOS version and local security settings, users
may need to approve the app in System Settings.

BarBop must continue to behave safely when permission is missing:

- The settings popover should remain usable.
- The app should not crash.
- The app should not attempt private APIs or event injection as a workaround.

Click monitoring does not proactively request Accessibility access. If its
system-wide mouse monitor cannot be started, Settings shows an unavailable
state and suggests relaunching the app and checking macOS privacy settings.

BarBop requests Accessibility access only when the user turns on
**Notification Effects (Experimental)**. It observes structural events from
the `com.apple.notificationcenterui` process and reacts only to a visible
`AXGroup/AXNotificationCenterBanner` element. It reads the event kind, element
identity, role, subrole, frame, parent depth, and derived display ID. It does
not read or store notification titles, bodies, source app names, or button
labels. It also does not access Notification Center databases, system logs,
screenshots, pixels, OCR, or private APIs.

If Accessibility access is missing, the notification effect toggle returns to
off and Settings explains how to approve BarBop. When the user returns from
System Settings after approval, BarBop completes the pending enable request
automatically. Turning notification effects off stops the AX observer. Click
effects remain independent.

BarBop is distributed outside the Mac App Store because the tested App Sandbox
build could not register as an Accessibility client. Direct releases must use
Developer ID signing and notarization. Hardened Runtime remains enabled.

Local notification permission is separate from Accessibility access. BarBop
requests notification permission only when the user chooses **Send Test
Notification**. If permission is denied, Settings directs the user to System
Settings > Notifications > BarBop and does not schedule a notification.

## Overlay Behavior

The visual effect is drawn in a temporary, transparent, non-activating panel.
The panel is configured to ignore mouse events, so the original menu bar click
continues to reach macOS or the clicked menu bar app.

The overlay is hidden after the configured effect duration.
