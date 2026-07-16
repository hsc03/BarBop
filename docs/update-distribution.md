# Application Updates

BarBop uses Sparkle 2 for signed in-app updates and keeps Homebrew upgrades as
an alternative installation channel. The app is not sandboxed, so it uses
Sparkle's regular application-bundle updater without the sandbox-only XPC
configuration.

## Runtime Behavior

- The settings popover footer shows the installed version and a
  **Check for Updates…** button.
- A user-initiated check closes the transient settings popover before Sparkle
  presents its update UI.
- Sparkle asks the user whether automatic background checks are allowed. BarBop
  does not silently opt the user into update checks.
- When a scheduled update needs attention, BarBop temporarily becomes a regular
  foreground app so Sparkle's update window is discoverable, then returns to
  menu-bar-only mode when the update session finishes.
- The feed URL is
  `https://raw.githubusercontent.com/hsc03/BarBop/main/appcast.xml`.
- Update archives are downloaded from immutable GitHub Release assets.
- Sparkle verifies the archive's EdDSA signature and the replacement app's
  Developer ID signature before installation.
- BarBop does not attach analytics or system-profile data to update requests.

The appcast does not exist until the first final notarized Sparkle-enabled
archive is generated. A development build may therefore report a feed error if
**Check for Updates…** is used before the first release is published.

## Signing Key

The public EdDSA key is stored in the BarBop target's Info.plist as
`SUPublicEDKey`. The matching private key is stored only in the developer's
login Keychain under the Sparkle account `io.github.hsc03.BarBop`.

Never commit an exported private key. Back it up to secure offline storage with
Sparkle's `generate_keys` tool and remove the exported file from the Mac after
the backup is secured:

```sh
generate_keys --account io.github.hsc03.BarBop -x /secure/offline/BarBop-Sparkle-private-key
```

Losing both the Keychain item and its backup complicates future update signing.
Rotating the Developer ID certificate and Sparkle key at the same time must be
avoided.

## Generate the Appcast

After exporting and stapling a final Developer ID build, make a ZIP containing
only `BarBop.app`. Prepare an ignored working directory containing the new ZIP
and the current `appcast.xml` when updating an existing release:

```sh
mkdir -p build/updates
cp /path/to/final/BarBop.zip build/updates/BarBop.zip
cp appcast.xml build/updates/appcast.xml # omit for the first release
```

Locate the Sparkle tools in Xcode's resolved package artifacts, then run:

```sh
SPARKLE_BIN_DIR="/path/to/SourcePackages/artifacts/sparkle/Sparkle/bin" \
  scripts/generate-appcast.sh 0.1.0 build/updates
```

Copy the generated feed into the repository root only after inspecting it:

```sh
cp build/updates/appcast.xml appcast.xml
```

The generated item must contain the expected `sparkle:version`, short version,
minimum macOS version, arm64 requirement, GitHub Release URL, file length, and
EdDSA signature. Do not manually edit a signed feed; rerun `generate_appcast`
after any change.

## Release Order

1. Increment both the user-facing version when appropriate and the monotonically
   increasing build number.
2. Run automated and interactive release gates.
3. Archive, Developer ID sign, notarize, staple, and export the app.
4. Create the final `BarBop.zip` and SHA-256.
5. Generate and inspect the signed appcast using the final ZIP.
6. Promote the validated source and appcast to `main`, then create the matching
   immutable Git tag.
7. Publish `BarBop.zip` and its checksum in the matching GitHub Release.
8. Download the public asset and revalidate its checksum and Gatekeeper status.
9. Verify the previous notarized version discovers and installs the new release.
10. Update the personal Homebrew Cask version and checksum.

Never replace an asset or appcast entry for a published version. Publish a new
patch version and a larger build number instead.

## Required Update Test

Before the first public release, test a complete transition between two
Developer ID signed and notarized builds using a temporary HTTPS appcast:

- The older build detects the newer build.
- Release notes and version information are correct.
- The archive signature is accepted.
- Installation replaces the app in `/Applications` and relaunches it.
- User effect settings remain intact.
- Click and notification effects still work.
- Accessibility remains approved when macOS preserves the code requirement; if
  macOS asks again, BarBop's onboarding recovers cleanly.
- Homebrew-installed copies do not leave duplicate application bundles.

The public release remains blocked until this end-to-end update test passes.
