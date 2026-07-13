# Phase 2 Manual Verification Checklist

Branch: `feature/phase-2-status-item-resolver`

Use this checklist after building and running BarBop from Xcode.

## Required Checks

- [ ] App still shows the red phase 1 reaction on menu bar clicks.
- [ ] Existing system and third-party menus still open normally.
- [ ] Without Accessibility permission, BarBop does not crash and logs the
      fallback `status-item:unknown` identity.
- [ ] After granting Accessibility permission, clicking representative menu bar
      items logs best-effort metadata.
- [ ] Battery, Wi-Fi, Sound, and Control Center clicks produce either useful
      metadata or a safe fallback.
- [ ] A standard `NSStatusItem` third-party app produces a stable identity when
      clicked repeatedly.
- [ ] Repeated clicks on the same identifiable item log the same identity.
- [ ] Unidentifiable items never prevent the overlay reaction.

## Log Inspection

Use Console.app or Xcode's debug console and filter for:

```text
subsystem: io.github.hsc03.BarBop
category: StatusItemResolver
```

Each log should include:

- `identity`
- `app`
- `bundle`
- `pid`
- `role`
- `title`
- `axid`
- `error`

## Environment Notes

Record the machine and menu bar items used for verification:

- macOS version:
- Accessibility permission granted:
- System items tested:
- Third-party items tested:
- Known gaps:
