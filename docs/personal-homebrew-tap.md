# Personal Homebrew Tap Distribution

This document defines the first Homebrew distribution path for BarBop. It is
written as an implementation handoff: another engineer or AI should be able to
create and validate the tap without making additional product decisions.

## Decision

BarBop will use a separate public personal tap before attempting submission to
the official `Homebrew/homebrew-cask` repository.

| Repository | Responsibility |
|---|---|
| `hsc03/BarBop` | Source, documentation, version tags, release notes, and notarized `BarBop.zip` assets |
| `hsc03/homebrew-tap` | Homebrew metadata only: `Casks/barbop.rb` and tap usage documentation |

Do not duplicate the application source or ZIP artifact in `homebrew-tap`. The
Cask must download the immutable release asset from the BarBop repository.

The intended installation command is:

```sh
brew install --cask hsc03/tap/barbop
```

Homebrew maps `hsc03/tap` to the GitHub repository
`https://github.com/hsc03/homebrew-tap`.

## Release Prerequisites

Do not publish the tap until all of the following are complete:

- The `hsc03/BarBop` repository and its README are publicly accessible.
- The release candidate passes all automated and required interactive checks.
- The minimum supported macOS version and CPU architecture are verified and
  documented.
- The app is signed with a **Developer ID Application** certificate, not an
  Apple Development or ad-hoc identity.
- Hardened Runtime remains enabled and the public artifact has no
  `get-task-allow` entitlement.
- Apple notarization succeeds and the ticket is stapled to `BarBop.app`.
- The stapled app passes `codesign`, `spctl`, and `stapler` validation.
- A stable version tag and matching GitHub Release exist.
- The final ZIP is downloadable without authentication or redirects requiring
  a browser session.
- SHA-256 is calculated from the exact final ZIP uploaded to GitHub.

Current source-preview state:

- Proposed first public version: `0.1.0` with Git tag `v0.1.0`.
- The current project deployment target is macOS `26.5`; lowering it requires
  real compatibility validation before the Cask declares broader support.
- The current local Release build is `arm64` only. Keep the first Cask
  Apple-silicon-only unless an `x86_64` or universal build is produced and
  tested on Intel hardware.
- Notification Effects are experimental because Notification Center
  open/close can still cause a false effect. The limitation must remain visible
  in release notes and in-app UI.
- Historical reliability evidence and pending manual checks are archived in
  the [notification spike report](history/notification-trigger-spike-report.md)
  and [quality checklist](history/phase-5-quality-checklist.md).
- No stable public ZIP currently exists. The final source commit must be
  archived, Developer ID signed, notarized, stapled, and revalidated before the
  Cask is published; results from an earlier test build are not transferable.

## Create the Tap Repository

Create the tap only after the release prerequisites are close to completion.
The recommended Homebrew bootstrap is:

```sh
brew tap-new hsc03/homebrew-tap
```

This creates a local tap at the path reported by:

```sh
brew --repository hsc03/tap
```

Create a new **public** GitHub repository named exactly
`hsc03/homebrew-tap`, then push the generated tap repository to it. Preserve
the generated GitHub Actions files unless there is a documented reason to
replace them.

The committed repository should have this minimum structure:

```text
homebrew-tap/
├── Casks/
│   └── barbop.rb
└── README.md
```

The tap README should contain the install, upgrade, uninstall, and support
commands from this document. Issues about the application belong in
`hsc03/BarBop`; issues about Cask syntax or installation belong in
`hsc03/homebrew-tap`.

## Publish the BarBop Release

Use the [release workflow](release-process.md). The final public asset
must be named `BarBop.zip` and contain a single top-level `BarBop.app` bundle.

After uploading the final ZIP to GitHub, download it again from the public
release URL and calculate the checksum from that downloaded file:

```sh
curl -L \
  "https://github.com/hsc03/BarBop/releases/download/v0.1.0/BarBop.zip" \
  -o /tmp/BarBop-0.1.0.zip

shasum -a 256 /tmp/BarBop-0.1.0.zip
```

Do not use the checksum of an earlier local ZIP. Repacking the app after
stapling changes the ZIP checksum.

## Cask Definition

Create `Casks/barbop.rb` in `hsc03/homebrew-tap`. For the currently verified
Apple-silicon-only release, use this template and replace the checksum:

```ruby
cask "barbop" do
  version "0.1.0"
  sha256 "REPLACE_WITH_PUBLIC_RELEASE_SHA256"

  url "https://github.com/hsc03/BarBop/releases/download/v#{version}/BarBop.zip"
  name "BarBop"
  desc "Visual effects for macOS menu bar interactions and notifications"
  homepage "https://github.com/hsc03/BarBop"

  auto_updates true

  depends_on arch: :arm64
  depends_on macos: ">= :tahoe"

  app "BarBop.app"

  zap trash: [
    "~/Library/Preferences/io.github.hsc03.BarBop.plist",
  ]
end
```

Deployment-policy rules:

- Keep `depends_on arch: :arm64` while the published executable is arm64-only.
- Remove the architecture restriction only after a universal artifact passes
  both Apple silicon and Intel tests.
- `:tahoe` represents macOS 26. If the deployment target is lowered and tested,
  replace it with the corresponding Homebrew macOS symbol; do not claim macOS
  15 or earlier based only on successful compilation.
- The `zap` stanza runs only with `brew uninstall --zap --cask barbop`. Normal
  uninstall must leave user settings intact.
- Do not add an Accessibility database reset, notification-permission reset,
  process kill, or broad Library-directory deletion to `uninstall` or `zap`.

## Local Validation

Run validation against the fully qualified Cask name from the tap repository.
Do not validate only by copying `BarBop.app` manually into `/Applications`.

```sh
brew install --cask hsc03/tap/barbop
brew info --cask hsc03/tap/barbop
brew list --cask hsc03/tap/barbop
```

After installation, verify:

- `/Applications/BarBop.app` exists and launches with Gatekeeper enabled.
- The application and menu bar icons are present.
- Settings opens and persists changes.
- Click effects still work.
- Accessibility onboarding uses the installed `/Applications/BarBop.app`.
- Notification Effects can be enabled after approval.
- A visible test notification triggers the configured effect exactly once.
- Quitting and reopening the installed app does not require re-adding
  Accessibility permission for the same signed version.

Validate upgrade and removal behavior:

```sh
brew reinstall --cask hsc03/tap/barbop
brew uninstall --cask hsc03/tap/barbop
brew install --cask hsc03/tap/barbop
brew uninstall --zap --cask hsc03/tap/barbop
```

Expected behavior:

- Reinstall replaces the app without leaving duplicate bundles.
- Normal uninstall removes the app and preserves settings.
- `--zap` removes the BarBop preferences listed in the Cask.
- No overlay panel or BarBop process remains after uninstall.

Run Homebrew validation before every tap release:

```sh
brew style --cask hsc03/tap/barbop
brew audit --cask hsc03/tap/barbop
```

If the installed Homebrew version supports the new-cask audit in a personal
tap, also run:

```sh
brew audit --new --cask hsc03/tap/barbop
```

Record the exact Homebrew version and command output in the release validation
report. A network download, checksum mismatch, Gatekeeper rejection, or Cask
audit failure blocks publication.

## Updating the Cask

For every new BarBop release:

1. Complete application tests, Developer ID signing, notarization, and
   stapling.
2. Publish a new immutable Git tag and GitHub Release, for example `v0.1.1`.
3. Download the public `BarBop.zip` and calculate its SHA-256.
4. Update only `version` and `sha256` in `Casks/barbop.rb` unless packaging,
   architecture, or system requirements changed.
5. Repeat install, reinstall, uninstall, zap, style, and audit checks.
6. Commit and push the tap update only after all checks pass.

BarBop also supports Sparkle updates. Keep `auto_updates true` in the Cask so
Homebrew knows the installed application can update itself. The Tap version and
checksum must still be updated for users who prefer `brew upgrade` and for new
installations.

Never replace the ZIP attached to an existing version tag after publishing its
checksum. If a release artifact is wrong, publish a new version and update the
Cask to that version.

## User Documentation

The tap README should expose these commands:

```sh
# Install directly from the personal tap
brew install --cask hsc03/tap/barbop

# Upgrade
brew upgrade --cask hsc03/tap/barbop

# Uninstall while preserving settings
brew uninstall --cask hsc03/tap/barbop

# Uninstall and remove BarBop preferences
brew uninstall --zap --cask hsc03/tap/barbop
```

Recent Homebrew releases may require trust for non-official taps. Prefer the
fully qualified direct-install command, which limits trust to the requested
Cask. If Homebrew prompts for explicit trust, follow the prompt and the current
[Tap Trust documentation](https://docs.brew.sh/Tap-Trust); do not recommend
disabling Homebrew trust checks globally.

## Completion Criteria

The personal Homebrew Tap work is complete only when:

- Both repositories are public and linked to each other.
- A notarized, stapled, immutable BarBop release is publicly downloadable.
- `barbop.rb` contains the matching version, URL, SHA-256, architecture, and
  minimum macOS requirement.
- A clean machine or account successfully installs the public artifact through
  the fully qualified Homebrew command.
- Install, launch, Accessibility onboarding, notification effect, upgrade,
  uninstall, and zap behavior pass.
- Homebrew style and audit checks pass.
- The tested commands and outcomes are recorded in the release report.

## References

- [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [Adding Software to Homebrew](https://docs.brew.sh/Adding-Software-to-Homebrew)
- [Cask Cookbook](https://docs.brew.sh/Cask-Cookbook)
- [Tap Trust](https://docs.brew.sh/Tap-Trust)
- [Apple Developer ID](https://developer.apple.com/developer-id/)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
