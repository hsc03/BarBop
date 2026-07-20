# Contributing to BarBop

Issues and pull requests are welcome. BarBop is a small macOS utility, so keep
changes focused and preserve the privacy boundaries described in
[`docs/privacy-and-permissions.md`](docs/privacy-and-permissions.md).

## Development Setup

- macOS 26.5 or later
- Apple silicon
- Xcode 26.6 or later

Open `BarBop.xcodeproj`, select the `BarBop` scheme and **My Mac**, and run the
app. The checked-in project does not contain a personal Developer Team ID;
local development uses **Sign to Run Locally** unless you provide your own
signing settings.

## Before Opening a Pull Request

Run:

```sh
xcodebuild -project BarBop.xcodeproj \
  -scheme BarBop \
  -configuration Debug \
  -destination 'platform=macOS' \
  build

xcodebuild -project BarBop.xcodeproj \
  -scheme BarBop \
  -configuration Release \
  -destination 'platform=macOS' \
  build

xcodebuild -project BarBop.xcodeproj \
  -scheme BarBop \
  -configuration Debug \
  -destination 'platform=macOS' \
  test

git diff --check
```

Add or update tests for pure settings, geometry, display routing, detector, and
controller behavior. Describe any manual macOS validation needed for overlays,
permissions, notification delivery, or multiple displays.

## Privacy and Safety Rules

Changes must not:

- read notification titles, bodies, app names, or button labels;
- observe keyboard input;
- capture screenshots or screen pixels;
- access Notification Center databases or private APIs;
- add analytics or transmit click, notification, settings, or display data;
- intercept and replay the user's original menu bar click.

Do not attach real notification contents, credentials, signing files, personal
paths, or unredacted system screenshots to issues or pull requests.

## Pull Requests

Base normal feature and fix work on `develop`. Keep commits scoped, explain the
user-visible behavior, and call out compatibility or permission changes.
Maintainers promote validated release candidates through `release` and `main`.
